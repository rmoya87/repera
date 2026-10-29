package dev.repera.mobile

import android.content.Context
import dev.repera.domain.ExerciseInput
import dev.repera.domain.ExerciseInputMode
import dev.repera.domain.WodFormat
import dev.repera.domain.ResultCapture
import dev.repera.domain.SessionReview
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Real local-first strength session writes using the wire format of ReperaDomain.Models.
 * No synthetic workouts, no inferred Health Connect readings, no skipped WOD blocks.
 * A WOD requires the Swift-equivalent planner and is explicitly rejected for now.
 */
class WorkoutRepository(private val context: Context, private val googleId: String,
    private val stillAuthorized:()->Boolean = {true}) {
    private val local = LocalSnapshotStore(context, googleId)
    private val loadedStates=java.util.WeakHashMap<JSONObject,ByteArray>()
    // Espejo remoto: noteDeleted solo toca SharedPreferences (outbox), sin red.
    private val mirror = WorkoutMirrorStore(context, googleId)
    private val prefs = context.getSharedPreferences("repera.local.writer", Context.MODE_PRIVATE)
    private val reviewPrefs=context.getSharedPreferences("repera.review."+java.security.MessageDigest.getInstance("SHA-256")
        .digest(googleId.toByteArray(Charsets.UTF_8)).joinToString("") {"%02x".format(it)},Context.MODE_PRIVATE)
    private val writerId: String by lazy {
        prefs.getString("writerId", null) ?: UUID.randomUUID().toString().also {
            prefs.edit().putString("writerId", it).apply()
        }
    }

    @Synchronized fun toggleWodTemplateFavorite(id:String) {
        val state=requireState();WodTemplateFavorites.toggle(state,id);save(state)
    }

    @Synchronized fun clearWeeklySchedule() {
        val state = requireState(); WeeklyScheduleActions.clear(state); save(state)
    }
    /** Vaciar semana visible (Apple clearWeeklySchedule(for:)) y, sin cambiar el comportamiento legacy, también el plan semanal por weekday/rotación. */
    @Synchronized fun clearScheduledWeek(week: LocalDate) {
        val state = requireState()
        WeeklyScheduleActions.clearWeek(state, week); WeeklyScheduleActions.clear(state); save(state)
    }
    @Synchronized fun removeScheduledRoutine(id: String) {
        val state = requireState()
        if (WeeklyScheduleActions.removeScheduled(state, id)) save(state)
    }
    /** Apple assignRoutine(_:toDate:): adds an independent dated copy; recurrence and legacy weekday routines untouched. */
    @Synchronized fun assignRoutineToDate(templateId: String, date: LocalDate): Boolean {
        val state = requireState()
        val id = WeeklyScheduleActions.assignTemplateToDate(state, templateId, date) ?: return false
        save(state)
        return id.isNotBlank()
    }
    @Synchronized fun copyPreviousWeekSchedule(today: LocalDate = LocalDate.now()): Int {
        val state = requireState()
        val count = WeeklyScheduleActions.copyPreviousWeek(state, today)
        if (count > 0) save(state)
        return count
    }

    @Synchronized fun setTestedOneRM(exerciseId:String,value:Double?) {
        val state=requireState()
        val catalog=state.getJSONArray("exercises")
        require((0 until catalog.length()).any {catalog.getJSONObject(it).optString("id")==exerciseId})
        ExerciseLoadPreference.setTested(state,exerciseId,value);save(state)
    }

    @Synchronized internal fun updateTrainingSettings(value:TrainingSettings) {
        val state=requireState()
        TrainingSettings.apply(state,value)
        save(state)
    }

    @Synchronized internal fun updateProfile(value:ProfileSettings) {val state=requireState();ProfileSettings.apply(state,value);save(state)}

    @Synchronized internal fun updateHealthGoals(value:HealthGoals) {
        val state=requireState();HealthGoals.apply(state,value);save(state)
    }

    @Synchronized internal fun updateRotation(plan:dev.repera.domain.RotationPlan?) {
        val state=requireState()
        val routines=state.getJSONArray("routines")
        val known=(0 until routines.length()).map { routines.getJSONObject(it).getString("id") }.toSet()
        require(plan==null || plan.routineIds.all { it in known })
        require(plan==null || plan.routineIds.distinct().size==plan.routineIds.size)
        RotationSettings.write(state,plan);save(state)
    }

    @Synchronized fun setLiveRouteID(sessionID: String, routeID: String) {
        val state = requireState()
        val archive = state.getJSONArray("workouts")
        val session = (0 until archive.length()).map { archive.getJSONObject(it) }
            .firstOrNull { it.optString("id") == sessionID } ?: error("Actividad no encontrada")
        require(session.optString("phase") == "finished" && !session.isNull("liveSportID"))
        session.put("liveRouteID", routeID);save(state)
    }

    /** Actividad En vivo confirmada desde revisión, sin ejercicios ficticios
     * ni escritura de Salud. UUID idempotente evita duplicar tras reintento. */
    /**
     * Registra un temporizador libre terminado en el historial local.
     * Paridad StandaloneTimerView.saveCompletedTimer (iOS): no escribe Salud
     * ni inventa kcal/FC; idempotente por id estable del resumen pendiente.
     */
    @Synchronized fun saveTimerSession(
        id: String,
        title: String,
        startedAtMillis: Long,
        finishedAtMillis: Long,
        details: dev.repera.domain.TimerCompletionDetails
    ): String {
        require(id.isNotBlank())
        require(finishedAtMillis >= startedAtMillis)
        val state = loadOrNull() ?: error("Inicializa el almacenamiento local antes de guardar.")
        val archive = state.getJSONArray("workouts")
        if ((0 until archive.length()).any { archive.getJSONObject(it).optString("id") == id }) {
            return id
        }
        val started = Instant.ofEpochMilli(startedAtMillis).toString()
        val finished = Instant.ofEpochMilli(maxOf(finishedAtMillis, startedAtMillis + 1000)).toString()
        archive.put(JSONObject()
            .put("id", id)
            .put("title", title.trim().ifBlank { "Temporizador · ${details.modeTitle}" })
            .put("phase", "finished")
            .put("startedAt", started)
            .put("finishedAt", finished)
            .put("exercises", JSONArray())
            .put("wodResults", JSONArray())
            .put("timerDetails", details.toJson()))
        save(state)
        return id
    }

    @Synchronized fun saveLiveActivity(snapshot: dev.repera.domain.LiveActivityState.Snapshot,
        finishedMillis: Long, activeSeconds: Double, title: String, notes: String): String {
        require(snapshot.phase == dev.repera.domain.LiveActivityState.Phase.REVIEW)
        require(activeSeconds.isFinite() && activeSeconds >= 0)
        val state = loadOrNull() ?: error("Inicializa el almacenamiento local antes de guardar.")
        val archive = state.getJSONArray("workouts")
        if ((0 until archive.length()).any { archive.getJSONObject(it).optString("id") == snapshot.gpsSessionID })
            return snapshot.gpsSessionID
        val sport = dev.repera.domain.LiveSport.byId(snapshot.sportID) ?: error("Deporte desconocido")
        val session = JSONObject().put("id", snapshot.gpsSessionID)
            .put("title", title.trim().ifBlank { sport.title }).put("phase", "finished")
            .put("startedAt", Instant.ofEpochMilli(snapshot.startedMillis).toString())
            .put("finishedAt", Instant.ofEpochMilli(maxOf(finishedMillis, snapshot.startedMillis + 1000)).toString())
            .put("exercises", JSONArray()).put("wodResults", JSONArray())
            .put("liveSportID", sport.id).put("activeDurationSeconds", activeSeconds)
        if (notes.trim().isNotEmpty()) session.put("notes", notes.trim())
        snapshot.selectedRouteID?.let { session.put("liveRouteID", it) }
        if (snapshot.selectedRouteID == null && sport.usesGPS && snapshot.points.size >= 2) {
            // ID estable por sesión: si falla guardar el archivo principal,
            // el reintento no duplica la ruta ya archivada.
            val routeID = UUID.nameUUIDFromBytes(("live-route:" + snapshot.gpsSessionID).toByteArray()).toString()
            session.put("liveRouteID", routeID)
            runCatching {
                LiveRoutesStore(context, googleId).recoverFromSessions(listOf(LiveSavedRoute(
                    id = routeID, title = session.getString("title"), points = snapshot.points,
                    sportID = sport.id, createdAtMillis = snapshot.startedMillis)))
            }
            // Si falla biblioteca, queda el ID en la actividad y la próxima
            // recuperación podrá reconstruirla sin perder el entrenamiento.
        }
        if (sport.usesGPS) session.put("recordedDistanceMeters", snapshot.distanceMeters)
        if (snapshot.splitsSeconds.isNotEmpty()) session.put("liveKilometerSplitsSeconds", JSONArray(snapshot.splitsSeconds))
        session.put("routePoints", JSONArray(snapshot.points.map { p -> JSONObject()
            .put("id", p.id).put("latitude", p.latitude).put("longitude", p.longitude)
            .put("recordedAtEpochMs", p.recordedAtEpochMs)
            .put("speedMps", p.speedMps ?: JSONObject.NULL).put("altitudeMeters", p.altitudeMeters ?: JSONObject.NULL)
            .put("horizontalAccuracyMeters", p.horizontalAccuracyMeters ?: JSONObject.NULL)
            .put("verticalAccuracyMeters", p.verticalAccuracyMeters ?: JSONObject.NULL) }))
        archive.put(session); save(state); return snapshot.gpsSessionID
    }

    /**
     * Creates a real native routine using the existing Swift Routine/RoutineBlock wire format.
     * Never creates completed work or a synthetic athlete result.
     */
    @Synchronized fun createRoutine(
        title: String,
        format: String,
        entries: List<RoutineDraftEntry>,
        timeCapMinutes: Int = 12,
        rounds: Int = 1,
        schedule: RoutineSchedule = RoutineSchedule(),
        emomIntervalSeconds: Int = 60,
        workSeconds: Int = 20,
        restSeconds: Int = 10,
        ladderScheme: List<Int>? = null,
        canCreateTemplate:(Int)->Boolean = {true}
    ): String {
        val cleaned = title.trim()
        require(cleaned.isNotBlank()) { "Escribe un título válido" }
        // buyInCashOut es un formato plano más en el modelo iOS (las secciones
        // buy-in / trabajo / cash-out se componen como BLOQUES separados de la
        // rutina, no como estructura anidada del formato).
        require(format in setOf("strength", "amrap", "forTime", "emom", "tabata",
            "circuit", "chipper", "afap", "ladder", "deathBy", "partner",
            "roundsForQuality", "maxEffort", "buyInCashOut")) {
            "Tipo de rutina no permitido"
        }
        require(format != "ladder" ||
            (ladderScheme != null && ladderScheme.size in 2..12 &&
                ladderScheme.all { it in 1..1000 })) {
            "La escalera necesita un esquema tipo 21-15-9"
        }
        require(entries.isNotEmpty()) { "Añade al menos un ejercicio" }
        require(entries.map { it.exerciseId }.distinct().size == entries.size) {
            "No se puede repetir el mismo ejercicio en esta plantilla"
        }
        require(entries.size <= 60) { "Demasiados movimientos" }
        require(timeCapMinutes in 1..180 && rounds in 1..100)
        require(emomIntervalSeconds in 15..600 && workSeconds in 5..600 &&
            restSeconds in 0..600)
        if (format == "emom") require(rounds.toLong() * emomIntervalSeconds <= 10800L)
        if (format == "tabata") require(rounds.toLong() * (workSeconds + restSeconds) <= 10800L)
        if (format == "tabata") require(workSeconds + restSeconds <= 600)
        require(schedule.scheduledDate == null || schedule.weekday == null) {
            "Un entreno no puede ser semanal y de fecha concreta a la vez"
        }
        require(schedule.weekday == null || schedule.weekday in 1..7)
        require(schedule.timeMinutes == null || schedule.timeMinutes in 0..1439)
        val scheduledDay = schedule.scheduledDate?.let { LocalDate.parse(it) }
        val state = requireState()
        requireTemplateSlot(state,schedule,canCreateTemplate)
        val catalog = state.getJSONArray("exercises")
        val byId = (0 until catalog.length()).associate {
            val exercise = catalog.getJSONObject(it)
            exercise.getString("id") to exercise
        }
        val block = buildBlock(format, null, entries, byId, timeCapMinutes, rounds,
            emomIntervalSeconds, workSeconds, restSeconds, ladderScheme)
        val id = UUID.randomUUID().toString()
        val nativeRoutine = JSONObject()
            .put("id", id)
            .put("title", cleaned)
            .put("blocks", JSONArray().put(block))
            .put("progression", "off")
            .put("isFavorite", false)
        if (scheduledDay != null) {
            // Convención del snapshot: fecha concreta "yyyy-MM-dd" (AITrainingContextStore,
            // AITrainingInbox y la antigua pestana Diario (eliminada) comparan contra LocalDate.toString()).
            nativeRoutine.put("scheduledDate", scheduledDay.toString())
        } else if (schedule.weekday != null) {
            nativeRoutine.put("weekday", schedule.weekday)
        }
        if (schedule.timeMinutes != null)
            nativeRoutine.put("scheduledTimeMinutes", schedule.timeMinutes)
        schedule.weekday?.let { WeeklyScheduleActions.makeWeekdayExclusive(state,id,it) }
        state.getJSONArray("routines").put(nativeRoutine)
        save(state)
        return id
    }

    /** Bloque compartido por createRoutine y replaceRoutineBlocks: misma
     *  validación y misma escritura JSON que consume iOS. */
    private fun isRestEntry(e: RoutineDraftEntry): Boolean =
        e.sourceJson?.let { runCatching { JSONObject(it).optBoolean("isRest") }.getOrDefault(false) } == true

    /** Movimiento libre (sin exerciseId de catálogo) o REST ya serializado. */
    private fun isFreeOrRestSource(e: RoutineDraftEntry): Boolean {
        if (isRestEntry(e)) return true
        if (e.exerciseId.isNotBlank()) return false
        val raw = e.sourceJson ?: return false
        return runCatching {
            val o = JSONObject(raw)
            !o.optBoolean("isRest") && o.optString("name").isNotBlank()
        }.getOrDefault(false)
    }

    private fun originalQuantity(m: JSONObject): Int? = when {
        m.has("reps") && !m.isNull("reps") -> m.getInt("reps")
        m.has("calories") && !m.isNull("calories") -> m.getInt("calories")
        m.has("distanceMeters") && !m.isNull("distanceMeters") -> m.getInt("distanceMeters")
        else -> null
    }

    private fun buildBlock(
        format: String,
        blockTitle: String?,
        entries: List<RoutineDraftEntry>,
        byId: Map<String, JSONObject>,
        timeCapMinutes: Int, rounds: Int, emomIntervalSeconds: Int,
        workSeconds: Int, restSeconds: Int, ladderScheme: List<Int>?,
        blockId: String? = null, blockSourceJson: String? = null,
        restBetweenRoundsSeconds: Int? = null
    ): JSONObject {
        val block = (blockSourceJson?.let { runCatching { JSONObject(it) }.getOrNull() } ?: JSONObject())
            .put("id", blockId ?: UUID.randomUUID().toString())
            .put("title", blockTitle?.takeIf { it.isNotBlank() } ?: when (format) {
                "strength" -> "Fuerza"
                else -> dev.repera.domain.WodFormat.fromWire(format)?.displayName
                    ?: "Circuito"
            })
            .put("kind", if (format == "strength") "strength" else "wod")
        if (format == "strength") {
            val exercises = JSONArray()
            for (entry in entries) {
                val movement = byId[entry.exerciseId] ?: error("Ejercicio no encontrado")
                check(supportsSimpleInput(movement)) {
                    "La rutina contiene una entrada que requiere un editor avanzado"
                }
                require(entry.sets in 1..30 && entry.quantity in 1..10000)
                require(entry.weightKg == null ||
                    (inputMode(movement).showsWeight && entry.weightKg.isFinite() &&
                        entry.weightKg >= 0))
                val planned = JSONArray()
                val perSet = entry.plannedSets
                if (perSet != null) {
                    // Editor por serie: validación y escritura 1:1 (iOS
                    // PlannedSet: targetReps / targetWeightKg / targetRir).
                    require(perSet.size in 1..30)
                    for (ps in perSet) {
                        require(ps.targetReps in 1..10000)
                        require(ps.targetWeightKg == null ||
                            (ps.targetWeightKg.isFinite() && ps.targetWeightKg >= 0))
                        require(ps.targetRir == null ||
                            (ps.targetRir.isFinite() && ps.targetRir >= 0))
                        require(ps.targetDurationSeconds==null || ps.targetDurationSeconds in 1..86400)
                        val set=EditorBlockOps.draftSetsToJson(listOf(ps)).getJSONObject(0)
                            .put("targetReps",if(isMobilityHold(movement)) 1 else ps.targetReps)
                        if(movement.optString("sportTag")=="Movilidad" && ps.targetDurationSeconds==null)
                            set.put("targetDurationSeconds",if(isMobilityHold(movement)) 30 else 60)
                        planned.put(set)
                    }
                } else repeat(entry.sets) {
                    val set = JSONObject().put("id", UUID.randomUUID().toString())
                        .put("targetReps", if (isMobilityHold(movement)) 1 else entry.quantity)
                    if(movement.optString("sportTag")=="Movilidad") set.put("targetDurationSeconds",if(isMobilityHold(movement)) 30 else 60)
                    if (entry.weightKg != null) set.put("targetWeightKg", entry.weightKg)
                    planned.put(set)
                }
                require(entry.restSeconds == null || entry.restSeconds in 0..600) {
                    "El descanso debe estar entre 0 y 600 segundos"
                }
                val item = (entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() } ?: JSONObject())
                    .put("id", entry.itemId ?: UUID.randomUUID().toString())
                    .put("exerciseId", entry.exerciseId).put("plannedSets", planned)
                    .put("quantityUnit", EditorBlockOps.resolveQuantityUnit(
                        movement.getString("name"), movement.optString("equipment"),
                        entry.quantityUnit, entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }))
                entry.restSeconds?.let { item.put("restSeconds", it) }
                exercises.put(item)
            }
            block.put("exercises", exercises)
        } else {
            val movements = JSONArray()
            for (entry in entries) {
                if (isFreeOrRestSource(entry)) {
                    movements.put(JSONObject(entry.sourceJson!!)); continue
                }
                val movement = byId[entry.exerciseId] ?: error("Ejercicio no encontrado")
                require(entry.quantity in 1..10000)
                val original = entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
                    ?.takeIf { it.optString("exerciseId") == entry.exerciseId }
                val quantityUnit = EditorBlockOps.resolveQuantityUnit(
                    movement.getString("name"), movement.optString("equipment"), entry.quantityUnit, original)
                val originalUnit = original?.let { o -> when {
                    o.has("calories") && !o.isNull("calories") -> "calories"
                    o.has("distanceMeters") && !o.isNull("distanceMeters") -> "meters"
                    else -> "reps" } }
                val item = original ?: JSONObject().put("exerciseId", entry.exerciseId)
                    .put("name", movement.getString("name")).put("isRest", false)
                item.put("id", entry.itemId ?: original?.optString("id")?.ifBlank { null } ?: UUID.randomUUID().toString())
                val unchanged = original != null && originalQuantity(original) == entry.quantity && (entry.quantityUnit == null || originalUnit == quantityUnit)
                if (!unchanged) {
                    // La prescripción cambió: se reescribe y se descartan series explícitas
                    // y esquema previos (el resto de campos WOD se conserva).
                    item.remove("explicitPlannedSets"); item.remove("repScheme")
                    item.remove("reps"); item.remove("calories"); item.remove("distanceMeters")
                    when (quantityUnit) {
                        "calories" -> item.put("calories", entry.quantity)
                        "meters" -> item.put("distanceMeters", entry.quantity)
                        else -> item.put("reps", entry.quantity)
                    }
                }
                if (format == "ladder" && ladderScheme != null)
                    item.put("repScheme", JSONArray(ladderScheme))
                movements.put(item)
            }
            block.put("movements", movements)
                .put("wodFormat", format)
                .put("timeCapMinutes", when (format) {
                    "emom" -> ((emomIntervalSeconds.toLong() * rounds + 59L) / 60L).toInt()
                    "tabata" -> (((workSeconds + restSeconds).toLong() * rounds + 59L) / 60L).toInt()
                    else -> timeCapMinutes
                })
            if (format in setOf("forTime", "emom", "tabata", "circuit", "partner",
                "roundsForQuality"))
                block.put("rounds", rounds)
            if (format in setOf("emom", "circuit", "deathBy"))
                block.put("emomIntervalSeconds", emomIntervalSeconds)
            if (format == "tabata") block.put("workSeconds", workSeconds)
                .put("restSeconds", restSeconds)
            // Circuit: descanso entre rondas; forTime: «Entre rondas» iOS.
            val roundRest = restBetweenRoundsSeconds
                ?: restSeconds.takeIf { format == "circuit" }
            if (format in setOf("circuit", "forTime") && roundRest != null)
                block.put("restBetweenRoundsSeconds", roundRest)
        }
        return block
    }

    /**
     * Rutina creada desde el escáner de pizarra: los bloques ya vienen
     * interpretados (fuerza + WOD multi-bloque) y se escriben en el formato
     * wire que consume iOS, sin pasar por el borrador simplificado (que
     * perdería pesos H/M, ondas, RIR/% y descansos entre rondas).
     * Nunca crea trabajo completado ni resultados sintéticos.
     */
    @Synchronized fun createRoutineFromScan(
        title: String,
        blocks: List<dev.repera.domain.RoutineBlock>,
        schedule: RoutineSchedule = RoutineSchedule(),
        routineId: String? = null,
        canCreateTemplate:(Int)->Boolean = {true}
    ): String {
        val state=requireState()
        if(routineId!=null) {
            require(routineId.isNotBlank())
            val routines=state.getJSONArray("routines")
            if((0 until routines.length()).any {routines.getJSONObject(it).optString("id")==routineId}) return routineId
        }
        requireTemplateSlot(state,schedule,canCreateTemplate)
        // Apple 04da40ef (DayPlusSheet review.seed): los % de 1RM de la pizarra
        // se resuelven a kg con el 1RM actual antes de guardar el entreno.
        val seededBlocks=ExerciseLoadGuide.applyPercentLoads(blocks,state)
        val id=appendScannedRoutine(state,title,seededBlocks,schedule,routineId,null)
        save(state)
        return id
    }

    private fun requireTemplateSlot(state:JSONObject,schedule:RoutineSchedule,allowed:(Int)->Boolean) {
        if(schedule.scheduledDate!=null) return
        val routines=state.getJSONArray("routines")
        val count=(0 until routines.length()).count {routines.getJSONObject(it).isNull("scheduledDate")}
        check(allowed(count)) {"Has alcanzado el límite de rutinas. Revisa tu plan antes de guardar otra plantilla."}
    }

    private fun appendScannedRoutine(state:JSONObject,title:String,
        blocks:List<dev.repera.domain.RoutineBlock>,schedule:RoutineSchedule,
        routineId:String?,maxBlocks:Int?):String {
        val cleaned = title.trim()
        require(cleaned.isNotBlank()) { "Escribe un título válido" }
        // Apple saveRoutine no limita bloques; solo la ruta IA tiene el tope explícito 1...12 (AITrainingInboxStore:321).
        require(blocks.isNotEmpty() && (maxBlocks==null || blocks.size<=maxBlocks)) {
            if(maxBlocks==null) "La rutina necesita al menos un bloque" else "La rutina necesita entre 1 y $maxBlocks bloques"
        }
        require(schedule.scheduledDate == null || schedule.weekday == null) {
            "Un entreno no puede ser semanal y de fecha concreta a la vez"
        }
        require(schedule.weekday == null || schedule.weekday in 1..7)
        require(schedule.timeMinutes == null || schedule.timeMinutes in 0..1439)
        val scheduledDay = schedule.scheduledDate?.let { LocalDate.parse(it) }
        val catalog = state.getJSONArray("exercises")
        val knownIds = (0 until catalog.length())
            .map { catalog.getJSONObject(it).getString("id") }.toSet()
        val array = JSONArray()
        for (block in blocks) {
            require(block.title.isNotBlank()) { "Cada bloque necesita un título" }
            for (ex in block.exercises) {
                require(ex.exerciseId in knownIds) { "Ejercicio no encontrado" }
                require(ex.plannedSets.isNotEmpty()) { "Cada ejercicio necesita series" }
            }
            array.put(BoardScanImport.wireBlock(block))
        }
        val id = routineId ?: UUID.randomUUID().toString()
        val nativeRoutine = JSONObject()
            .put("id", id)
            .put("title", cleaned)
            .put("blocks", array)
            .put("progression", "off")
            .put("isFavorite", false)
        if (scheduledDay != null) {
            nativeRoutine.put("scheduledDate", scheduledDay.toString())
        } else if (schedule.weekday != null) {
            nativeRoutine.put("weekday", schedule.weekday)
        }
        if (schedule.timeMinutes != null)
            nativeRoutine.put("scheduledTimeMinutes", schedule.timeMinutes)
        schedule.weekday?.let { WeeklyScheduleActions.makeWeekdayExclusive(state,id,it) }
        state.getJSONArray("routines").put(nativeRoutine)
        return id
    }

    /** One local CAS for the catalog additions and the complete AI routine. */
    @Synchronized internal fun importAiRoutine(planId:String,schedule:RoutineSchedule,
        stillAuthorized:()->Boolean={true},
        build:((String,String?)->String)->Pair<String,List<dev.repera.domain.RoutineBlock>>):String {
        require(planId.isNotBlank() && schedule.scheduledDate!=null)
        check(stillAuthorized()) {"La cuenta cambió antes de importar el plan"}
        val state=requireState()
        val routines=state.getJSONArray("routines")
        check((0 until routines.length()).none {i -> routines.getJSONObject(i).let {
            it.optString("id")!=planId && it.optString("scheduledDate").take(10)==schedule.scheduledDate
        }}) {"Ya existe un entreno para ese día"}
        if((0 until routines.length()).any {routines.getJSONObject(it).optString("id")==planId}) return planId
        val (title,blocks)=build {name,key ->
            check(stillAuthorized()) {"La cuenta cambió durante la importación"}
            resolveCatalogExerciseInState(state,name,key,"Otros")
        }
        val id=appendScannedRoutine(state,title,blocks,schedule,planId,12)
        check(stillAuthorized()) {"La cuenta cambió antes de guardar el plan"}
        save(state)
        return id
    }

    /**
     * Editor de contenido: sustituye los bloques de una rutina existente
     * (multi-bloque incluido: buy-in / trabajo / cash-out como bloques
     * separados, igual que iOS). Conserva identidad, título y programación
     * de la rutina; los entrenos ya registrados nunca se reescriben.
     */
    /** Rutinas actuales (copia) para dedupe/idempotencia del inbox IA. */
    @Synchronized fun routinesSnapshot(): List<JSONObject> {
        val state = requireState()
        val routines = state.optJSONArray("routines") ?: JSONArray()
        return (0 until routines.length()).map {
            JSONObject(routines.getJSONObject(it).toString())
        }
    }

    /** Catálogo de ejercicios actual (copia) para el espejo de contexto IA. */
    @Synchronized fun exercisesSnapshot(): List<JSONObject> {
        val state = requireState()
        val catalog = state.optJSONArray("exercises") ?: JSONArray()
        return (0 until catalog.length()).map {
            JSONObject(catalog.getJSONObject(it).toString())
        }
    }

    /** iOS AITrainingInboxStore.catalogExercise: por catalogKey, luego por
     * nombre normalizado; si no existe, crea ejercicio libre (isCustom) que
     * permanece usable/editable en el mismo bloque y registro. Devuelve el id. */
    @Synchronized fun resolveOrCreateCatalogExercise(
        name: String,
        catalogKey: String? = null,
        muscleGroup: String = "Otros"

    ): String {
        val state=requireState()
        val before=state.getJSONArray("exercises").length()
        val id=resolveCatalogExerciseInState(state,name,catalogKey,muscleGroup)
        if(state.getJSONArray("exercises").length()!=before) save(state)
        return id
    }

    private fun resolveCatalogExerciseInState(state:JSONObject,name:String,catalogKey:String?,muscleGroup:String):String {
        val catalog = state.getJSONArray("exercises")
        if (catalogKey != null) {
            for (i in 0 until catalog.length()) {
                val exercise = catalog.getJSONObject(i)
                if (exercise.optString("catalogId") == catalogKey)
                    return exercise.getString("id")
            }
        }
        val wanted = dev.repera.domain.ExerciseAliasSearch.normalize(name)
        for (i in 0 until catalog.length()) {
            val exercise = catalog.getJSONObject(i)
            if (dev.repera.domain.ExerciseAliasSearch.normalize(
                    exercise.optString("name")) == wanted)
                return exercise.getString("id")
        }
        val id = UUID.randomUUID().toString()
        catalog.put(JSONObject()
            .put("id", id)
            .put("name", name)
            .put("muscleGroup", muscleGroup)
            .put("equipment", JSONObject.NULL)
            .put("targetMuscle", "")
            .put("isCustom", true))
        return id
    }

    @Synchronized fun replaceRoutineBlocks(
        id: String, blocks: List<RoutineBlockDraft>, suggestedTitle:String? = null,
        canCreateCustom: (Int) -> Boolean = { true }
    ) {
        val state = requireState()
        val routines = state.getJSONArray("routines")
        val routine = (0 until routines.length())
            .map { routines.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id } ?: error("Rutina no encontrada")
        routine.put("blocks", validatedDraftBlocks(materializePendingCustoms(blocks, state, canCreateCustom), state))
        suggestedTitle?.let {
            val title=it.trim()
            require(title.isNotBlank()) {"Escribe un título válido"}
            routine.put("title",title)
        }
        save(state)
    }

    /** Validación y construcción de bloques desde borradores del editor
     *  (compartida por replaceRoutineBlocks y createRoutineFromDrafts). */
    private fun validatedDraftBlocks(
        blocks: List<RoutineBlockDraft>, state: JSONObject
    ): JSONArray {
        require(blocks.isNotEmpty()) { "La rutina necesita al menos un bloque" }
        val catalog = state.getJSONArray("exercises")
        val byId = (0 until catalog.length()).associate {
            val exercise = catalog.getJSONObject(it)
            exercise.getString("id") to exercise
        }
        val array = JSONArray()
        for (draft in blocks) {
            require(draft.format in setOf("strength", "amrap", "forTime", "emom",
                "tabata", "circuit", "chipper", "afap", "ladder", "deathBy", "partner",
                "roundsForQuality", "maxEffort", "buyInCashOut")) {
                "Tipo de bloque no permitido"
            }
            require(draft.entries.isNotEmpty()) { "Cada bloque necesita al menos un ejercicio" }
            val nonRest = draft.entries.filterNot { isRestEntry(it) }
            require(nonRest.map { it.exerciseId }.distinct().size ==
                nonRest.size || draft.format != "strength") { "No repitas el mismo ejercicio en un bloque" }
            require(draft.timeCapMinutes in 1..180 && draft.rounds in 1..100)
            require(draft.emomIntervalSeconds in 15..600 &&
                draft.workSeconds in 5..600 && draft.restSeconds in 0..600)
            if (draft.format == "emom")
                require(draft.rounds.toLong() * draft.emomIntervalSeconds <= 10800L)
            if (draft.format == "tabata") {
                require(draft.rounds.toLong() * (draft.workSeconds + draft.restSeconds) <= 10800L)
                require(draft.workSeconds + draft.restSeconds <= 600)
            }
            // Sin esquema = cada movimiento conserva sus reps/repScheme propios (plantillas ladder con
            // movimientos repetidos, como WODTemplate.makeBlock de Apple). Con esquema, se valida.
            require(draft.format != "ladder" || draft.ladderScheme == null ||
                (draft.ladderScheme.size in 2..12 &&
                    draft.ladderScheme.all { it in 1..1000 })) {
                "La escalera necesita un esquema tipo 21-15-9"
            }
            array.put(buildBlock(draft.format, draft.title, draft.entries, byId,
                draft.timeCapMinutes, draft.rounds, draft.emomIntervalSeconds,
                draft.workSeconds, draft.restSeconds, draft.ladderScheme,
                draft.blockId, draft.sourceJson, draft.restBetweenRoundsSeconds))
        }
        return array
    }

    /**
     * DayPlus (equivalencia iOS DayEditorView): crea la rutina one-off SOLO al
     * Guardar el borrador del editor. Mientras el borrador está abierto no
     * existe rutina persistida: cancelar no deja artefactos ni consume cuota.
     */
    @Synchronized fun createRoutineFromDrafts(
        title: String,
        drafts: List<RoutineBlockDraft>,
        schedule: RoutineSchedule = RoutineSchedule(),
        routineId:String? = null,
        canCreateTemplate:(Int)->Boolean = {true},
        canCreateCustom: (Int) -> Boolean = { true }
    ): String {
        val cleaned = title.trim()
        require(cleaned.isNotBlank()) { "Escribe un título válido" }
        require(schedule.scheduledDate == null || schedule.weekday == null) {
            "Un entreno no puede ser semanal y de fecha concreta a la vez"
        }
        require(schedule.weekday == null || schedule.weekday in 1..7)
        require(schedule.timeMinutes == null || schedule.timeMinutes in 0..1439)
        val state = requireState()
        val id = routineId ?: UUID.randomUUID().toString()
        require(id.isNotBlank())
        if(routineId!=null && (0 until state.getJSONArray("routines").length()).any {
            state.getJSONArray("routines").getJSONObject(it).optString("id")==id
        }) return id
        requireTemplateSlot(state,schedule,canCreateTemplate)
        val nativeRoutine = JSONObject()
            .put("id", id)
            .put("title", cleaned)
            .put("blocks", validatedDraftBlocks(materializePendingCustoms(drafts, state, canCreateCustom), state))
            .put("progression", "off")
            .put("isFavorite", false)
        if (schedule.scheduledDate != null) {
            nativeRoutine.put("scheduledDate", LocalDate.parse(schedule.scheduledDate).toString())
        } else if (schedule.weekday != null) {
            nativeRoutine.put("weekday", schedule.weekday)
        }
        if (schedule.timeMinutes != null)
            nativeRoutine.put("scheduledTimeMinutes", schedule.timeMinutes)
        schedule.weekday?.let { WeeklyScheduleActions.makeWeekdayExclusive(state,id,it) }
        state.getJSONArray("routines").put(nativeRoutine)
        save(state)
        return id
    }

    /**
     * Registra un peso corporal manual (BodyWeightEntry de iOS:
     * {id, date, weightKg, source:"manual"}). Un registro por día: repetir
     * el mismo día sustituye la medición anterior.
     */
    @Synchronized fun logBodyWeight(weightKg: Double, date: String? = null): Pair<Long,Double> {
        require(weightKg.isFinite() && weightKg in 20.0..400.0) {
            "Peso fuera de rango"
        }
        val day = date?.let { LocalDate.parse(it) } ?: LocalDate.now()
        val state = requireState()
        val weights = state.optJSONArray("bodyWeights")
            ?: JSONArray().also { state.put("bodyWeights", it) }
        // Apple keeps the entry identity and uses the actual capture time, not midnight.
        val instant=if(date==null) Instant.now() else day.atStartOfDay(ZoneId.systemDefault()).toInstant()
        var preservedId:String?=null
        for (i in weights.length() - 1 downTo 0) {
            val entry = weights.optJSONObject(i) ?: continue
            if (BodyWeightHistory.day(entry.optString("date")) == day) {
                preservedId=entry.optString("id").takeIf {it.isNotBlank()};weights.remove(i)
            }
        }
        weights.put(JSONObject().put("id",preservedId ?: UUID.randomUUID().toString())
            .put("date",instant.toString()).put("weightKg",weightKg).put("source","manual"))
        save(state)
        return instant.toEpochMilli() to weightKg
    }

    /**
     * Fusiona el peso de Salud con el local (syncBodyWeight de iOS):
     * una entrada por día, gana la muestra más reciente; si Salud es más
     * nueva (o mismo instante con kg distinto) actualiza la local con
     * source "health". Devuelve los días solo locales para escribirlos
     * en Salud después.
     */
    @Synchronized fun mergeHealthBodyWeights(
        samples: List<Pair<Long, Double>>
    ): List<Pair<Long, Double>> {
        val state = requireState()
        val weights = state.optJSONArray("bodyWeights")
            ?: JSONArray().also { state.put("bodyWeights", it) }
        val zone = ZoneId.systemDefault()
        // Una muestra por día: la más reciente.
        val byDay = mutableMapOf<String, Pair<Long, Double>>()
        for ((millis, kg) in samples) {
            if (!(kg.isFinite() && kg > 0)) continue
            val day = Instant.ofEpochMilli(millis).atZone(zone).toLocalDate().toString()
            val existing = byDay[day]
            if (existing == null || millis > existing.first) byDay[day] = millis to kg
        }
        var changed = false
        for ((day, sample) in byDay) {
            var foundIndex = -1
            var foundMillis = 0L
            var foundKg = 0.0
            for (i in 0 until weights.length()) {
                val entry = weights.optJSONObject(i) ?: continue
                if (BodyWeightHistory.day(entry.optString("date"),zone)?.toString() == day) {
                    foundIndex = i
                    foundMillis = runCatching {
                        Instant.parse(entry.optString("date")).toEpochMilli()
                    }.getOrDefault(0L)
                    foundKg = entry.optDouble("weightKg")
                    break
                }
            }
            if (foundIndex >= 0) {
                if (sample.first > foundMillis ||
                    (kotlin.math.abs(sample.first - foundMillis) < 1000 &&
                        kotlin.math.abs(sample.second - foundKg) >= 0.05)) {
                    val entry = weights.getJSONObject(foundIndex)
                    entry.put("date", Instant.ofEpochMilli(sample.first).toString())
                    entry.put("weightKg", sample.second)
                    entry.put("source", "health")
                    changed = true
                }
            } else {
                weights.put(JSONObject()
                    .put("id", UUID.randomUUID().toString())
                    .put("date", Instant.ofEpochMilli(sample.first).toString())
                    .put("weightKg", sample.second)
                    .put("source", "health"))
                changed = true
            }
        }
        // Orden descendente como iOS tras la fusión.
        if (changed) {
            val sorted = (0 until weights.length())
                .map { weights.getJSONObject(it) }
                .sortedByDescending { runCatching {
                    Instant.parse(it.optString("date")).toEpochMilli()
                }.getOrDefault(0L) }
            while (weights.length() > 0) weights.remove(0)
            sorted.forEach { weights.put(it) }
            save(state)
        }
        // Días solo en Repera → Salud.
        val localOnly = mutableListOf<Pair<Long, Double>>()
        for (i in 0 until weights.length()) {
            val entry = weights.optJSONObject(i) ?: continue
            val day = BodyWeightHistory.day(entry.optString("date"),zone)?.toString() ?: continue
            if (byDay.containsKey(day)) continue
            val millis = runCatching {
                Instant.parse(entry.optString("date")).toEpochMilli()
            }.getOrNull() ?: continue
            val kg = entry.optDouble("weightKg")
            if (kg > 0) localOnly.add(millis to kg)
        }
        return localOnly
    }

    @Synchronized fun deleteBodyWeight(id: String) {
        val state = requireState()
        val weights = state.optJSONArray("bodyWeights") ?: return
        for (i in weights.length() - 1 downTo 0) {
            if (weights.optJSONObject(i)?.optString("id") == id) weights.remove(i)
        }
        save(state)
    }

    /**
     * Inserts a benchmark WOD from CatalogWods as a native routine, mirroring
     * Swift WODTemplate.makeBlock: repeated movements stay repeated (Fran's
     * 21-15-9), unmatched names resolve by catalog name at session assembly,
     * and prescribed weights/notes keep the shared snapshot fidelity.
     */
    @Synchronized fun createWodRoutine(
        template: dev.repera.domain.WodTemplate,
        schedule: RoutineSchedule = RoutineSchedule(),
        canCreateTemplate:(Int)->Boolean = {true}
    ): String {
        require(template.movements.isNotEmpty()) { "La plantilla no tiene movimientos" }
        require(template.movements.size <= 200) { "Demasiados movimientos" }
        require(schedule.scheduledDate == null || schedule.weekday == null) {
            "Un entreno no puede ser semanal y de fecha concreta a la vez"
        }
        require(schedule.weekday == null || schedule.weekday in 1..7)
        require(schedule.timeMinutes == null || schedule.timeMinutes in 0..1439)
        val state = requireState()
        requireTemplateSlot(state,schedule,canCreateTemplate)
        val nativeRoutine=buildWodTemplateRoutine(state,template)
        val id=nativeRoutine.getString("id")
        val scheduledDay = schedule.scheduledDate?.let { LocalDate.parse(it) }
        if (scheduledDay != null) {
            nativeRoutine.put("scheduledDate", scheduledDay.toString())
        } else if (schedule.weekday != null) {
            nativeRoutine.put("weekday", schedule.weekday)
        }
        if (schedule.timeMinutes != null)
            nativeRoutine.put("scheduledTimeMinutes", schedule.timeMinutes)
        schedule.weekday?.let { WeeklyScheduleActions.makeWeekdayExclusive(state,id,it) }
        state.getJSONArray("routines").put(nativeRoutine)
        save(state)
        return id
    }

    private fun buildWodTemplateRoutine(state:JSONObject,template:dev.repera.domain.WodTemplate):JSONObject {
        val catalog = state.getJSONArray("exercises")
        val byName = (0 until catalog.length()).associate {
            val exercise = catalog.getJSONObject(it)
            exercise.getString("name").lowercase() to exercise
        }
        val movements = JSONArray()
        for (move in template.movements) {
            val item = JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("name", move.name)
                .put("isRest", false)
            byName[move.name.lowercase()]?.let { item.put("exerciseId", it.getString("id")) }
            move.reps?.let { item.put("reps", it) }
            move.distanceMeters?.let { item.put("distanceMeters", it) }
            move.calories?.let { item.put("calories", it) }
            move.weightMaleKg?.let { item.put("weightMaleKg", it) }
            move.weightFemaleKg?.let { item.put("weightFemaleKg", it) }
            move.notes?.let { item.put("notes", it) }
            movements.put(item)
        }
        val block = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("title", template.name)
            .put("kind", "wod")
            .put("movements", movements)
            .put("wodFormat", template.format.wireName)
            .put("emomIntervalSeconds", template.emomIntervalSeconds ?: 60)
            .put("wodTemplateId", template.id)
        template.timeCapMinutes?.let { block.put("timeCapMinutes", it) }
        template.rounds?.let { block.put("rounds", it) }
        template.workSeconds?.let { block.put("workSeconds", it) }
        template.restSeconds?.let { block.put("restSeconds", it) }
        template.notes?.let { block.put("wodNotes", it) }
        val id = UUID.randomUUID().toString()
        val nativeRoutine = JSONObject()
            .put("id", id)
            .put("title", template.name)
            .put("blocks", JSONArray().put(block))
            .put("progression", "off")
            .put("isFavorite", false)
        return nativeRoutine
    }

    /** Library play is ephemeral: no saved template or template quota is involved. */
    @Synchronized fun startWodTemplate(templateId:String,requestId:String,allowAdvanced:Boolean=false):ActiveWorkout {
        require(requestId.isNotBlank())
        requireNoLiveActivity()
        val template=dev.repera.domain.CatalogWods.template(templateId) ?: error("WOD no encontrado")
        val state=requireState()
        val current=state.optJSONObject("activeSession")
        if(current?.optString("draftRequestId")==requestId) return summarize(current)
        check(current==null) {"Ya existe una sesión activa"}
        val history=state.getJSONArray("workouts")
        check((0 until history.length()).none {history.getJSONObject(it).optString("draftRequestId")==requestId}) {
            "Este inicio ya está guardado en el historial"
        }
        val routine=buildWodTemplateRoutine(state,template)
        val session=assembleSession(state,routine,allowAdvanced,applyDefaultPolicy=true).put("draftRequestId",requestId)
        state.put("activeSession",session);save(state)
        return summarize(session)
    }

    @Synchronized fun active(): ActiveWorkout? {
        val state = loadOrNull() ?: return null
        return state.optJSONObject("activeSession")?.let { summarize(it) }
    }

    /**
     * DayEditorView modo .session (StartHub «Crear entreno»): empieza una sesión desde un borrador. Título por
     * defecto «Mi entreno», progresión off, sin día. Con `saveAsFavorite` la rutina se guarda como favorita (la
     * llamante ya validó la cuota de rutinas, como Apple con saveRoutine). Sin favorito NO se persiste rutina alguna.
     * Todo se valida y construye antes de la única escritura: un fallo no deja sesión ni rutina.
     */
    private fun requireNoLiveActivity() {
        check(!LiveActivityRuntime.hasPendingActivity(context, googleId)) {
            "Hay una actividad En vivo pendiente. Finalízala, guárdala o descártala antes de iniciar otro entreno."
        }
    }

    @Synchronized fun startSessionFromDrafts(
        title: String, drafts: List<RoutineBlockDraft>, saveAsFavorite: Boolean,
        allowAdvancedProgression: Boolean = true,
        requestId:String? = null,
        canSaveFavorite:(Int)->Boolean = {true},
        canCreateCustom: (Int) -> Boolean = { true }
    ): ActiveWorkout {
        requireNoLiveActivity()
        val state = loadOrNull() ?: error("Importa primero un historial o crea tus datos locales")
        requestId?.let {id ->
            require(id.isNotBlank())
            state.optJSONObject("activeSession")?.takeIf {it.optString("draftRequestId")==id}?.let {return summarize(it)}
            val archive=state.getJSONArray("workouts")
            check((0 until archive.length()).none {archive.getJSONObject(it).optString("draftRequestId")==id}) {
                "Este borrador ya se guardó como entrenamiento terminado. Consulta el historial."
            }
        }
        check(state.isNull("activeSession")) { "Ya existe una sesión activa" }
        if(saveAsFavorite) requireTemplateSlot(state,RoutineSchedule(),canSaveFavorite)
        val cleaned = title.trim().ifEmpty { "Mi entreno" }
        val routine = JSONObject().put("id", UUID.randomUUID().toString()).put("title", cleaned)
            .put("blocks", validatedDraftBlocks(materializePendingCustoms(drafts, state, canCreateCustom), state))
            .put("progression", "off").put("isFavorite", saveAsFavorite)
        val session = assembleSession(state, routine, allowAdvancedProgression, applyDefaultPolicy = true)
        requestId?.let {session.put("draftRequestId",it)}
        if (saveAsFavorite) state.getJSONArray("routines").put(routine)
        state.put("activeSession", session)
        save(state)
        return summarize(session)
    }

    @Synchronized fun startStrengthRoutine(id: String): ActiveWorkout = startRoutine(id)

    @Synchronized fun startRoutine(id: String, allowAdvancedProgression: Boolean = true): ActiveWorkout {
        requireNoLiveActivity()
        val state = loadOrNull() ?: error("Importa primero un historial o crea tus datos locales")
        check(state.isNull("activeSession")) { "Ya existe una sesión activa" }
        val routines = state.getJSONArray("routines")
        val routine = (0 until routines.length()).map { routines.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id } ?: error("Rutina no encontrada")
        val session = assembleSession(state, routine, allowAdvancedProgression, applyDefaultPolicy = true)
        state.put("activeSession", session)
        save(state)
        return summarize(session)
    }

    /** Apple ProgressionEngine.applySuggestions por ejercicio: series uniformes con reps/peso sugeridos. */
    private fun progressedPlannedSets(
        exerciseId: String, plannedSets: JSONArray, policy: dev.repera.domain.ProgressionPolicy,
        history: List<dev.repera.domain.StatsWorkout>, incrementKg: Double
    ): JSONArray {
        val targets = (0 until plannedSets.length()).map { t ->
            val set = plannedSets.getJSONObject(t)
            dev.repera.domain.PlannedTarget(
                targetReps = set.optInt("targetReps").takeIf { it > 0 } ?: 8,
                targetWeightKg = if (set.has("targetWeightKg") && !set.isNull("targetWeightKg"))
                    set.optDouble("targetWeightKg") else null)
        }
        val suggestion = dev.repera.domain.ProgressionEngine.suggest(
            exerciseId = exerciseId, planned = targets, policy = policy, workouts = history, incrementKg = incrementKg)
        val out = JSONArray()
        repeat(maxOf(suggestion.setCount, 1)) {
            val set = JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", suggestion.reps)
            suggestion.weightKg?.let { w -> set.put("targetWeightKg", w) }
            out.put(set)
        }
        return out
    }

    /** Catálogo empaquetado para el respaldo offline BTT/T2B al iniciar WODs
     *  (Apple Catalog.seed() dentro de catalogExercise). Lectura de asset,
     *  nunca se inserta en el estado. */
    private val packagedSeed: () -> JSONArray by lazy {
        {
            context.assets.open("catalog_seed.json").bufferedReader(Charsets.UTF_8)
                .use { JSONArray(it.readText()) }
        }
    }

    /** Monta el JSON de sesión de una rutina sin persistirlo (plan del día). */
    private fun assembleSession(
        state: JSONObject, routine: JSONObject,
        allowAdvanced: Boolean = true, applyDefaultPolicy: Boolean = false
    ): JSONObject {
        val blocks = routine.optJSONArray("blocks") ?: JSONArray()
        require(blocks.length() > 0) { "Esta rutina no tiene bloques" }
        // Refuse unsupported formats atomically before touching the local document.
        check((0 until blocks.length()).all { i ->
            val block = blocks.getJSONObject(i)
            block.optString("kind") == "strength" || WodSessionAssembler.supports(block)
        }) { "Hay bloques que requieren un editor WOD aún no disponible" }
        val catalog = state.getJSONArray("exercises")
        val byId = (0 until catalog.length()).associate {
            val exercise = catalog.getJSONObject(it)
            exercise.getString("id") to exercise
        }
        // ReperaStore.startSession iOS: sin acceso a progresión avanzada no se aplican sugerencias; con acceso,
        // ProgressionEngine.applySuggestions usa `routine.progression == .off ? settings.defaultProgression : routine.progression`.
        val routinePolicy = dev.repera.domain.ProgressionPolicy
            .fromWire(routine.optString("progression"))
            ?: dev.repera.domain.ProgressionPolicy.OFF
        val settings = state.optJSONObject("settings")
        val policy = when {
            !allowAdvanced -> dev.repera.domain.ProgressionPolicy.OFF
            applyDefaultPolicy && routinePolicy == dev.repera.domain.ProgressionPolicy.OFF ->
                dev.repera.domain.ProgressionPolicy.fromWire(settings?.optString("defaultProgression").orEmpty())
                    ?: dev.repera.domain.ProgressionPolicy.LINEAR
            else -> routinePolicy
        }
        val incrementKg = settings?.takeIf { it.has("weightIncrementKg") && !it.isNull("weightIncrementKg") }
            ?.getDouble("weightIncrementKg")?.takeIf { it > 0 } ?: dev.repera.domain.ProgressionEngine.defaultIncrementKg
        val history = if (policy != dev.repera.domain.ProgressionPolicy.OFF)
            ProgressSnapshotBuilder.statsWorkouts(state) else emptyList()
        val planned = JSONArray()
        for (blockIndex in 0 until blocks.length()) {
            val block = blocks.getJSONObject(blockIndex)
            if (block.optString("kind") == "wod") {
                val firstWod = planned.length()
                WodSessionAssembler.append(block, catalog, planned, packagedSeed())
                if (policy != dev.repera.domain.ProgressionPolicy.OFF) {
                    // Apple applySuggestions recorre TODOS los ejercicios de la sesión, también movimientos WOD, y
                    // sustituye plannedSets por series uniformes (reps/peso sugeridos). Réplica literal.
                    for (k in firstWod until planned.length()) {
                        val mv = planned.getJSONObject(k)
                        mv.put("plannedSets", progressedPlannedSets(mv.getJSONObject("exercise").getString("id"),
                            mv.getJSONArray("plannedSets"), policy, history, incrementKg))
                    }
                }
                continue
            }
            val entries = block.optJSONArray("exercises") ?: JSONArray()
            for (j in 0 until entries.length()) {
                val entry = entries.getJSONObject(j)
                val exercise = byId[entry.getString("exerciseId")]
                    ?: error("La rutina contiene un ejercicio ausente del catálogo")
                check(supportsSimpleInput(exercise)) {
                    "La rutina requiere un tipo de entrada que todavía no está disponible en Android"
                }
                var plannedSets = JSONArray(
                    (entry.optJSONArray("plannedSets") ?: JSONArray()).toString())
                if (policy != dev.repera.domain.ProgressionPolicy.OFF) {
                    plannedSets = progressedPlannedSets(entry.getString("exerciseId"), plannedSets, policy, history, incrementKg)
                }
                // Apple SessionController.from: SessionExercise.id = id del ítem de la rutina.
                val item = JSONObject()
                    .put("id", entry.optString("id").ifBlank { UUID.randomUUID().toString() })
                    .put("exercise", JSONObject(exercise.toString()))
                    .put("plannedSets", plannedSets)
                    .put("loggedSets", JSONArray())
                    .put("completedReps", 0)
                    .put("isCompleted", false)
                    .put("blockId", block.getString("id"))
                    .put("blockKind", "strength")
                copyIfPresent(entry, item, "restSeconds", "quantityUnit")
                copyIfPresent(block, item, "wodFormat")
                if (block.has("timeCapMinutes")) item.put("blockTimeCapMinutes", block.getInt("timeCapMinutes"))
                if (block.has("emomIntervalSeconds")) item.put("blockIntervalSeconds", block.getInt("emomIntervalSeconds"))
                if (block.has("rounds")) item.put("blockRounds", block.getInt("rounds"))
                if (block.has("workSeconds")) item.put("blockWorkSeconds", block.getInt("workSeconds"))
                if (block.has("restSeconds")) item.put("blockRestSeconds", block.getInt("restSeconds"))
                if (block.has("restBetweenRoundsSeconds")) item.put("blockRestBetweenRoundsSeconds", block.getInt("restBetweenRoundsSeconds"))
                item.put("blockHeader", block.optString("title"))
                planned.put(item)
            }
        }
        require(planned.length() > 0) { "La rutina no contiene ejercicios ejecutables" }
        return JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("title", routine.getString("title"))
            .put("routineId", routine.getString("id"))
            .put("exercises", planned)
            .put("currentIndex", 0)
            .put("phase", "ready")
            .put("startedAt", nowISO8601())
            .put("wodResults", JSONArray())
            .put("routineBlocks", JSONArray(blocks.toString()))
            .put("routePoints", JSONArray())
    }

    /** Direct ficha log: one atomic archive write, never steals the active session. */
    @Synchronized fun logQuickSets(exerciseId:String,rows:List<QuickLogRow>,notes:String?,requestId:String):String {
        require(requestId.isNotBlank())
        val state=requireState();val archive=state.getJSONArray("workouts")
        if((0 until archive.length()).any {archive.getJSONObject(it).optString("id")==requestId}) return requestId
        val catalog=state.getJSONArray("exercises")
        val exercise=(0 until catalog.length()).map {catalog.getJSONObject(it)}.firstOrNull {it.optString("id")==exerciseId} ?: error("Ejercicio no encontrado")
        val mode=inputMode(exercise);val unit=rows.firstOrNull()?.unit ?: error("Añade una serie")
        val normalized=QuickLogRows.validate(rows,mode,ExerciseInput.defaultQuantityUnit(exercise.getString("name"),exercise.optString("equipment")),ExerciseInput.supportsCaloriesAndMeters(exercise.getString("name"),exercise.optString("equipment")),isMobilityHold(exercise),ExerciseInput.supportsRepsOrMeters(exercise.getString("name")))
        val now=Instant.now();val logged=JSONArray();val planned=JSONArray()
        normalized.forEach {row ->
            val set=JSONObject().put("id",UUID.randomUUID().toString()).put("reps",row.quantity)
                .put("completedAt",now.toString()).put("phase","work").put("kind","straight").put("toFailure",false)
                .put("quantityUnit",row.unit).put("drops",JSONArray()).put("clusters",JSONArray())
            row.weightKg?.takeIf {it>0}?.let {set.put("weightKg",it)}
            row.deficitCm?.takeIf {it>0}?.let {set.put("deficitCm",it)}
            row.durationSeconds?.let {set.put("durationSeconds",it)}
            logged.put(set)
            planned.put(JSONObject().put("id",UUID.randomUUID().toString()).put("targetReps",row.quantity).apply {row.weightKg?.takeIf {it>0}?.let {put("targetWeightKg",it)}})
        }
        val entry=JSONObject().put("id",UUID.randomUUID().toString()).put("exercise",JSONObject(exercise.toString()))
            .put("plannedSets",planned).put("loggedSets",logged).put("completedReps",normalized.sumOf {it.quantity}).put("isCompleted",true).put("quantityUnit",unit)
        val seconds=maxOf(60,normalized.size*90)
        val session=JSONObject().put("id",requestId).put("title","Apuntar · "+exercise.getString("name"))
            .put("phase","finished").put("startedAt",now.minusSeconds(seconds.toLong()).toString()).put("finishedAt",now.toString())
            .put("exercises",JSONArray().put(entry)).put("currentIndex",0).put("wodResults",JSONArray()).put("routePoints",JSONArray())
            .put("appleDurationSeconds",seconds)
        notes?.trim()?.takeIf {it.isNotBlank()}?.let {session.put("notes",it)}
        archive.put(session)
        val review=SessionReviewSupport.attachToFinishedSession(state,session)
        save(state)
        if(review!=null) reviewPrefs.edit().putString(SessionReviewSupport.PREFS_PENDING_KEY,requestId).apply()
        return requestId
    }

    /**
     * Swift ReperaStore.startQuickLog: one selected real exercise, three targets
     * copied from the latest saved workout when available; never invent recorded sets.
     */
    @Synchronized fun startQuickLog(exerciseId: String): ActiveWorkout {
        requireNoLiveActivity()
        val state = requireState()
        check(state.isNull("activeSession")) { "Ya existe una sesión activa" }
        val catalog = state.getJSONArray("exercises")
        val exercise = (0 until catalog.length()).map { catalog.getJSONObject(it) }
            .firstOrNull { it.optString("id") == exerciseId }
            ?: error("Ejercicio no encontrado")
        val history = state.getJSONArray("workouts")
        val inputMode = inputMode(exercise)
        val mobilityHold = isMobilityHold(exercise)
        val defaultUnit = ExerciseInput.defaultQuantityUnit(
            exercise.getString("name"), exercise.optString("equipment"))
        var lastUnit = defaultUnit
        var lastReps: Int? = null
        var lastWeight: Double? = null
        historyLoop@ for (w in history.length() - 1 downTo 0) {
            val work = history.getJSONObject(w).optJSONArray("exercises") ?: continue
            for (j in 0 until work.length()) {
                val previous = work.getJSONObject(j)
                if (previous.optJSONObject("exercise")?.optString("id") != exerciseId) continue
                val logged = previous.optJSONArray("loggedSets") ?: continue
                for (k in logged.length() - 1 downTo 0) {
                    val set = logged.getJSONObject(k)
                    if (set.optString("phase", "work") != "work") continue
                    lastReps = set.optInt("reps", 8)
                    lastUnit = set.optString("quantityUnit").takeIf {
                        it == "calories" || it == "meters" || it == "reps"
                    } ?: previous.optString("quantityUnit").takeIf {
                        it == "calories" || it == "meters" || it == "reps"
                    } ?: defaultUnit
                    if (set.has("weightKg") && !set.isNull("weightKg")) lastWeight = set.getDouble("weightKg")
                    break@historyLoop
                }
            }
        }
        check(supportsSimpleInput(exercise)) {
            "Este ejercicio requiere un tipo de entrada aún no disponible"
        }
        val presets = JSONArray()
        repeat(if (inputMode == ExerciseInputMode.MACHINE_WORK ||
            inputMode == ExerciseInputMode.REPS_AND_TIME) 1 else 3) {
            val target = JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("targetReps", lastReps ?: when {
                    mobilityHold -> 1
                    inputMode == ExerciseInputMode.MACHINE_WORK -> 0
                    else -> 8
                })
            if (mobilityHold) target.put("targetDurationSeconds", 30)
                .put("targetPercent1RMIsMinimum", false)
            if (lastWeight != null) target.put("targetWeightKg", lastWeight)
            presets.put(target)
        }
        val entry = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("exercise", JSONObject(exercise.toString()))
            .put("plannedSets", presets)
            .put("loggedSets", JSONArray())
            .put("completedReps", 0)
            .put("isCompleted", false)
            .put("quantityUnit", lastUnit)
        val session = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("title", "Apuntar · " + exercise.getString("name"))
            .put("exercises", JSONArray().put(entry))
            .put("currentIndex", 0)
            .put("phase", "ready")
            .put("startedAt", nowISO8601())
            .put("wodResults", JSONArray())
            .put("routePoints", JSONArray())
        state.put("activeSession", session)
        save(state)
        return summarize(session)
    }

    @Synchronized fun logCurrentSet(
        quantity: Int,
        weightKg: Double?,
        rir: Double? = null,
        warmup: Boolean = false,
        setId: String? = null,
        quantityUnit: String? = null,
        durationSeconds: Int? = null,
        deficitCm: Int? = null,
        toFailure: Boolean = false
    ): ActiveWorkout {
        require(setId == null || setId.isNotBlank())
        require(quantity >= 0) { "Cantidad inválida" }
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0)) { "Peso inválido" }
        require(rir == null || (rir.isFinite() && rir >= 0)) { "RIR inválido" }
        require(durationSeconds == null || durationSeconds in 1..86400) { "Duración inválida" }
        require(deficitCm == null || deficitCm in 0..100) { "Déficit HSPU inválido" }
        require(quantityUnit == null || quantityUnit in setOf("reps", "calories", "meters"))
        val state = requireState()
        val session = requireActive(state)
        val array = session.getJSONArray("exercises")
        val index = session.getInt("currentIndex")
        val exercise = array.getJSONObject(index)
        check(exercise.optString("blockKind") != "wod") { "Los scores WOD se registran por bloque" }
        val movement = exercise.getJSONObject("exercise")
        val inputMode = inputMode(movement)
        check(inputMode.basicRecorderAvailable)
        check(deficitCm == null || inputMode == ExerciseInputMode.HSPU_DEFICIT) {
            "El déficit solo se registra en HSPU"
        }
        if (inputMode == ExerciseInputMode.MACHINE_WORK || inputMode == ExerciseInputMode.REPS_AND_TIME) {
            check(weightKg == null && rir == null && !warmup && !toFailure) { "Cardio no admite lastre, RIR o calentamiento de fuerza" }
        }
        check(inputMode.showsWeight || weightKg == null) {
            "Este ejercicio no registra peso"
        }
        val logged = exercise.getJSONArray("loggedSets")
        val set = JSONObject()
            .put("id", setId ?: UUID.randomUUID().toString())
            .put("reps", quantity)
            .put("completedAt", nowISO8601())
            .put("phase", if (warmup) "warmup" else "work")
            .put("kind", "straight")
            .put("toFailure", toFailure && !warmup)
            .put("drops", JSONArray())
            .put("clusters", JSONArray())
        if (weightKg != null) set.put("weightKg", weightKg)
        if (toFailure && !warmup) set.put("rir", 0.0)
        else if (rir != null && !warmup) set.put("rir", rir)
        if (deficitCm != null) set.put("deficitCm", deficitCm)
        val unit = quantityUnit ?: exercise.optString("quantityUnit")
            .takeIf { it in setOf("reps", "calories", "meters") }
            ?: ExerciseInput.defaultQuantityUnit(
                movement.getString("name"), movement.optString("equipment"))
        if(ExerciseInput.supportsRepsOrMeters(movement.getString("name"))) {
            check(unit in setOf("reps","meters")) {"Unidad incompatible con el ejercicio"}
        } else if (inputMode == ExerciseInputMode.LOAD_DISTANCE) {
            // Apple 1d1edc8b/f7109bd7: los recorridos alternan reps/metros.
            check(unit == "meters" || ExerciseInput.supportsRepsOrMeters(
                movement.getString("name")) && unit == "reps") {
                "Este transporte se registra en metros" }
        } else if (inputMode == ExerciseInputMode.MACHINE_WORK) {
            // f7109bd7: burpee broad jump (reps/m sin lastre) tambien alterna.
            check(unit == "meters" || unit == "calories" ||
                ExerciseInput.supportsRepsOrMeters(movement.getString("name")) && unit == "reps")
            if (!ExerciseInput.supportsCaloriesAndMeters(
                    movement.getString("name"), movement.optString("equipment"))) {
                check(unit == ExerciseInput.defaultQuantityUnit(
                    movement.getString("name"), movement.optString("equipment"))) {
                    "Este ejercicio registra distancia en metros"
                }
            }
        } else check(unit == "reps") { "Unidad incompatible con el ejercicio" }
        set.put("quantityUnit", unit)
        if (durationSeconds != null) set.put("durationSeconds", durationSeconds)
        exercise.put("quantityUnit", unit)
        logged.put(set)
        if (!warmup) exercise.put("completedReps", exercise.optInt("completedReps") + quantity)
        session.put("phase", "counting")
        save(state)
        return summarize(session)
    }

    /**
     * Dropset: serie principal + caídas (reps y peso opcional por caída).
     * Espejo de LoggedSet.kind = .dropset en iOS; completedReps suma la serie
     * madre y todas las caídas, como CompletedWorkoutEditing/completedReps.
     */
    @Synchronized fun logDropSet(
        quantity: Int, weightKg: Double?,
        drops: List<Pair<Int, Double?>>,
        rir: Double? = null, toFailure: Boolean = false,
        setId: String? = null
    ): ActiveWorkout {
        require(setId == null || setId.isNotBlank())
        require(quantity in 1..10000) { "Cantidad inválida" }
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0)) { "Peso inválido" }
        require(drops.size in 1..5) { "La dropset necesita entre 1 y 5 caídas" }
        drops.forEach { (reps, weight) ->
            require(reps in 1..10000) { "Repeticiones de caída inválidas" }
            require(weight == null || (weight.isFinite() && weight >= 0)) { "Peso de caída inválido" }
        }
        require(rir == null || (rir.isFinite() && rir >= 0)) { "RIR inválido" }
        val state = requireState()
        val session = requireActive(state)
        val exercise = session.getJSONArray("exercises")
            .getJSONObject(session.getInt("currentIndex"))
        check(exercise.optString("blockKind") != "wod") { "Los scores WOD se registran por bloque" }
        val movement = exercise.getJSONObject("exercise")
        val inputMode = inputMode(movement)
        check(inputMode in setOf(ExerciseInputMode.LOAD_REPS, ExerciseInputMode.REPS_ONLY,
            ExerciseInputMode.HSPU_DEFICIT)) {
            "Las dropsets solo aplican a ejercicios de fuerza"
        }
        check(inputMode(movement).showsWeight ||
            (weightKg == null && drops.all { it.second == null })) {
            "Este ejercicio no registra peso"
        }
        val set = JSONObject()
            .put("id", setId ?: UUID.randomUUID().toString())
            .put("reps", quantity)
            .put("completedAt", nowISO8601())
            .put("phase", "work")
            .put("kind", "dropset")
            .put("toFailure", toFailure)
            .put("clusters", JSONArray())
            .put("quantityUnit", "reps")
        if (toFailure) set.put("rir", 0.0) else if (rir != null) set.put("rir", rir)
        if (weightKg != null) set.put("weightKg", weightKg)
        val dropArray = JSONArray()
        drops.forEach { (reps, weight) ->
            val segment = JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("reps", reps)
            if (weight != null) segment.put("weightKg", weight)
            dropArray.put(segment)
        }
        set.put("drops", dropArray)
        exercise.getJSONArray("loggedSets").put(set)
        exercise.put("completedReps",
            exercise.optInt("completedReps") + quantity + drops.sumOf { it.first })
        session.put("phase", "counting")
        save(state)
        return summarize(session)
    }

    /**
     * Rest-pause: mini-series con microdescansos. Espejo de kind = .restpause:
     * las reps de la serie madre son la SUMA de los clusters.
     */
    @Synchronized fun logRestPauseSet(
        clusters: List<Pair<Int, Int>>,
        weightKg: Double? = null,
        rir: Double? = null, toFailure: Boolean = false,
        setId: String? = null
    ): ActiveWorkout {
        require(setId == null || setId.isNotBlank())
        require(clusters.isNotEmpty()) { "El rest-pause necesita al menos 1 mini-serie" }
        clusters.forEach { (reps, rest) ->
            require(reps in 1..10000) { "Repeticiones de mini-serie inválidas" }
            require(rest in 1..600) { "Descanso de mini-serie inválido" }
        }
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0)) { "Peso inválido" }
        require(rir == null || (rir.isFinite() && rir >= 0)) { "RIR inválido" }
        val state = requireState()
        val session = requireActive(state)
        val exercise = session.getJSONArray("exercises")
            .getJSONObject(session.getInt("currentIndex"))
        check(exercise.optString("blockKind") != "wod") { "Los scores WOD se registran por bloque" }
        val movement = exercise.getJSONObject("exercise")
        val inputMode = inputMode(movement)
        check(inputMode in setOf(ExerciseInputMode.LOAD_REPS, ExerciseInputMode.REPS_ONLY,
            ExerciseInputMode.HSPU_DEFICIT)) {
            "El rest-pause solo aplica a ejercicios de fuerza"
        }
        check(inputMode(movement).showsWeight || weightKg == null) {
            "Este ejercicio no registra peso"
        }
        val total=clusters.sumOf {it.first.toLong()}
        require(total<=Int.MAX_VALUE) {"Demasiadas repeticiones"}
        val totalReps=total.toInt()
        val set = JSONObject()
            .put("id", setId ?: UUID.randomUUID().toString())
            .put("reps", totalReps)
            .put("completedAt", nowISO8601())
            .put("phase", "work")
            .put("kind", "restpause")
            .put("toFailure", toFailure)
            .put("drops", JSONArray())
            .put("quantityUnit", "reps")
        if (toFailure) set.put("rir", 0.0) else if (rir != null) set.put("rir", rir)
        if (weightKg != null) set.put("weightKg", weightKg)
        val clusterArray = JSONArray()
        clusters.forEach { (reps, rest) ->
            clusterArray.put(JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("reps", reps)
                .put("restSeconds", rest))
        }
        set.put("clusters", clusterArray)
        exercise.getJSONArray("loggedSets").put(set)
        exercise.put("completedReps", exercise.optInt("completedReps") + totalReps)
        session.put("phase", "counting")
        save(state)
        return summarize(session)
    }

    /** Read-only editor draft. Canceling never creates a routine. */
    @Synchronized fun activeRoutineForEditing(): RoutineEntry {
        val state=requireState();val session=requireActive(state)
        val list=state.getJSONArray("routines")
        val routine=(0 until list.length()).map {list.getJSONObject(it)}
            .firstOrNull {it.optString("id")==session.optString("routineId")}
            // Apple (live main): the session's own blocks are newer than the reusable template.
            ?.let {template ->session.optJSONArray("routineBlocks")?.takeIf {it.length()>0}
                ?.let {blocks ->JSONObject(template.toString()).put("blocks",JSONArray(blocks.toString()))} ?: template}
            ?: ActiveSessionFavorite.template(session).apply {
                put("id",UUID.nameUUIDFromBytes(("active-editor:"+session.getString("id")).toByteArray(Charsets.UTF_8)).toString())
                put("isFavorite",false)
                // Editor preserves current quantity units and explicit WOD prescriptions.
                val entries=session.getJSONArray("exercises")
                val copy=JSONObject(session.toString())
                for(i in 0 until entries.length()) copy.getJSONArray("exercises").getJSONObject(i).put("loggedSets",JSONArray())
                put("blocks",CompletedWorkoutEditing.blocksFrom(copy,null))
            }
        val view=JSONObject(state.toString()).put("routines",JSONArray().put(routine))
        return requireNotNull(StateOverview.fromBytes(view.toString().toByteArray())).routineEntries.single()
    }

    @Synchronized fun updateActiveSessionPlan(
        draftId:String, blocks:List<RoutineBlockDraft>,expectedSessionId:String?=null,
        canCreateTemplate:(Int)->Boolean = {true},canCreateCustom:(Int)->Boolean = {true}
    ): ActiveWorkout {
        val state=requireState();val session=requireActive(state)
        check(expectedSessionId==null || session.optString("id")==expectedSessionId) {"La sesión cambió durante la edición"}
        val routines=state.getJSONArray("routines")
        val existing=(0 until routines.length()).map {routines.getJSONObject(it)}.firstOrNull {it.optString("id")==draftId}
        check(existing==null || session.optString("routineId")==draftId) {"La rutina de la sesión cambió durante la edición"}
        if(existing==null) requireTemplateSlot(state,RoutineSchedule(),canCreateTemplate)
        val routine=existing ?: JSONObject().put("id",draftId).put("title",session.optString("title"))
            .put("progression","off").put("isFavorite",false)
        routine.put("blocks",validatedDraftBlocks(materializePendingCustoms(blocks,state,canCreateCustom),state))
        val fresh=assembleSession(state,routine,allowAdvanced=false)
        ActiveSessionPlan.refresh(session,fresh)
        if(existing==null) {routines.put(routine);session.put("routineId",draftId)}
        save(state)
        return summarize(session)
    }

    @Synchronized fun saveActiveSessionAsFavorite(canCreateTemplate:(Int)->Boolean = {true}): ActiveWorkout {
        val state=requireState()
        ActiveSessionFavorite.save(state,canCreateTemplate)
        save(state)
        return summarize(requireActive(state))
    }

    /** Navigation never confirms an exercise or fabricates completed work. */
    @Synchronized fun selectActiveExercise(index: Int): ActiveWorkout {
        val state = requireState(); val session = requireActive(state)
        require(index in 0 until session.getJSONArray("exercises").length())
        session.put("currentIndex",index).put("phase","ready")
        save(state); return summarize(session)
    }
    /** Apple ReperaStore.updateActiveExerciseDraft: persists edited planned sets (and optionally recorded sets by id) of the
     *  active session in one save. Returns false when nothing changed. Not called from any Play UI yet. */
    @Synchronized fun updateActiveExerciseDraft(id: String, plannedSets: JSONArray, quantityUnit: String?, performedSets: JSONArray? = null): Boolean {
        val state = requireState(); val session = requireActive(state)
        val changedPlan = ActiveSessionDraft.update(session, id, plannedSets, quantityUnit)
        val changedResults = performedSets?.let { ActiveSessionDraft.replaceRecordedSets(session, id, it) } ?: false
        if (!changedPlan && !changedResults) return false
        save(state); return true
    }

    /**
     * Apple persistActiveLiveDraft: ONE save of the edited live rows of the current exercise: planned sets (revise) plus
     * recorded sets by id (recorded). The caller must only call this after the user edited the exercise, so untouched
     * suggestions are never saved as results. WOD blocks are excluded (their rows live in the WOD editor).
     */
    @Synchronized internal fun persistLiveRows(sessionId: String, exerciseIndex: Int, rows: List<ActiveSessionDraft.Row>, quantityUnit: String?): ActiveWorkout? {
        val state = requireState()
        val changed = ActiveSessionDraft.applyRows(state, sessionId, exerciseIndex, rows, quantityUnit, nowISO8601()) { inputMode(it) } ?: return null
        if (changed) save(state)
        return summarize(state.getJSONObject("activeSession"))
    }

    /** "Quitar serie" for a pending (not yet recorded) planned set of the current exercise. Recorded sets use deleteCurrentSet. */
    @Synchronized fun removePendingSet(setId: String): ActiveWorkout {
        val state = requireState(); val session = requireActive(state)
        val exercise = session.getJSONArray("exercises").getJSONObject(session.getInt("currentIndex"))
        check(exercise.optString("blockKind") != "wod") { "Usa el editor WOD para estos movimientos" }
        check(ActiveSessionDraft.removePending(session, exercise.getString("id"), setId)) { "Serie pendiente no encontrada" }
        save(state); return summarize(session)
    }

    /** Edits reps/weight of a pending planned set of the current exercise (Apple live row edit, planned part only). */
    @Synchronized fun editPendingSet(setId: String, reps: Int, weightKg: Double?): ActiveWorkout {
        val state = requireState(); val session = requireActive(state)
        val exercise = session.getJSONArray("exercises").getJSONObject(session.getInt("currentIndex"))
        check(exercise.optString("blockKind") != "wod") { "Usa el editor WOD para estos movimientos" }
        val byWeight = inputMode(exercise.getJSONObject("exercise")).showsWeight
        check(ActiveSessionDraft.editPending(session, exercise.getString("id"), setId, reps, weightKg, byWeight)) { "Serie pendiente no encontrada o sin cambios" }
        save(state); return summarize(session)
    }

    @Synchronized fun updateActiveSessionNotes(notes: String) {
        val state = requireState(); val session = requireActive(state)
        val trimmed = notes.trim()
        if (trimmed.isEmpty()) session.remove("notes") else session.put("notes",trimmed)
        save(state)
    }

    @Synchronized fun next(): ActiveWorkout? {
        val state = requireState()
        val session = requireActive(state)
        val exercises = session.getJSONArray("exercises")
        val index = session.getInt("currentIndex")
        check(exercises.getJSONObject(index).optString("blockKind") != "wod") {
            "Registra el resultado global del bloque WOD para continuar"
        }
        exercises.getJSONObject(index).put("isCompleted", true)
        if (index + 1 == exercises.length()) {
            finishInPlace(state, session)
            return null
        }
        session.put("currentIndex", index + 1).put("phase", "ready")
        save(state)
        return summarize(session)
    }

    /**
     * Swift SessionController.recordWODResult + finishCurrentBlock.
     * 'totalReps' is additional reps after full rounds, NOT an invented sum.
     */
    @Synchronized fun recordWodScore(
        roundsCompleted: Int?, additionalReps: Int?, elapsedSeconds: Int?
    ): ActiveWorkout? {
        val state = requireState()
        val session = requireActive(state)
        val exercises = session.getJSONArray("exercises")
        val index = session.getInt("currentIndex")
        val current = exercises.getJSONObject(index)
        require(current.optString("blockKind") == "wod") { "El ejercicio actual no es un bloque WOD" }
        val format = WodFormat.fromWire(current.getString("wodFormat"))
            ?: error("Formato WOD no reconocido")
        when (format.capture) {
            ResultCapture.TOTAL_REPS -> {
                require(additionalReps != null && additionalReps >= 0)
                require(elapsedSeconds == null)
                if (format == WodFormat.AMRAP || format == WodFormat.DEATH_BY) {
                    require(roundsCompleted != null && roundsCompleted >= 0)
                } else require(roundsCompleted == null)
            }
            ResultCapture.ELAPSED_TIME -> {
                require(elapsedSeconds != null && elapsedSeconds >= 0)
                require(roundsCompleted == null && additionalReps == null)
            }
            ResultCapture.PER_MOVEMENT_SETS ->
                error("Este formato requiere el editor de series por movimiento")
        }
        val blockId = current.getString("blockId")
        val original = session.optJSONArray("routineBlocks")
        val block = original?.let { blocks ->
            (0 until blocks.length()).map { blocks.getJSONObject(it) }
                .firstOrNull { it.optString("id") == blockId }
        }
        val score = JSONObject().put("id", blockId).put("format", format.wireName)
        if (roundsCompleted != null) score.put("roundsCompleted", roundsCompleted)
        if (additionalReps != null) score.put("totalReps", additionalReps)
        if (elapsedSeconds != null) score.put("elapsedSeconds", elapsedSeconds)
        if (block?.has("wodTemplateId") == true && !block.isNull("wodTemplateId"))
            score.put("wodTemplateId", block.getString("wodTemplateId"))
        val previous = session.optJSONArray("wodResults") ?: JSONArray()
        val revised = JSONArray()
        for (i in 0 until previous.length()) {
            if (previous.getJSONObject(i).optString("id") != blockId)
                revised.put(previous.getJSONObject(i))
        }
        revised.put(score)
        session.put("wodResults", revised)
        var nextIndex = index + 1
        // Finish all movements in the same block (including a user-selected movement).
        for (i in 0 until exercises.length()) {
            if (exercises.getJSONObject(i).optString("blockId") == blockId)
                exercises.getJSONObject(i).put("isCompleted", true)
        }
        while (nextIndex < exercises.length() &&
            exercises.getJSONObject(nextIndex).optString("blockId") == blockId) {
            nextIndex++
        }
        if (nextIndex == exercises.length()) {
            finishInPlace(state, session)
            return null
        }
        session.put("currentIndex", nextIndex).put("phase", "ready")
        save(state)
        return summarize(session)
    }

    /** Explicit per-movement confirmation. Timer intervals never create logged work. */
    @Synchronized fun recordWodMovement(
        movementIndex: Int, intervalIndex: Int, quantity: Int, weightKg: Double?,
        setId: String = UUID.randomUUID().toString()
    ): ActiveWorkout {
        require(movementIndex >= 0 && intervalIndex >= 0 && quantity >= 0)
        require(setId.isNotBlank())
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0))
        val state = requireState()
        val session = requireActive(state)
        val exercises = session.getJSONArray("exercises")
        val current = exercises.getJSONObject(session.getInt("currentIndex"))
        check(current.optString("blockKind") == "wod")
        val format = WodFormat.fromWire(current.getString("wodFormat"))
        check(format?.capture == ResultCapture.PER_MOVEMENT_SETS) {
            "Este formato registra un resultado global"
        }
        val blockId = current.getString("blockId")
        // Interval numbers must belong to the actual programmed block, rather
        // than permitting an accidental set outside the workout time window.
        val sourceBlock = session.optJSONArray("routineBlocks")?.let { blocks ->
            (0 until blocks.length()).map { blocks.getJSONObject(it) }
                .firstOrNull { it.optString("id") == blockId }
        }
        val maximumInterval = when (format) {
            WodFormat.EMOM, WodFormat.TABATA ->
                sourceBlock?.optInt("rounds", if (format == WodFormat.TABATA) 8 else 0)
                    ?.takeIf { it > 0 }
            WodFormat.CIRCUIT -> {
                val rounds = sourceBlock?.optInt("rounds", 0) ?: 0
                val stations = sourceBlock?.optJSONArray("movements")?.let { array ->
                    (0 until array.length()).count { !array.getJSONObject(it).optBoolean("isRest") }
                } ?: 0
                (rounds.toLong() * stations).takeIf { it in 1..10000 }
                    ?.toInt()
            }
            else -> null
        }
        if (maximumInterval != null)
            require(intervalIndex < maximumInterval) { "Intervalo fuera de la programación" }
        val movements = (0 until exercises.length()).map { exercises.getJSONObject(it) }
            .filter { it.optString("blockId") == blockId }
        require(movementIndex < movements.size) { "Movimiento fuera del bloque" }
        val exercise = movements[movementIndex]
        val set = JSONObject()
            .put("id", setId)
            .put("reps", quantity)
            .put("completedAt", nowISO8601())
            .put("phase", "work")
            .put("kind", "straight")
            .put("intervalIndex", intervalIndex)
            .put("toFailure", false)
            .put("drops", JSONArray())
            .put("clusters", JSONArray())
        if (weightKg != null) set.put("weightKg", weightKg)
        // Preserve the prescribed machine/distance unit in each actual WOD log.
        val quantityUnit = exercise.optString("quantityUnit")
        if (quantityUnit.isNotBlank()) set.put("quantityUnit", quantityUnit)
        exercise.getJSONArray("loggedSets").put(set)
        exercise.put("completedReps", exercise.optInt("completedReps") + quantity)
        session.put("phase", "counting")
        save(state)
        return summarize(session)
    }

    /** Update a confirmed WOD entry without changing its identity or timestamp. */
    @Synchronized fun reviseWodMovementSet(setId: String, quantity: Int, weightKg: Double?): ActiveWorkout {
        require(setId.isNotBlank() && quantity >= 0)
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0))
        val state = requireState()
        val session = requireActive(state)
        val items = session.getJSONArray("exercises")
        val current = items.getJSONObject(session.getInt("currentIndex"))
        val blockId = current.optString("blockId")
        check(current.optString("blockKind") == "wod")
        check(WodFormat.fromWire(current.optString("wodFormat"))?.capture == ResultCapture.PER_MOVEMENT_SETS)
        var found = false
        for (i in 0 until items.length()) {
            val item = items.getJSONObject(i)
            if (item.optString("blockId") != blockId) continue
            val logs = item.getJSONArray("loggedSets")
            for (j in 0 until logs.length()) {
                val set = logs.getJSONObject(j)
                if (set.optString("id") != setId) continue
                set.put("reps", quantity)
                if (weightKg == null) set.remove("weightKg") else set.put("weightKg", weightKg)
                item.put("completedReps", (0 until logs.length()).sumOf {
                    logs.getJSONObject(it).optInt("reps")
                })
                found = true
                break
            }
        }
        check(found) { "Registro WOD no encontrado en el bloque activo" }
        save(state)
        return summarize(session)
    }

    /** Undo one movement record, never remove a strength set or another WOD block. */
    @Synchronized fun deleteWodMovementSet(setId: String): ActiveWorkout {
        require(setId.isNotBlank())
        val state = requireState()
        val session = requireActive(state)
        val items = session.getJSONArray("exercises")
        val current = items.getJSONObject(session.getInt("currentIndex"))
        val blockId = current.optString("blockId")
        check(current.optString("blockKind") == "wod")
        check(WodFormat.fromWire(current.optString("wodFormat"))?.capture == ResultCapture.PER_MOVEMENT_SETS)
        var found = false
        for (i in 0 until items.length()) {
            val item = items.getJSONObject(i)
            if (item.optString("blockId") != blockId) continue
            val logs = item.getJSONArray("loggedSets")
            val kept = JSONArray()
            for (j in 0 until logs.length()) {
                val set = logs.getJSONObject(j)
                if (set.optString("id") == setId) found = true else kept.put(set)
            }
            if (kept.length() != logs.length()) {
                item.put("loggedSets", kept)
                item.put("completedReps", (0 until kept.length()).sumOf {
                    kept.getJSONObject(it).optInt("reps")
                })
            }
        }
        check(found) { "Registro WOD no encontrado en el bloque activo" }
        save(state)
        return summarize(session)
    }

    /** Finish a per-movement block without turning unrecorded movements into sets. */
    @Synchronized fun completeWodMovementBlock(): ActiveWorkout? {
        val state = requireState()
        val session = requireActive(state)
        val exercises = session.getJSONArray("exercises")
        val index = session.getInt("currentIndex")
        val current = exercises.getJSONObject(index)
        check(current.optString("blockKind") == "wod")
        val format = WodFormat.fromWire(current.getString("wodFormat"))
        check(format?.capture == ResultCapture.PER_MOVEMENT_SETS)
        val blockId = current.getString("blockId")
        val hasWork = (0 until exercises.length()).any { i ->
            val item = exercises.getJSONObject(i)
            item.optString("blockId") == blockId &&
                item.getJSONArray("loggedSets").length() > 0
        }
        check(hasWork) { "Registra al menos un movimiento antes de cerrar el bloque" }
        var nextIndex = index
        while (nextIndex < exercises.length() &&
            exercises.getJSONObject(nextIndex).optString("blockId") == blockId) {
            val item = exercises.getJSONObject(nextIndex)
            item.put("isCompleted", item.getJSONArray("loggedSets").length() > 0)
            nextIndex++
        }
        if (nextIndex == exercises.length()) {
            finishInPlace(state, session)
            return null
        }
        session.put("currentIndex", nextIndex).put("phase", "ready")
        save(state)
        return summarize(session)
    }

    /**
     * Nombre y descanso prescrito del ejercicio indicado (o el actual), para la
     * notificación de cuenta atrás tras registrar una serie. null si no hay
     * sesión activa, el índice no existe o no hay descanso configurado.
     */
    @Synchronized fun restInfoForExercise(exerciseIndex: Int? = null): Pair<String, Int>? {
        val state = loadOrNull() ?: return null
        val session = state.optJSONObject("activeSession") ?: return null
        val array = session.optJSONArray("exercises") ?: return null
        val index = exerciseIndex ?: session.optInt("currentIndex", -1)
        if (index !in 0 until array.length()) return null
        val exercise = array.getJSONObject(index)
        val rest = exercise.optInt("restSeconds", TrainingSettings.read(state).defaultRestSeconds)
        if (rest <= 0) return null
        val name = exercise.optJSONObject("exercise")?.optString("name")
            ?: return null
        return name to rest
    }

    /** Finish retries acknowledge an already archived matching ID without creating a session. */
    @Synchronized fun finishWearSession(sessionId:String):Boolean {
        require(sessionId.isNotBlank())
        val state=requireState()
        val archive=state.getJSONArray("workouts")
        if((0 until archive.length()).any {archive.getJSONObject(it).let {w ->w.optString("id")==sessionId && w.optString("phase")=="finished"}}) return true
        val active=state.optJSONObject("activeSession") ?: return false
        if(active.optString("id")!=sessionId) return false
        finishInPlace(state,active)
        return true
    }

    @Synchronized fun finish(): Unit {
        val state = requireState()
        finishInPlace(state, requireActive(state))
    }

    /**
     * Plan del día para el reloj: la primera rutina programada para hoy montada
     * como sesión (sin persistir). null si no hay rutina de hoy o hay sesión
     * activa. Equivale al todayPlan que el iPhone envía al Apple Watch.
     */
    @Synchronized fun todayPlanSession(today: LocalDate = LocalDate.now(),
        professional:List<BusinessCenterStore.ProfessionalSession> = emptyList()): JSONObject? {
        val state = loadOrNull() ?: return null
        if (!state.isNull("activeSession")) return null
        val routines = state.optJSONArray("routines") ?: JSONArray()
        val choices=(0 until routines.length()).map { routines.getJSONObject(it) }
        val rotationID=RotationSettings.nextRoutineId(state)
        val routine = if(TrainingSettings.read(state).scheduleMode=="rotation") choices.firstOrNull {it.optString("id")==rotationID}
        else choices.firstOrNull {it.optString("scheduledDate").take(10)==today.toString()} ?:
            choices.firstOrNull { routine ->
                val scheduled=routine.optString("scheduledDate").takeIf {it.isNotBlank() && it!="null"}
                scheduled==null && routine.optInt("weekday",-1)==today.dayOfWeek.value
            }
        val personal=routine?.let {runCatching {assembleSession(state,it)}.getOrNull()}
        if(personal?.optJSONArray("exercises")?.length()?.let {it>0}==true) return personal
        val assigned=professional.firstOrNull {it.scheduledDate==today.toString() && it.status=="scheduled" &&
            it.prescription?.optInt("schemaVersion")==1 && (it.prescription.optJSONArray("blocks")?.length() ?: 0)>0} ?: return null
        return try {projectProfessionalWatchPlan(state,assigned)} catch(_:org.json.JSONException) {null}
    }

    private fun projectProfessionalWatchPlan(state:JSONObject,assigned:BusinessCenterStore.ProfessionalSession):JSONObject? {
        // Apple professionalWorkoutForWatchToday: clone catalog for resolution,
        // no writes, no personal catalog/routine additions and no progression.
        val temporary=JSONObject(state.toString())
        val catalog=temporary.optJSONArray("exercises") ?: JSONArray().also {temporary.put("exercises",it)}
        val blocks=JSONArray()
        val source=assigned.prescription!!.getJSONArray("blocks")
        for(i in 0 until source.length()) {
            val prescribed=source.getJSONObject(i);val wod=prescribed.optString("kind")=="wod"
            val block=JSONObject().put("id",prescribed.getString("id")).put("title",prescribed.optString("title"))
                .put("kind",if(wod) "wod" else "strength").put("exercises",JSONArray()).put("movements",JSONArray())
            val format=dev.repera.domain.ProfessionalWodFormat.normalize(prescribed.optString("wodFormat"))
            if(format.isNotEmpty() && format!="null") block.put("wodFormat",format)
            listOf("rounds","timeCapMinutes").forEach {key -> if(prescribed.has(key) && !prescribed.isNull(key)) block.put(key,prescribed.get(key))}
            val entries=prescribed.optJSONArray(if(wod) "movements" else "exercises") ?: JSONArray()
            for(j in 0 until entries.length()) {
                val entry=entries.getJSONObject(j)
                val known=(0 until catalog.length()).map {catalog.getJSONObject(it)}
                val resolved=known.firstOrNull {it.optString("id")==entry.optString("catalogKey")} ?:
                    known.firstOrNull {dev.repera.domain.ExerciseEquivalence.sameName(it.optString("name"),entry.optString("name"))} ?:
                    JSONObject().put("id",UUID.randomUUID().toString()).put("name",entry.optString("name"))
                        .put("muscleGroup","Entrenador").put("isCustom",true).also {catalog.put(it)}
                val planned=entry.optJSONArray("plannedSets")?.let {JSONArray(it.toString())} ?: JSONArray()
                for(k in 0 until planned.length()) {val set=planned.getJSONObject(k);set.put("targetReps",set.optInt("targetReps").coerceAtLeast(0))}
                val item=JSONObject().put("id",entry.getString("id")).put("exerciseId",resolved.getString("id"))
                if(wod) {
                    item.put("name",resolved.getString("name"))
                    listOf("reps","notes").forEach {key -> if(entry.has(key) && !entry.isNull(key)) item.put(key,entry.get(key))}
                    if(planned.length()>0) item.put("explicitPlannedSets",planned)
                    block.getJSONArray("movements").put(item)
                } else {
                    if(planned.length()==0) planned.put(JSONObject().put("id",UUID.randomUUID().toString()).put("targetReps",entry.optInt("reps").coerceAtLeast(0)))
                    item.put("plannedSets",planned);block.getJSONArray("exercises").put(item)
                }
            }
            blocks.put(block)
        }
        val projected=JSONObject().put("id",assigned.id).put("title",assigned.title).put("blocks",blocks).put("progression","off")
        return runCatching {assembleSession(temporary,projected,allowAdvanced=false)}.getOrNull()
    }

    /**
     * Adopta una sesión iniciada en el reloj (ejecución autónoma offline):
     * idempotente por id; rechaza si hay otra sesión activa distinta.
     */
    @Synchronized fun adoptWearSession(sessionJson: JSONObject): Boolean {
        val id = sessionJson.optString("id")
        val exercises = sessionJson.optJSONArray("exercises")
        if (id.isBlank() || exercises == null || exercises.length() == 0) return false
        if (sessionJson.optInt("currentIndex") !in 0 until exercises.length()) return false
        val state = loadOrNull() ?: return false
        val archive=state.optJSONArray("workouts") ?: JSONArray()
        if((0 until archive.length()).any {archive.getJSONObject(it).optString("id")==id}) return false
        if(id in mirror.blockedIds()) return false
        val active = state.optJSONObject("activeSession")
        if (active != null) return active.optString("id") == id
        state.put("activeSession", JSONObject(sessionJson.toString()))
        save(state)
        return true
    }

    /**
     * Apply a wearable action idempotently. Reject mismatched sessions/indices and
     * preserve original set ID so a lost acknowledgement cannot duplicate the set.
     * Called only after the phone has a verified signed-in account.
     */
    @Synchronized fun logWearSet(
        sessionId: String, exerciseIndex: Int, setId: String, quantity: Int,
        weightKg: Double?, rir: Double? = null,
        durationSeconds: Int? = null, quantityUnit: String? = null,
        deficitCm: Int? = null, intervalIndex: Int? = null,
        sessionPayload: JSONObject? = null, warmup:Boolean=false,toFailure:Boolean=false,
        kind: String = "straight",
        drops: List<Pair<Int, Double?>> = emptyList(),
        clusters: List<Pair<Int, Int>> = emptyList(),
        onNewSet:(()->Unit)?=null
    ): Boolean {
        require(sessionId.isNotBlank() && setId.isNotBlank() && exerciseIndex >= 0)
        require(quantity > 0 && quantity <= 10000)
        val state = requireState()
        fun containsId(session: JSONObject): Boolean {
            if (session.optString("id") != sessionId) return false
            val exercises = session.optJSONArray("exercises") ?: return false
            return (0 until exercises.length()).any { i ->
                val logged = exercises.getJSONObject(i).optJSONArray("loggedSets") ?: JSONArray()
                (0 until logged.length()).any { n ->
                    logged.getJSONObject(n).optString("id") == setId
                }
            }
        }
        state.optJSONObject("activeSession")?.let {
            if (containsId(it)) return true
        }
        val history = state.optJSONArray("workouts") ?: JSONArray()
        if ((0 until history.length()).any { containsId(history.getJSONObject(it)) }) return true
        if (state.optJSONObject("activeSession")?.optString("id") != sessionId &&
            sessionPayload != null) {
            check(adoptWearSession(sessionPayload)) {
                "La sesión del reloj ya no es la activa"
            }
        }
        // adoptWearSession carga y guarda su propia copia del estado: si aquí
        // faltaba activeSession hay que releer, el `state` anterior no la tiene.
        val currentState =
            if (state.optJSONObject("activeSession") == null) requireState() else state
        val active = requireActive(currentState)
        check(active.optString("id") == sessionId) { "La sesión del reloj ya no es la activa" }
        val exercises = active.getJSONArray("exercises")
        val exercise = exercises.getJSONObject(exerciseIndex)
        if (exercise.optString("blockKind") == "wod") {
            // Apple 44713457: el reloj registra series por movimiento en
            // EMOM/Tabata/circuito (perMovementSets), una serie por intervalo
            // confirmado por el atleta; nunca se fabrica una serie.
            val blockId = exercise.getString("blockId")
            val current = exercises.getJSONObject(active.getInt("currentIndex"))
            check(current.optString("blockId") == blockId) {
                "El bloque activo ha cambiado"
            }
            check(!exercise.optBoolean("isCompleted")) {
                "El bloque WOD ya está cerrado"
            }
            val format = WodFormat.fromWire(exercise.getString("wodFormat"))
            check(format?.capture == ResultCapture.PER_MOVEMENT_SETS) {
                "Este formato WOD registra un resultado global en el móvil"
            }
            requireNotNull(intervalIndex) {
                "El reloj debe indicar el intervalo de la serie WOD"
            }
            var movementIndex = -1
            var seen = 0
            for (i in 0 until exercises.length()) {
                if (exercises.getJSONObject(i).optString("blockId") == blockId) {
                    if (i == exerciseIndex) { movementIndex = seen; break }
                    seen++
                }
            }
            check(movementIndex >= 0) { "Movimiento fuera del bloque" }
            recordWodMovement(movementIndex, intervalIndex, quantity, weightKg,
                setId = setId)
            runCatching {onNewSet?.invoke()} // Notification failure cannot undo a persisted set.
            return true
        }
        check(active.optInt("currentIndex") == exerciseIndex) {
            "El ejercicio activo ha cambiado"
        }
        check(!exercise.optBoolean("isCompleted")) {
            "El reloj solo puede registrar series de fuerza abiertas"
        }
        val effectiveKind = if (warmup) "straight" else kind
        when (effectiveKind) {
            "dropset" -> {
                check(!warmup) { "El calentamiento no admite dropset" }
                logDropSet(quantity, weightKg, drops, rir = rir, toFailure = toFailure, setId = setId)
            }
            "restpause" -> {
                check(!warmup) { "El calentamiento no admite rest-pause" }
                logRestPauseSet(clusters, weightKg, rir = rir, toFailure = toFailure, setId = setId)
            }
            else -> logCurrentSet(quantity, weightKg, rir = rir, warmup = warmup,
                toFailure = toFailure, setId = setId, quantityUnit = quantityUnit,
                durationSeconds = durationSeconds, deficitCm = deficitCm)
        }
        runCatching {onNewSet?.invoke()} // Notification failure cannot undo a persisted set.
        return true
    }

    /** Undo a saved strength set without changing the identity or timestamp of any other set. */
    @Synchronized fun deleteCurrentSet(setId: String): ActiveWorkout {
        val state = requireState()
        val session = requireActive(state)
        val exercise = session.getJSONArray("exercises").getJSONObject(session.getInt("currentIndex"))
        check(exercise.optString("blockKind") != "wod") { "Usa el editor WOD para estos movimientos" }
        val old = exercise.getJSONArray("loggedSets")
        val kept = JSONArray()
        var removed = false
        for (i in 0 until old.length()) {
            val entry = old.getJSONObject(i)
            if (entry.optString("id") == setId) {
                removed = true
            } else {
                kept.put(entry)
            }
        }
        check(removed) { "Serie no encontrada" }
        exercise.put("loggedSets", kept)
        val work = (0 until kept.length()).sumOf { n ->
            val set = kept.getJSONObject(n)
            if (set.optString("phase", "work") == "warmup") 0 else {
                set.optInt("reps") + (set.optJSONArray("drops")?.let { drops ->
                    (0 until drops.length()).sumOf { drops.getJSONObject(it).optInt("reps") }
                } ?: 0)
            }
        }
        exercise.put("completedReps", work)
        save(state)
        return summarize(session)
    }

    @Synchronized fun reviseCurrentSet(
        setId: String, quantity: Int, weightKg: Double?,
        quantityUnit: String? = null, durationSeconds: Int? = null,
        deficitCm: Int? = null
    ): ActiveWorkout {
        require(quantity >= 0 && (weightKg == null || (weightKg.isFinite() && weightKg >= 0)))
        require(durationSeconds == null || durationSeconds in 1..86400)
        require(deficitCm == null || deficitCm in 0..100)
        require(quantityUnit == null || quantityUnit in setOf("reps", "calories", "meters"))
        val state = requireState()
        val session = requireActive(state)
        val exercise = session.getJSONArray("exercises").getJSONObject(session.getInt("currentIndex"))
        val logged = exercise.getJSONArray("loggedSets")
        val index = (0 until logged.length()).firstOrNull {
            logged.getJSONObject(it).optString("id") == setId
        } ?: error("Serie no encontrada")
        val movement = exercise.getJSONObject("exercise")
        check(supportsSimpleInput(movement)) { "Este editor no admite el tipo de movimiento" }
        check(inputMode(movement).showsWeight || weightKg == null) { "Este ejercicio no registra peso" }
        check(deficitCm == null || inputMode(movement) == ExerciseInputMode.HSPU_DEFICIT)
        val original = logged.getJSONObject(index)
        original.put("reps", quantity)
        if (weightKg == null) original.remove("weightKg") else original.put("weightKg", weightKg)
        if (deficitCm == null) original.remove("deficitCm") else original.put("deficitCm", deficitCm)
        if (quantityUnit != null) {
            if(ExerciseInput.supportsRepsOrMeters(movement.getString("name"))) {
                check(quantityUnit in setOf("reps","meters"))
            } else if (inputMode(movement) == ExerciseInputMode.LOAD_DISTANCE) {
                check(quantityUnit == "meters" || ExerciseInput.supportsRepsOrMeters(
                    movement.getString("name")) && quantityUnit == "reps")
            } else if (inputMode(movement) == ExerciseInputMode.MACHINE_WORK) {
                check(quantityUnit in setOf("calories", "meters"))
                check(ExerciseInput.supportsCaloriesAndMeters(
                    movement.getString("name"), movement.optString("equipment")) ||
                    quantityUnit == ExerciseInput.defaultQuantityUnit(
                        movement.getString("name"), movement.optString("equipment")))
            } else check(quantityUnit == "reps")
            original.put("quantityUnit", quantityUnit)
        }
        if (durationSeconds != null) original.put("durationSeconds", durationSeconds)
        else if (inputMode(movement) in setOf(
                ExerciseInputMode.MACHINE_WORK, ExerciseInputMode.REPS_AND_TIME
            )) original.remove("durationSeconds")
        // Recompute only work sets, preserving each existing identity and completedAt.
        val total = (0 until logged.length()).sumOf { i ->
            val set = logged.getJSONObject(i)
            if (set.optString("phase") == "warmup") 0 else
                set.optInt("reps") + (set.optJSONArray("drops")?.let { drops ->
                    (0 until drops.length()).sumOf { drops.getJSONObject(it).optInt("reps") }
                } ?: 0)
        }
        exercise.put("completedReps", total)
        save(state)
        return summarize(session)
    }

    /** Espejo de ReperaStore.deleteRoutine: elimina la plantilla y su
     *  presencia en la rotación; los entrenos ya registrados no se tocan. */
    /** Política de progresión de la rutina (Routine.progression de iOS). */
    @Synchronized fun setRoutineProgression(id: String, policyWire: String) {
        require(dev.repera.domain.ProgressionPolicy.fromWire(policyWire) != null) {
            "Política de progresión desconocida"
        }
        val state = requireState()
        val routines = state.getJSONArray("routines")
        val routine = (0 until routines.length())
            .map { routines.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id } ?: error("Rutina no encontrada")
        routine.put("progression", policyWire)
        save(state)
    }

    /** Marca o desmarca una rutina como favorita (paridad setRoutineFavorite iOS). */
    @Synchronized fun setRoutineFavorite(id: String, favorite: Boolean) {
        val state = requireState()
        val routines = state.getJSONArray("routines")
        val routine = (0 until routines.length())
            .map { routines.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id } ?: error("Rutina no encontrada")
        routine.put("isFavorite", favorite)
        save(state)
    }

    /** El favorito de un entreno completado se mantiene tras cerrar y reabrir
     *  el detalle (paridad isWorkoutFavorite iOS, c5aae1cc). */
    @Synchronized fun isWorkoutFavorite(id: String): Boolean {
        val state = loadOrNull() ?: return false
        return WorkoutFavoriteSupport.isWorkoutFavorite(state, id)
    }

    /** Marca o desmarca entrenos registrados sin modificar la programación
     *  original (paridad toggleWorkoutFavorite iOS, c5aae1cc + sport favorites).
     *  [canSaveFavorite] recibe el conteo actual (rutinas ★ + actividades) al
     *  crear un favorito nuevo; quitar siempre está permitido. */
    @Synchronized fun toggleWorkoutFavorite(
        id: String,
        canSaveFavorite: (Int) -> Boolean = { true }
    ): Boolean {
        val state = loadOrNull() ?: return false
        val count = WorkoutFavoriteSupport.favoriteCount(state)
        val allowNew = canSaveFavorite(count)
        if (!WorkoutFavoriteSupport.toggleWorkoutFavorite(state, id, allowNewFavorite = allowNew)) {
            return false
        }
        save(state)
        return true
    }

    /** Actividades Comenzar marcadas ★ (paridad favoriteSportActivities). */
    @Synchronized fun favoriteSportActivities(): List<FavoriteSportActivity> {
        val state = loadOrNull() ?: return emptyList()
        return WorkoutFavoriteSupport.listFavoriteSportActivities(state)
    }

    @Synchronized fun removeFavoriteSportActivity(id: String): Boolean {
        val state = loadOrNull() ?: return false
        if (!WorkoutFavoriteSupport.removeFavoriteSportActivity(state, id)) return false
        save(state)
        return true
    }

    /** Marca o desmarca un ejercicio como favorito (paridad LibraryView iOS). */
    @Synchronized fun setExerciseFavorite(id: String, favorite: Boolean) {
        val state = requireState()
        val exercises = state.getJSONArray("exercises")
        val exercise = (0 until exercises.length())
            .map { exercises.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id } ?: error("Ejercicio no encontrado")
        exercise.put("isFavorite", favorite)
        save(state)
    }

    @Synchronized fun deleteRoutine(id: String) {
        val state = requireState()
        val routines = state.getJSONArray("routines")
        val index = (0 until routines.length()).firstOrNull {
            routines.getJSONObject(it).optString("id") == id
        } ?: error("Rutina no encontrada")
        routines.remove(index)
        state.optJSONObject("rotation")?.let { rotation ->
            val ids = rotation.optJSONArray("routineIds")
            if (ids != null) {
                val kept = JSONArray()
                for (i in 0 until ids.length()) {
                    if (ids.optString(i) != id) kept.put(ids.get(i))
                }
                if (kept.length() == 0) state.remove("rotation")
                else rotation.put("routineIds", kept)
            }
        }
        save(state)
    }

    /** Renombra y/o reprograma una rutina existente conservando sus bloques. */
    @Synchronized fun updateRoutineDetails(
        id: String,
        title: String,
        schedule: RoutineSchedule
    ) {
        val cleaned = title.trim()
        require(cleaned.isNotBlank()) { "Escribe un título válido" }
        require(schedule.scheduledDate == null || schedule.weekday == null) {
            "Un entreno no puede ser semanal y de fecha concreta a la vez"
        }
        require(schedule.weekday == null || schedule.weekday in 1..7)
        require(schedule.timeMinutes == null || schedule.timeMinutes in 0..1439)
        val state = requireState()
        val routines = state.getJSONArray("routines")
        val routine = (0 until routines.length())
            .map { routines.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id } ?: error("Rutina no encontrada")
        routine.put("title", cleaned)
        routine.remove("scheduledDate")
        routine.remove("weekday")
        routine.remove("scheduledTimeMinutes")
        val scheduledDay = schedule.scheduledDate?.let { LocalDate.parse(it) }
        if (scheduledDay != null) {
            routine.put("scheduledDate", scheduledDay.toString())
        } else if (schedule.weekday != null) {
            routine.put("weekday", schedule.weekday)
        }
        if (schedule.timeMinutes != null)
            routine.put("scheduledTimeMinutes", schedule.timeMinutes)
        schedule.weekday?.let { WeeklyScheduleActions.makeWeekdayExclusive(state,id,it) }
        save(state)
    }

    /**
     * Edita una serie registrada de un entreno TERMINADO. Las series
     * registradas son la fuente de verdad (principio CompletedWorkoutEditing
     * de iOS): solo se corrigen cantidades, nunca se convierten objetivos
     * pendientes en trabajo realizado.
     */
    @Synchronized fun reviseFinishedSet(
        workoutId: String, entryId: String, setId: String,
        quantity: Int, weightKg: Double?,
        durationSeconds: Int? = null
    ) {
        require(quantity >= 0 && (weightKg == null || (weightKg.isFinite() && weightKg >= 0)))
        require(durationSeconds == null || durationSeconds in 1..86400)
        val state = requireState()
        val workout = findWorkout(state, workoutId)
        val exercise = findSessionExercise(workout, entryId)
        val logged = exercise.optJSONArray("loggedSets") ?: error("Serie no encontrada")
        val index = (0 until logged.length()).firstOrNull {
            logged.getJSONObject(it).optString("id") == setId
        } ?: error("Serie no encontrada")
        val movement = exercise.getJSONObject("exercise")
        check(supportsSimpleInput(movement)) { "Este editor no admite el tipo de movimiento" }
        check(inputMode(movement).showsWeight || weightKg == null) {
            "Este ejercicio no registra peso"
        }
        val original = logged.getJSONObject(index)
        original.put("reps", quantity)
        if (weightKg == null) original.remove("weightKg") else original.put("weightKg", weightKg)
        if (durationSeconds != null) original.put("durationSeconds", durationSeconds)
        else if (inputMode(movement) in setOf(
                ExerciseInputMode.MACHINE_WORK, ExerciseInputMode.REPS_AND_TIME
            )) original.remove("durationSeconds")
        recomputeCompletedReps(exercise)
        save(state)
    }

    // --- Cambios propuestos por la IA (AIChangeRequestStore) ---

    /** Parche de una serie propuesto por la IA y consentido por el deportista. */
    data class AISetPatch(
        val exerciseEntryId: String,
        val loggedSetId: String,
        val reps: Int? = null,
        val weightKg: Double? = null,
        val rir: Double? = null,
        val clearWeight: Boolean = false,
        val clearRir: Boolean = false
    )

    /** Entrenos terminados (copia) para validar el objetivo de un cambio IA. */
    /**
     * Port de ReperaStore.mergeRecoveredWorkoutsFromSupabase (iOS): incorpora
     * entrenos terminados recuperados del espejo Supabase que este
     * dispositivo no conoce (segundo dispositivo). Sólo IDs nuevos con
     * finishedAt; ordena por finishedAt/startedAt descendente.
     */
    data class CSVImportSummary(
        val source: String,
        val workouts: Int,
        val matchedSets: Int,
        val createdExercises: Int,
        val skippedRows: Int
    ) {
        val label: String
            get() = "$source: $workouts entrenos, $matchedSets series" +
                (if (createdExercises > 0) ", $createdExercises ejercicios nuevos"
                else "")
    }

    /**
     * Importa un histórico CSV de Strong/Hevy (port de ReperaStore.importCSV
     * + WorkoutCSVImporter.swift): crea ejercicios libres para los nombres no
     * reconocidos y añade los entrenos como sesiones terminadas.
     */
    @Synchronized fun importCSV(text: String): CSVImportSummary {
        val state = requireState()
        val catalog = state.getJSONArray("exercises")
        val existing = (0 until catalog.length()).map {
            val e = catalog.getJSONObject(it)
            e.getString("id") to e.optString("name")
        }
        val result = dev.repera.domain.WorkoutCSVImporter.parse(text, existing)
        for (exercise in result.createdExercises) {
            catalog.put(JSONObject()
                .put("id", exercise.id)
                .put("name", exercise.name)
                .put("muscleGroup", exercise.muscleGroup)
                .put("isCustom", true)
                .put("secondaryMuscles", JSONArray())
                .put("instructions", JSONArray())
                .put("primaryRegions", JSONArray())
                .put("secondaryRegions", JSONArray())
                .put("isFavorite", false))
        }
        val byId = (0 until catalog.length()).associate {
            val e = catalog.getJSONObject(it)
            e.getString("id") to e
        }
        val workouts = state.getJSONArray("workouts")
        for (workout in result.workouts) {
            val whenIso = java.time.Instant.ofEpochSecond(
                workout.epochSeconds).toString()
            val entries = JSONArray()
            for (item in workout.exercises) {
                val movement = byId[item.exercise.id] ?: continue
                val sets = JSONArray()
                for (set in item.sets) {
                    val row = JSONObject()
                        .put("id", UUID.randomUUID().toString())
                        .put("reps", set.reps)
                        .put("completedAt", java.time.Instant.ofEpochSecond(
                            set.epochSeconds).toString())
                        .put("phase", "work")
                        .put("toFailure", false)
                        .put("quantityUnit", "reps")
                    set.weightKg?.let { row.put("weightKg", it) }
                    sets.put(row)
                }
                entries.put(JSONObject()
                    .put("id", UUID.randomUUID().toString())
                    .put("exercise", JSONObject(movement.toString()))
                    .put("plannedSets", JSONArray())
                    .put("loggedSets", sets)
                    .put("completedReps", item.sets.sumOf { it.reps })
                    .put("isCompleted", true))
            }
            workouts.put(JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("title", workout.title)
                .put("startedAt", whenIso)
                .put("finishedAt", whenIso)
                .put("phase", "finished")
                .put("exercises", entries))
        }
        save(state)
        return CSVImportSummary(
            source = result.source.name.lowercase(),
            workouts = result.workouts.size,
            matchedSets = result.matchedSets,
            createdExercises = result.createdExercises.size,
            skippedRows = result.skippedRows)
    }

    @Synchronized fun mergeRecoveredWorkoutsFromSupabase(
        recovered: List<JSONObject>): Int {
        if (recovered.isEmpty()) return 0
        val state = requireState()
        val archive = state.optJSONArray("workouts")
            ?: JSONArray().also { state.put("workouts", it) }
        val known = (0 until archive.length())
            .map { archive.getJSONObject(it).optString("id") }.toMutableSet()
        var imported = 0
        for (session in recovered) {
            if(session.optString("id") in mirror.blockedIds()) continue
            if (session.isNull("finishedAt")) continue
            if (!known.add(session.optString("id"))) continue
            archive.put(JSONObject(session.toString()))
            imported += 1
        }
        if (imported > 0) {
            val sorted = (0 until archive.length())
                .map { archive.getJSONObject(it) }
                .sortedByDescending {
                    it.optString("finishedAt").ifBlank {
                        it.optString("startedAt") } }
            state.put("workouts", JSONArray().also { out ->
                sorted.forEach { out.put(it) } })
            save(state)
        }
        return imported
    }

    /** Registra la procedencia de entrenos recuperados del espejo (ver MirrorRecoveryReconciler). */
    fun recordMirrorRecovered(entries: Map<String, String>) = local.addMirrorProvenance(entries)

    @Synchronized fun finishedWorkoutsSnapshot(): List<JSONObject> {
        val state = requireState()
        val archive = state.optJSONArray("workouts") ?: JSONArray()
        return (0 until archive.length())
            .map { archive.getJSONObject(it) }
            .filter { !it.isNull("finishedAt") }
            .map { JSONObject(it.toString()) }
    }

    /**
     * Aplica un cambio IA consentido (port del update_workout de
     * AIChangeRequestStore.decide): título + parches de series. Las series
     * drop/rest-pause no se tocan si el parche cambia reps (igual que iOS).
     */
    @Synchronized fun applyAIWorkoutPatch(
        workoutId: String, title: String?, setChanges: List<AISetPatch>,
        expectedLocalDigest:String?=null
    ) {
        val state = requireState()
        val workout = findWorkout(state, workoutId)
        check(expectedLocalDigest==null || WorkoutMirrorStore.canonicalDigest(workout)==expectedLocalDigest) {
            "El entrenamiento local cambió mientras se revisaba la propuesta IA"
        }
        if (title != null) workout.put("title", title)
        for (patch in setChanges) {
            val exercise = findSessionExercise(workout, patch.exerciseEntryId)
            val logged = exercise.optJSONArray("loggedSets")
                ?: error("Una serie ya no coincide con el entrenamiento actual.")
            val index = (0 until logged.length()).firstOrNull {
                logged.getJSONObject(it).optString("id") == patch.loggedSetId
            } ?: error("Una serie ya no coincide con el entrenamiento actual.")
            val set = logged.getJSONObject(index)
            if (patch.reps != null) {
                val drops = set.optJSONArray("drops")
                val clusters = set.optJSONArray("clusters")
                check((drops == null || drops.length() == 0) &&
                    (clusters == null || clusters.length() == 0)) {
                    "Las series drop/rest-pause deben editarse manualmente."
                }
                set.put("reps", patch.reps)
            }
            if (patch.weightKg != null) set.put("weightKg", patch.weightKg)
            if (patch.clearWeight) set.remove("weightKg")
            if (patch.rir != null) {
                set.put("rir", patch.rir)
                set.put("toFailure", false)
            }
            if (patch.clearRir) {
                set.remove("rir")
                set.put("toFailure", false)
            }
        }
        val exercises = workout.optJSONArray("exercises")
        if (exercises != null) {
            for (i in 0 until exercises.length()) {
                recomputeCompletedReps(exercises.getJSONObject(i))
            }
        }
        save(state)
    }

    /** Elimina un entreno registrado (solo tras consentimiento explícito). */
    @Synchronized fun deleteWorkout(id: String,expectedLocalDigest:String?=null) {
        // Tombstone ANTES de borrar (paridad ReperaStore.deleteWorkout iOS): el
        // espejo no debe resucitar el registro en el próximo sync.
        val state = requireState()
        val archive = state.getJSONArray("workouts")
        val index = (0 until archive.length()).firstOrNull {
            archive.getJSONObject(it).optString("id") == id
        } ?: error("Entreno no encontrado")
        check(expectedLocalDigest==null || WorkoutMirrorStore.canonicalDigest(archive.getJSONObject(index))==expectedLocalDigest) {
            "El entrenamiento local cambió mientras se revisaba la propuesta IA"
        }
        check(stillAuthorized()) {"La cuenta cambió antes de borrar el entrenamiento"}
        mirror.noteDeleted(id)
        archive.remove(index)
        save(state)
    }

    /**
     * INTERNO, SIN UI, SIN USO EN PRODUCCION. Sustituye al prototipo anterior (tombstones antes de guardar, inseguro).
     * Usa el diario ResetCoordinator con puertos reales: intencion -> save CAS -> tombstones -> borrar intencion.
     * No es una implementacion utilizable de "Borrar todo": faltan epoca global, otras instalaciones, reloj y decisiones de producto
     * (ver android/docs/RESET_USER_DATA_CONTRACT.md).
     */
    internal fun resetUserDataJournaledForTests(resetId: String): ResetCoordinator.Outcome =
        ResetCoordinator(resetPorts()).reset(resetId)

    /** Ids bloqueados en el almacen de tombstones de ESTE repositorio (clave = id de cuenta Google; ver doc de reset). */
    fun mirrorBlockedIds(): Set<String> = mirror.blockedIds()

    /** Reconciliacion idempotente tras un corte; la llama el sync del espejo antes de usar tombstones. */
    fun recoverPendingReset(): ResetCoordinator.Recovery = ResetCoordinator(resetPorts()).recover()

    private fun resetPorts() = object : ResetPorts {
        override fun loadIntent() = mirror.loadResetIntent()
        override fun storeIntent(json: String) = mirror.storeResetIntent(json)
        override fun clearIntent() = mirror.clearResetIntent()
        override fun readState(): JSONObject? = loadOrNull()
        override fun saveState(state: JSONObject): Boolean = try { save(state); true } catch (e: IllegalStateException) { false }
        override fun noteDeleted(id: String) = mirror.noteDeleted(id)
    }

    /** Ejercicios personalizados actuales (copia) para el espejo IA. */
    @Synchronized fun customExercisesSnapshot(): List<JSONObject> {
        val state = requireState()
        val catalog = state.optJSONArray("exercises") ?: JSONArray()
        return (0 until catalog.length())
            .map { catalog.getJSONObject(it) }
            .filter { it.optBoolean("isCustom") }
            .map { JSONObject(it.toString()) }
    }

    /** Crea ejercicio personalizado con id fijado (la IA propone, el
     * deportista consiente). Devuelve false si el id ya existe. */
    @Synchronized fun addCustomExercise(
        id: String, name: String, muscleGroup: String,
        equipment: String? = null, targetMuscle: String? = null,
        secondaryMuscles: List<String> = emptyList()
    ): Boolean {
        val state = requireState()
        val catalog = state.getJSONArray("exercises")
        for (i in 0 until catalog.length()) {
            if (catalog.getJSONObject(i).optString("id") == id) return false
        }
        catalog.put(JSONObject()
            .put("id", id)
            .put("name", name)
            .put("muscleGroup", muscleGroup)
            .put("equipment", equipment ?: JSONObject.NULL)
            .put("targetMuscle", targetMuscle ?: "")
            .put("secondaryMuscles", JSONArray(secondaryMuscles))
            .put("isCustom", true))
        save(state)
        return true
    }

    /** Edita un ejercicio personalizado; false si no existe o no es custom. */
    @Synchronized fun updateCustomExercise(
        id: String, name: String, muscleGroup: String,
        equipment: String? = null, targetMuscle: String? = null,
        secondaryMuscles: List<String> = emptyList()
    ): Boolean {
        val state = requireState()
        val catalog = state.getJSONArray("exercises")
        for (i in 0 until catalog.length()) {
            val exercise = catalog.getJSONObject(i)
            if (exercise.optString("id") != id) continue
            if (!exercise.optBoolean("isCustom")) return false
            exercise.put("name", name)
            exercise.put("muscleGroup", muscleGroup)
            exercise.put("equipment", equipment ?: JSONObject.NULL)
            exercise.put("targetMuscle", targetMuscle ?: "")
            exercise.put("secondaryMuscles", JSONArray(secondaryMuscles))
            save(state)
            return true
        }
        return false
    }

    /** Elimina un ejercicio personalizado; false si no existe o no es custom. */
    @Synchronized fun deleteCustomExercise(id: String): Boolean {
        val state = requireState()
        val catalog = state.getJSONArray("exercises")
        for (i in 0 until catalog.length()) {
            val exercise = catalog.getJSONObject(i)
            if (exercise.optString("id") != id) continue
            if (!exercise.optBoolean("isCustom")) return false
            catalog.remove(i)
            save(state)
            return true
        }
        return false
    }

    /** Borra una serie registrada de un entreno terminado, sin tocar el resto. */
    @Synchronized fun deleteFinishedSet(workoutId: String, entryId: String, setId: String) {
        val state = requireState()
        val workout = findWorkout(state, workoutId)
        val exercise = findSessionExercise(workout, entryId)
        val logged = exercise.optJSONArray("loggedSets") ?: error("Serie no encontrada")
        val index = (0 until logged.length()).firstOrNull {
            logged.getJSONObject(it).optString("id") == setId
        } ?: error("Serie no encontrada")
        logged.remove(index)
        recomputeCompletedReps(exercise)
        if (logged.length() == 0) exercise.put("isCompleted", false)
        save(state)
    }

    private fun findWorkout(state: JSONObject, workoutId: String): JSONObject {
        val archive = state.getJSONArray("workouts")
        return (0 until archive.length())
            .map { archive.getJSONObject(it) }
            .firstOrNull { it.optString("id") == workoutId }
            ?: error("Entreno no encontrado")
    }

    private fun findSessionExercise(workout: JSONObject, entryId: String): JSONObject {
        val exercises = workout.optJSONArray("exercises") ?: error("Ejercicio no encontrado")
        return (0 until exercises.length())
            .map { exercises.getJSONObject(it) }
            .firstOrNull { it.optString("id") == entryId }
            ?: error("Ejercicio no encontrado")
    }

    private fun recomputeCompletedReps(exercise: JSONObject) {
        val logged = exercise.optJSONArray("loggedSets") ?: return
        val total = (0 until logged.length()).sumOf { i ->
            val set = logged.getJSONObject(i)
            if (set.optString("phase") == "warmup") 0 else
                set.optInt("reps") + (set.optJSONArray("drops")?.let { drops ->
                    (0 until drops.length()).sumOf { drops.getJSONObject(it).optInt("reps") }
                } ?: 0)
        }
        exercise.put("completedReps", total)
    }

    /** Descartar la sesión activa SIN guardarla (endActiveSession(save: false)
     *  iOS): se borra la sesión en curso y no aparece en el historial. */
    @Synchronized fun discardActiveSession(): Boolean {
        val state = loadOrNull() ?: return false
        if (state.isNull("activeSession")) return false
        state.remove("activeSession")
        save(state)
        return true
    }

    /** Pin de inicio (gym/sitio) sobre la sesión ACTIVA (capturePin iOS). */
    @Synchronized fun attachLocationPin(sessionId: String, pin: dev.repera.domain.WorkoutLocationPin) {
        val state = loadOrNull() ?: return
        val session = state.optJSONObject("activeSession") ?: return
        if (session.optString("id") != sessionId) return
        session.put("locationPin", JSONObject()
            .put("latitude", pin.latitude)
            .put("longitude", pin.longitude)
            .put("recordedAtEpochMs", pin.recordedAtEpochMs)
            .apply {
                pin.name?.let { put("name", it) }
                pin.mapItemIdentifier?.let { put("mapItemIdentifier", it) }
                pin.pointOfInterestCategory?.let { put("pointOfInterestCategory", it) }
            })
        save(state)
    }

    /** Cambia o borra el pin de la sesión ACTIVA desde el selector de lugar
     *  (activeLocationPin set iOS). pin == null lo elimina. */
    @Synchronized fun setActiveLocationPin(sessionId: String, pin: dev.repera.domain.WorkoutLocationPin?) {
        if (pin != null) { attachLocationPin(sessionId, pin); return }
        val state = loadOrNull() ?: return
        val session = state.optJSONObject("activeSession") ?: return
        if (session.optString("id") != sessionId) return
        session.remove("locationPin")
        save(state)
    }

    /** Pin crudo de la sesión activa (lectura para verificación de tests). */
    @Synchronized internal fun activeSessionLocationPinForTest(): JSONObject? =
        loadOrNull()?.optJSONObject("activeSession")?.optJSONObject("locationPin")

    /** Edición de un entreno archivado desde el borrador del editor
     *  (HistoryView/DayEditorView iOS + ReperaStore.saveWorkout). Se aplica
     *  SOLO al confirmar. Reglas iOS: fin < inicio => fin = inicio + 60 s; la
     *  valoración se recalcula (no se borra); el pin solo se escribe si el
     *  entreno no tiene ruta (>= 2 puntos). Notas y demás datos se conservan.
     *  No crea ni borra entrenos (cuota/tombstones intactos). false si no existe. */
    data class FinishedWorkoutEdit(
        val title: String,
        val startedAtIso: String?,
        val finishedAtIso: String?,
        val notes: String?,
        val pinEdited: Boolean,
        val pin: dev.repera.domain.WorkoutLocationPin?,
        /** Bloques editados (JSON, con ids) del editor de contenido; null = contenido intacto. */
        val blocksJson: String? = null,
        /** «Favorito» de DayEditorView al editar un entreno terminado: copia independiente (ids nuevos), nunca la misma rutina. */
        val saveAsFavorite: Boolean = false,
        /** Ediciones de la marca WOD completada (Apple changingScore), reproducidas en orden tras el contenido. */
        val scoreEdits: List<ScoreEdit> = emptyList()
    )
    data class ScoreEdit(val blockId: String, val field: CompletedWorkoutEditing.ScoreField, val value: Int)

    /**
     * [canCreateCustom] recibe el nº de ejercicios personalizados existentes y decide si se puede
     * crear uno más (cuota). Si se deniega, lanza ANTES de tocar nada: no se guarda ni se crea nada.
     */
    @Synchronized fun updateFinishedWorkout(
        workoutId: String, edit: FinishedWorkoutEdit,
        canSaveFavorite:(Int)->Boolean = {true},
        canCreateCustom: (Int) -> Boolean = { true }
    ): Boolean {
        val state = loadOrNull() ?: return false
        val archive = state.optJSONArray("workouts") ?: return false
        val target = (0 until archive.length()).map { archive.getJSONObject(it) }
            .firstOrNull { it.optString("id") == workoutId } ?: return false
        if(edit.saveAsFavorite) requireTemplateSlot(state,RoutineSchedule(),canSaveFavorite)
        val start = edit.startedAtIso?.let { runCatching { java.time.Instant.parse(it) }.getOrNull() }
        var end = edit.finishedAtIso?.let { runCatching { java.time.Instant.parse(it) }.getOrNull() }
        if (start != null && end != null && end.isBefore(start)) end = start.plusSeconds(60)
        val cleanTitle = edit.title.trim().ifEmpty { "Entreno" }
        if (edit.blocksJson != null) {
            // Contenido (CompletedWorkoutEditing.applying): validado ANTES de tocar nada.
            val catalogArr = state.getJSONArray("exercises")
            val draftBlocks = JSONArray(edit.blocksJson)
            val idByName = mutableMapOf<String, String>()
            // Identidad por nombre normalizado (sin mayúsculas ni diacríticos), como la búsqueda de catálogo.
            val byNorm = mutableMapOf<String, String>()
            for (i in 0 until catalogArr.length()) catalogArr.getJSONObject(i).let {
                byNorm.putIfAbsent(foldForSearch(it.optString("name")), it.getString("id")) }
            val pendingNames = EditorBlockOps.pendingCustomNames(draftBlocks)
            val toCreate = pendingNames.map { foldForSearch(it) }.distinct().filter { it !in byNorm }
            // Capacidad del LOTE completo antes de crear nada: el último nuevo debe caber.
            val customsNow = (0 until catalogArr.length()).count { catalogArr.getJSONObject(it).optBoolean("isCustom") }
            if (toCreate.isNotEmpty())
                check(canCreateCustom(customsNow + toCreate.size - 1)) { "Límite de ejercicios personalizados alcanzado" }
            for (name in pendingNames) {
                val norm = foldForSearch(name)
                byNorm[norm]?.let { idByName[name] = it; continue }
                val newId = UUID.randomUUID().toString()
                catalogArr.put(JSONObject().put("id", newId).put("name", name.trim()).put("muscleGroup", "Otros")
                    .put("equipment", JSONObject.NULL).put("targetMuscle", "")
                    .put("secondaryMuscles", JSONArray()).put("isCustom", true))
                byNorm[norm] = newId; idByName[name] = newId
            }
            val applied = CompletedWorkoutEditing.applying(
                cleanTitle, EditorBlockOps.resolvePending(draftBlocks, idByName), target, catalogArr)
            for (key in listOf("exercises", "routineBlocks", "wodResults", "currentIndex"))
                target.put(key, applied.get(key))
        }
        if (edit.scoreEdits.isNotEmpty()) {
            val blocksNow = CompletedWorkoutEditing.blocksFrom(target, null)
            var working: JSONObject = target
            for (e in edit.scoreEdits) {
                val b = (0 until blocksNow.length()).map { blocksNow.getJSONObject(it) }.firstOrNull { it.optString("id") == e.blockId } ?: continue
                working = CompletedWorkoutEditing.changingScore(working, b, e.field, e.value)
            }
            target.put("wodResults", working.optJSONArray("wodResults") ?: JSONArray())
        }
        target.put("title", cleanTitle)
        if (start != null) target.put("startedAt", start.toString())
        if (end != null) target.put("finishedAt", end.toString())
        val notes = edit.notes?.trim().orEmpty()
        if (notes.isEmpty()) target.remove("notes") else target.put("notes", notes)
        // ReperaStore.saveWorkout iOS (phase == finished): sin vínculo con Salud no
        // hay kcal verificadas; la duración es fin - inicio (mín. 60 s); y la
        // valoración se RECALCULA con el historial (attachSessionReview), nunca
        // se borra por extensión: solo desaparece si el motor devuelve null.
        if (target.isNull("healthKitWorkoutUUID") || target.optString("healthKitWorkoutUUID").isEmpty()) {
            target.remove("appleActiveEnergyKcal")
        }
        val s2 = start ?: runCatching { java.time.Instant.parse(target.optString("startedAt")) }.getOrNull()
        val e2 = end ?: runCatching { java.time.Instant.parse(target.optString("finishedAt")) }.getOrNull()
        // ReperaStore.saveWorkout iOS: con vínculo Salud o captura En vivo se preserva la medición.
        if (s2 != null && e2 != null && FinishedSessionDuration.shouldDeriveFromSchedule(target)) {
            target.put("appleDurationSeconds", maxOf(60.0, (e2.toEpochMilli() - s2.toEpochMilli()) / 1000.0))
        }
        SessionReviewSupport.attachToFinishedSession(state, target)
        val hasRoute = (target.optJSONArray("routePoints")?.length() ?: 0) >= 2
        if (edit.pinEdited && !hasRoute) {
            val pin = edit.pin
            if (pin == null) target.remove("locationPin") else target.put("locationPin", JSONObject()
                .put("latitude", pin.latitude)
                .put("longitude", pin.longitude)
                .put("recordedAtEpochMs", pin.recordedAtEpochMs)
                .apply {
                    pin.name?.let { put("name", it) }
                    pin.mapItemIdentifier?.let { put("mapItemIdentifier", it) }
                    pin.pointOfInterestCategory?.let { put("pointOfInterestCategory", it) }
                })
        }
        if (edit.saveAsFavorite) {
            // routineForEditing de Apple: la rutina guardada si existe; si no, se
            // reconstruye desde la sesión (p. ej. quick log sin routineBlocks).
            val src = CompletedWorkoutEditing.blocksFrom(target, null)
            val copy = JSONArray()
            for (k in 0 until src.length())
                EditorBlockOps.freshIds(src.getJSONObject(k).toString())?.let { copy.put(JSONObject(it)) }
            if (copy.length() > 0) state.getJSONArray("routines").put(JSONObject()
                .put("id", UUID.randomUUID().toString()).put("title", cleanTitle).put("blocks", copy)
                .put("progression", "off").put("isFavorite", true))
        }
        save(state)
        return true
    }

    /** Ruta GPS al terminar (stopRouteTracking iOS): vale con la sesión aún
     *  activa o ya archivada en el historial. */
    @Synchronized fun attachRoutePoints(sessionId: String, points: List<dev.repera.domain.WorkoutRoutePoint>) {
        val state = loadOrNull() ?: return
        val active = state.optJSONObject("activeSession")
            ?.takeIf { it.optString("id") == sessionId }
        val target = active ?: run {
            val archive = state.optJSONArray("workouts") ?: return
            (0 until archive.length()).map { archive.getJSONObject(it) }
                .firstOrNull { it.optString("id") == sessionId } ?: return
        }
        val array = JSONArray()
        for (point in points) {
            array.put(JSONObject()
                .put("id", point.id)
                .put("latitude", point.latitude)
                .put("longitude", point.longitude)
                .put("recordedAtEpochMs", point.recordedAtEpochMs)
                .apply {
                    point.speedMps?.let { put("speedMps", it) }
                    point.altitudeMeters?.let { put("altitudeMeters", it) }
                    point.horizontalAccuracyMeters?.let { put("horizontalAccuracyMeters", it) }
                    point.verticalAccuracyMeters?.let { put("verticalAccuracyMeters", it) }
                    point.isEstimated?.let { put("isEstimated", it) }
                })
        }
        target.put("routePoints", array)
        save(state)
    }

    /** Datos de la sesión activa para la heurística outdoor
     *  (shouldTrackRoute iOS: título + exercises.map(\.exercise.name)). */
    data class ActiveSessionOutdoorInfo(
        val sessionId: String, val title: String, val exerciseNames: List<String>)

    @Synchronized fun activeSessionOutdoorInfo(): ActiveSessionOutdoorInfo? {
        val state = loadOrNull() ?: return null
        val session = state.optJSONObject("activeSession") ?: return null
        val names = mutableListOf<String>()
        val exercises = session.optJSONArray("exercises") ?: JSONArray()
        for (i in 0 until exercises.length()) {
            val name = exercises.optJSONObject(i)
                ?.optJSONObject("exercise")?.optString("name").orEmpty()
            if (name.isNotEmpty()) names += name
        }
        return ActiveSessionOutdoorInfo(
            sessionId = session.optString("id"),
            title = session.optString("title"),
            exerciseNames = names)
    }

    private fun finishInPlace(state: JSONObject, session: JSONObject) {
        check(session.optString("phase") != "finished")
        val exercises = session.getJSONArray("exercises")
        for (i in 0 until exercises.length()) {
            val exercise = exercises.getJSONObject(i)
            if ((exercise.optJSONArray("loggedSets")?.length() ?: 0) > 0) {
                exercise.put("isCompleted", true)
            }
        }
        session.put("phase", "finished").put("finishedAt", nowISO8601())
        state.getJSONArray("workouts").put(session)
        state.remove("activeSession")
        RotationSettings.advanceIfNeeded(state,session.optString("routineId").takeIf { it.isNotBlank() })
        // Valoración post-entreno (paridad ReperaStore.attachSessionReview iOS):
        // se calcula con todo el historial y se persiste dentro de la sesión.
        val review = SessionReviewSupport.attachToFinishedSession(state, session)
        save(state)
        if (review != null) {
            reviewPrefs.edit().putString(SessionReviewSupport.PREFS_PENDING_KEY,
                session.optString("id")).apply()
        }
    }

    /** Id del registro de Health Connect vinculado a la sesión
     *  (healthKitWorkoutUUID iOS), o null si no se ha vinculado. */
    @Synchronized fun healthRecordId(sessionId: String): String? {
        val state = loadOrNull() ?: return null
        val archive = state.optJSONArray("workouts") ?: return null
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") == sessionId) {
                return session.optString(
                    dev.repera.domain.HealthSessionLink.SNAPSHOT_FIELD)
                    .takeIf { it.isNotBlank() }
            }
        }
        return null
    }

    /** Persiste el vínculo sesión ↔ registro de Salud (campo aditivo). */
    @Synchronized fun setHealthRecordId(sessionId: String, recordId: String) {
        val state = loadOrNull() ?: return
        val archive = state.optJSONArray("workouts") ?: return
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") == sessionId) {
                session.put(dev.repera.domain.HealthSessionLink.SNAPSHOT_FIELD, recordId)
                save(state)
                return
            }
        }
    }

    /** Título + ventana de la sesión para la escritura en Salud. */
    /** liveSportID de una sesión archivada (null si es clásica o no existe). */
    @Synchronized fun liveSportId(sessionId: String): String? {
        val archive = loadOrNull()?.optJSONArray("workouts") ?: return null
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") != sessionId) continue
            return session.optString("liveSportID").takeIf { it.isNotBlank() && it != "null" }
        }
        return null
    }

    @Synchronized fun sessionTitleAndRange(sessionId: String): Triple<String, Long, Long>? {
        val state = loadOrNull() ?: return null
        val archive = state.optJSONArray("workouts") ?: return null
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") != sessionId) continue
            val start = runCatching { java.time.Instant.parse(
                session.optString("startedAt")).toEpochMilli() }.getOrNull()
            val end = runCatching { java.time.Instant.parse(
                session.optString("finishedAt")).toEpochMilli() }.getOrNull()
            if (start != null && end != null && end > start) {
                return Triple(session.optString("title").ifBlank { "Sesión" }, start, end)
            }
            return null
        }
        return null
    }

    /** Puntos GPS grabados por Repera de una sesión (exportación a Salud,
     *  Apple 435f6992). */
    @Synchronized fun sessionRoutePoints(sessionId: String): List<dev.repera.domain.WorkoutRoutePoint> {
        val state = loadOrNull() ?: return emptyList()
        val archive = state.optJSONArray("workouts") ?: return emptyList()
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") != sessionId) continue
            val arr = session.optJSONArray("routePoints") ?: return emptyList()
            return (0 until arr.length()).mapNotNull { j ->
                val p = arr.optJSONObject(j) ?: return@mapNotNull null
                dev.repera.domain.WorkoutRoutePoint(
                    id = p.optInt("id"),
                    latitude = p.optDouble("latitude"),
                    longitude = p.optDouble("longitude"),
                    recordedAtEpochMs = p.optLong("recordedAtEpochMs"),
                    speedMps = if (p.has("speedMps")) p.getDouble("speedMps") else null,
                    altitudeMeters = if (p.has("altitudeMeters")) p.getDouble("altitudeMeters") else null,
                    horizontalAccuracyMeters = if (p.has("horizontalAccuracyMeters")) p.getDouble("horizontalAccuracyMeters") else null,
                    verticalAccuracyMeters = if (p.has("verticalAccuracyMeters")) p.getDouble("verticalAccuracyMeters") else null,
                    isEstimated = if (p.has("isEstimated")) p.getBoolean("isEstimated") else null
                )
            }
        }
        return emptyList()
    }

    /** Ventana temporal de una sesión (epoch ms inicio/fin) para leer Salud. */
    @Synchronized fun sessionTimeRange(sessionId: String): Pair<Long, Long>? {
        val state = loadOrNull() ?: return null
        val archive = state.optJSONArray("workouts") ?: return null
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") != sessionId) continue
            val start = runCatching { java.time.Instant.parse(
                session.optString("startedAt")).toEpochMilli() }.getOrNull()
            val end = runCatching { java.time.Instant.parse(
                session.optString("finishedAt")).toEpochMilli() }.getOrNull()
            if (start != null && end != null && end > start) return start to end
            return null
        }
        return null
    }

    /** Afina la nota con la muestra de Salud (refineSessionReviewWithHealth
     *  iOS): se aplica tras terminar, cuando la lectura de Salud llega. */
    @Synchronized fun refineSessionReviewWithCardio(
        sessionId: String,
        sample: dev.repera.domain.SessionCardioSample
    ): dev.repera.domain.SessionReview? {
        val state = loadOrNull() ?: return null
        val updated = SessionReviewSupport.refineWithCardio(state, sessionId, sample)
        val energy = SessionReviewSupport.applyMeasuredEnergy(state, sessionId, sample.activeEnergyKcal, sample.sourceRecordId)
        if (updated == null && !energy) return null
        save(state)
        return updated
    }

    /** Valoración pendiente de mostrar tras terminar (pendingSessionReview iOS).
     *  Se consume una sola vez. */
    @Synchronized fun consumePendingReview(): Pair<String, SessionReview>? {
        val id = reviewPrefs.getString(SessionReviewSupport.PREFS_PENDING_KEY, null)
            ?: return null
        reviewPrefs.edit().remove(SessionReviewSupport.PREFS_PENDING_KEY).apply()
        val state = loadOrNull() ?: return null
        val archive = state.optJSONArray("workouts") ?: return null
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") == id) {
                val review = session.optJSONObject("sessionReview")
                    ?.let { SessionReviewJson.fromJson(it) } ?: return null
                return id to review
            }
        }
        return null
    }

    /** Recalcula notas de todos los entrenos si la fórmula cambió
     *  (refreshSessionReviewsIfNeeded iOS). */
    @Synchronized fun refreshSessionReviewsIfNeeded() {
        val stored = reviewPrefs.getInt(SessionReviewSupport.PREFS_VERSION_KEY, 0)
        val state = loadOrNull() ?: return
        if (SessionReviewSupport.refreshAllIfNeeded(state, stored)) {
            save(state)
        }
        if (stored < SessionReviewSupport.FORMULA_VERSION) {
            reviewPrefs.edit().putInt(SessionReviewSupport.PREFS_VERSION_KEY,
                SessionReviewSupport.FORMULA_VERSION).apply()
        }
    }

    private fun isMobilityHold(exercise: JSONObject): Boolean =
        exercise.optString("sportTag") == "Movilidad" &&
            exercise.optString("catalogId") in setOf(
                "mobility-14","mobility-15","mobility-16","mobility-20",
                "mobility-21","mobility-30","mobility-31","mobility-32",
                "mobility-36","mobility-38","mobility-39","mobility-40",
                "mobility-41","mobility-42","mobility-44","mobility-46",
                "mobility-60","mobility-61","mobility-62","mobility-67",
                "mobility-70","mobility-80"
            )

    private fun inputMode(exercise: JSONObject): ExerciseInputMode =
        ExerciseInput.mode(
            exercise.getString("name"),
            exercise.optString("equipment").takeIf { it.isNotBlank() },
            exercise.optString("targetMuscle").takeIf { it.isNotBlank() },
            exercise.optString("muscleGroup"),
            exercise.optString("sportTag")
        )

    private fun supportsSimpleInput(exercise: JSONObject) =
        inputMode(exercise).basicRecorderAvailable

    private fun nowISO8601(): String = DateTimeFormatter
        .ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")
        .withZone(ZoneOffset.UTC)
        .format(Instant.now())

    private fun loadOrNull(): JSONObject? {
        check(stillAuthorized()) {"La cuenta cambió antes de leer el historial"}
        return local.read()?.let { bytes ->
        LocalSnapshotStore.validate(bytes)
        JSONObject(String(bytes, Charsets.UTF_8)).also {loadedStates[it]=bytes}
    }

    }

    private fun requireState() = loadOrNull() ?: error("No hay estado local")
    private fun requireActive(state: JSONObject): JSONObject =
        state.optJSONObject("activeSession") ?: error("No hay sesión activa")

    private fun save(state: JSONObject) {
        check(stillAuthorized()) {"La cuenta cambió antes de guardar el historial"}
        state.put("syncRevision", state.optInt("syncRevision", 0) + 1)
        state.put("updatedAt", nowISO8601())
        state.put("lastWriterDeviceId", writerId)
        val expected=loadedStates[state] ?: error("Estado sin origen verificable")
        val replacement=state.toString().toByteArray(Charsets.UTF_8)
        check(local.replaceIfUnchanged(expected,replacement)) {
            "El historial cambió durante esta acción. No se sobrescribió; vuelve a intentarlo."
        }
        loadedStates[state]=replacement
        // Notification failure never turns an already durable training save into failure.
        runCatching {PlannedWorkoutNotification.refresh(context,googleId,state)}
    }

    private fun copyIfPresent(source: JSONObject, target: JSONObject, vararg keys: String) {
        for (key in keys) if (source.has(key) && !source.isNull(key)) target.put(key, source.get(key))
    }

    /** Rows of the Apple-style editable Play list; null when the classic form must be used (WOD, no basic recorder, or
     *  a logged work set that is not a straight set, because rows are matched to planned sets by position). */
    private fun liveRowsOf(current: JSONObject): List<LiveRowSummary>? {
        if (current.optString("blockKind") == "wod") return null
        val mode = inputMode(current.getJSONObject("exercise"))
        if (!mode.basicRecorderAvailable) return null
        val logged = current.optJSONArray("loggedSets") ?: JSONArray()
        val plan = current.optJSONArray("plannedSets") ?: JSONArray()
        val work = (0 until logged.length()).map { logged.getJSONObject(it) }.filter { it.optString("phase", "work") == "work" }
        if (work.any { it.optString("kind", "straight") != "straight" }) return null
        fun d(o: JSONObject, k: String) = if (o.has(k) && !o.isNull(k)) o.getDouble(k) else null
        val deficitMode = mode == ExerciseInputMode.HSPU_DEFICIT
        val done = work.map { set ->
            LiveRowSummary(set.getString("id"), set.optInt("reps"), d(set, "weightKg"),
                if (set.has("deficitCm") && !set.isNull("deficitCm")) set.getInt("deficitCm") else null,
                set.optInt("durationSeconds").takeIf { set.has("durationSeconds") && it > 0 }, d(set, "rir"), true)
        }
        val pending = (work.size until plan.length()).mapNotNull { n ->
            val p = plan.getJSONObject(n); val id = p.optString("id")
            if (id.isBlank()) null else {
                val target = d(p, "targetWeightKg")
                LiveRowSummary(id, p.optInt("targetReps"), if (deficitMode) null else target,
                    if (deficitMode) target?.toInt() else null,
                    p.optInt("targetDurationSeconds").takeIf { p.has("targetDurationSeconds") && it > 0 }, d(p, "targetRir"), false)
            }
        }
        return done + pending
    }

    private fun summarize(session: JSONObject): ActiveWorkout {
        val exercises = session.getJSONArray("exercises")
        val index = session.getInt("currentIndex")
        val current = exercises.getJSONObject(index)
        val plan = current.optJSONArray("plannedSets") ?: JSONArray()
        val logged = current.optJSONArray("loggedSets") ?: JSONArray()
        val finishedWork = (0 until logged.length()).count {
            logged.getJSONObject(it).optString("phase") == "work"
        }
        val next = if (plan.length() == 0) null
            else plan.getJSONObject(minOf(finishedWork, plan.length() - 1))
        val blockId = current.optString("blockId")
        val block = session.optJSONArray("routineBlocks")?.let { blocks ->
            (0 until blocks.length()).map { blocks.getJSONObject(it) }
                .firstOrNull { it.optString("id") == blockId }
        }
        val format = WodFormat.fromWire(current.optString("wodFormat"))
        val wod = if (current.optString("blockKind") == "wod" && format != null) {
            val moves = block?.optJSONArray("movements") ?: JSONArray()
            WodExecution(
                format = format.wireName,
                capture = format.capture.name,
                expectsRounds = format == WodFormat.AMRAP || format == WodFormat.DEATH_BY,
                title = block?.optString("title") ?: format.wireName,
                timeCapMinutes = block?.optInt("timeCapMinutes")?.takeIf { block.has("timeCapMinutes") },
                intervalSeconds = block?.optInt("emomIntervalSeconds")?.takeIf { block.has("emomIntervalSeconds") },
                rounds = block?.optInt("rounds")?.takeIf { block.has("rounds") },
                workSeconds = block?.optInt("workSeconds")?.takeIf { block.has("workSeconds") },
                restSeconds = block?.optInt("restSeconds")?.takeIf { block.has("restSeconds") },
                restBetweenRoundsSeconds = block?.optInt("restBetweenRoundsSeconds")?.takeIf {
                    block.has("restBetweenRoundsSeconds")
                },
                stations = (0 until moves.length()).count {
                    !moves.getJSONObject(it).optBoolean("isRest")
                }.coerceAtLeast(1),
                plannedIntervals = block?.optInt("plannedIntervals")?.takeIf {
                    block.has("plannedIntervals")
                },
                recorded = (0 until exercises.length()).map { exercises.getJSONObject(it) }
                    .filter { it.optString("blockId") == blockId }
                    .flatMap { item ->
                        val logs = item.optJSONArray("loggedSets") ?: JSONArray()
                        (0 until logs.length()).map { n ->
                            val s = logs.getJSONObject(n)
                            WodRecordedMovement(s.getString("id"),
                                item.getJSONObject("exercise").optString("name"),
                                s.optInt("intervalIndex"), s.optInt("reps"),
                                s.optDouble("weightKg").takeIf { s.has("weightKg") },
                                s.optString("quantityUnit").takeIf { it.isNotBlank() })
                        }
                    },
                movements = (0 until moves.length()).map { j ->
                    val m = moves.getJSONObject(j)
                    WodMovementSummary(
                        id = m.optString("id", m.optString("name")),
                        name = m.optString("name"),
                        isRest = m.optBoolean("isRest"),
                        reps = m.optInt("reps").takeIf { m.has("reps") && !m.isNull("reps") },
                        repScheme = m.optJSONArray("repScheme")?.let { a ->
                            (0 until a.length()).map { a.getInt(it) }
                        }.orEmpty(),
                        calories = m.optInt("calories").takeIf { m.has("calories") && !m.isNull("calories") },
                        meters = m.optInt("distanceMeters").takeIf {
                            m.has("distanceMeters") && !m.isNull("distanceMeters")
                        },
                        restSeconds = m.optInt("restSeconds").takeIf {
                            m.has("restSeconds") && !m.isNull("restSeconds")
                        }
                    )
                }
            )
        } else null
        return ActiveWorkout(
            id = session.getString("id"),
            draftRequestId=session.optString("draftRequestId").takeIf {it.isNotBlank()},
            routineId=session.optString("routineId").takeIf {it.isNotBlank() && it!="null"},
            title = session.getString("title"),
            index = index,
            total = exercises.length(),
            exerciseName = current.getJSONObject("exercise").exerciseDisplayName(),
            completedSets = logged.length(),
            prescribedQuantity = next?.optInt("targetReps"),
            prescribedDurationSeconds = next?.takeIf { it.has("targetDurationSeconds") }
                ?.optInt("targetDurationSeconds")?.takeIf { it > 0 },
            mobilityHold = isMobilityHold(current.getJSONObject("exercise")),
            mobility = current.getJSONObject("exercise").optString("sportTag") == "Movilidad",
            prescribedWeightKg = next?.takeIf { it.has("targetWeightKg") && !it.isNull("targetWeightKg") }
                ?.getDouble("targetWeightKg"),
            allowsWeight = inputMode(current.getJSONObject("exercise")).showsWeight,
            allowsDeficit = inputMode(current.getJSONObject("exercise")) == ExerciseInputMode.HSPU_DEFICIT,
            quantityUnit = current.optString("quantityUnit").takeIf { it in setOf("calories","meters","reps") }
                ?: ExerciseInput.defaultQuantityUnit(
                    current.getJSONObject("exercise").getString("name"),
                    current.getJSONObject("exercise").optString("equipment")),
            durationInput = inputMode(current.getJSONObject("exercise")) in
                setOf(ExerciseInputMode.MACHINE_WORK, ExerciseInputMode.REPS_AND_TIME,
                    ExerciseInputMode.LOAD_DISTANCE),
            repsMetersToggle = ExerciseInput.supportsRepsOrMeters(current.getJSONObject("exercise").getString("name")),
            cardioToggle = ExerciseInput.supportsCaloriesAndMeters(
                current.getJSONObject("exercise").getString("name"),
                current.getJSONObject("exercise").optString("equipment")),
            wod = wod,
            liveRows = liveRowsOf(current),
            quantityCap = if(ExerciseInput.supportsRepsOrMeters(current.getJSONObject("exercise").getString("name"))) 100_000 else QuickLogInput.quantityCap(inputMode(current.getJSONObject("exercise"))),
            isFavorite = loadOrNull()?.optJSONArray("routines")?.let { list ->
                (0 until list.length()).any {list.getJSONObject(it).optString("id")==session.optString("routineId") && list.getJSONObject(it).optBoolean("isFavorite")}
            } ?: false,
            notes = session.optString("notes").takeIf {it.isNotBlank()},
            navigationEntries = (0 until exercises.length()).map { n ->
                val entry=exercises.getJSONObject(n)
                ActiveExerciseNavigation(n,entry.getJSONObject("exercise").exerciseDisplayName(),
                    entry.optString("blockId"),entry.optString("blockKind"),entry.optBoolean("isCompleted"))
            },
            pendingSets = if (current.optString("blockKind") == "wod") emptyList()
                else (finishedWork until plan.length()).mapNotNull { n ->
                    val p = plan.getJSONObject(n); val id = p.optString("id")
                    if (id.isBlank()) null else PendingSetSummary(id, p.optInt("targetReps"),
                        if (p.has("targetWeightKg") && !p.isNull("targetWeightKg")) p.getDouble("targetWeightKg") else null)
                },
            sets = (0 until logged.length()).map { n ->
                val set = logged.getJSONObject(n)
                WorkoutSetSummary(
                    id = set.getString("id"),
                    reps = set.getInt("reps"),
                    weightKg = if (set.has("weightKg") && !set.isNull("weightKg"))
                        set.getDouble("weightKg") else null,
                    phase = set.optString("phase", "work"),
                    unit = set.optString("quantityUnit").takeIf { it in setOf("reps","calories","meters") }
                        ?: current.optString("quantityUnit").takeIf { it in setOf("reps","calories","meters") }
                        ?: "reps",
                    durationSeconds = set.optInt("durationSeconds").takeIf {
                        set.has("durationSeconds") && it > 0
                    },
                    deficitCm = set.optInt("deficitCm").takeIf {
                        set.has("deficitCm") && !set.isNull("deficitCm")
                    },
                    toFailure = set.optBoolean("toFailure"),
                    rir = if (set.has("rir") && !set.isNull("rir")) set.getDouble("rir") else null
                )
            }
        )
    }
}

data class WorkoutSetSummary(
    val id: String,
    val reps: Int,
    val weightKg: Double?,
    val phase: String = "work",
    val rir: Double? = null,
    val unit: String = "reps",
    val durationSeconds: Int? = null,
    val deficitCm: Int? = null,
    val toFailure: Boolean = false
)
data class ActiveWorkout(
    val id: String,
    val title: String,
    val index: Int,
    val total: Int,
    val exerciseName: String,
    val completedSets: Int,
    val prescribedQuantity: Int?,
    val prescribedWeightKg: Double?,
    val prescribedDurationSeconds: Int? = null,
    val mobilityHold: Boolean = false,
    val mobility: Boolean = false,
    val allowsWeight: Boolean,
    val sets: List<WorkoutSetSummary>,
    val allowsDeficit: Boolean = false,
    val quantityUnit: String = "reps",
    val durationInput: Boolean = false,
    val cardioToggle: Boolean = false,
    val wod: WodExecution? = null,
    val isFavorite: Boolean = false,
    val notes: String? = null,
    val navigationEntries: List<ActiveExerciseNavigation> = emptyList(),
    val draftRequestId:String? = null,
    val pendingSets: List<PendingSetSummary> = emptyList(),
    val liveRows: List<LiveRowSummary>? = null,
    val quantityCap: Int = 50,
    val routineId: String? = null,
    val repsMetersToggle:Boolean = false
)
data class PendingSetSummary(val id:String,val reps:Int,val weightKg:Double?)
/** Apple live row: a recorded straight work set (completed) or a pending planned set. null liveRows = use the classic form. */
data class LiveRowSummary(val id:String,val reps:Int,val weightKg:Double?,val deficitCm:Int?,val durationSeconds:Int?,val rir:Double?,val completed:Boolean)
data class ActiveExerciseNavigation(val index:Int,val name:String,val blockId:String,val blockKind:String,val completed:Boolean)

data class WodExecution(
    val format: String,
    val capture: String,
    val expectsRounds: Boolean,
    val title: String,
    val movements: List<WodMovementSummary>,
    val recorded: List<WodRecordedMovement> = emptyList(),
    val timeCapMinutes: Int? = null,
    val intervalSeconds: Int? = null,
    val rounds: Int? = null,
    val workSeconds: Int? = null,
    val restSeconds: Int? = null,
    val restBetweenRoundsSeconds: Int? = null,
    val stations: Int = 1,
    val plannedIntervals: Int? = null
)

data class WodRecordedMovement(val id: String, val name: String, val intervalIndex: Int, val quantity: Int, val weightKg: Double?, val quantityUnit: String?)

data class WodMovementSummary(
    val id: String,
    val name: String,
    val isRest: Boolean,
    val reps: Int?,
    val repScheme: List<Int>,
    val calories: Int?,
    val meters: Int?,
    val restSeconds: Int?
)

/** Borrador de bloque para el editor de contenido de rutinas. */
data class RoutineBlockDraft(
    val title: String = "",
    val format: String,
    val entries: List<RoutineDraftEntry>,
    val timeCapMinutes: Int = 12,
    val rounds: Int = 1,
    val emomIntervalSeconds: Int = 60,
    val workSeconds: Int = 20,
    val restSeconds: Int = 10,
    val ladderScheme: List<Int>? = null,
    /** For Time / iOS `restBetweenRoundsSeconds` («Entre rondas»). */
    val restBetweenRoundsSeconds: Int? = null,
    /** Identidad del bloque original (editar conserva ids y campos no editables). */
    val blockId: String? = null,
    val sourceJson: String? = null
)

data class RoutineDraftEntry(
    val exerciseId: String,
    val quantity: Int,
    val sets: Int = 3,
    val weightKg: Double? = null,
    val restSeconds: Int? = null,
    /** Editor por serie (fuerza): cuando llega, sustituye a sets/quantity/
     *  weightKg uniformes y se escribe 1:1 (paridad PlannedSet iOS). */
    val plannedSets: List<PlannedSetDraft>? = null,
    /** Identidad y JSON original del ítem/movimiento (REST, escala, peso M, notas...). */
    val itemId: String? = null,
    val sourceJson: String? = null,
    /** Unidad de cardio elegida en el editor (calories/meters); null = conservar la original. */
    val quantityUnit: String? = null
)

/** Serie planificada (port de PlannedSet iOS). targetRir null = sin fijar;
 *  se muestra como «asumido» donde aplique, nunca como objetivo confirmado. */
data class PlannedSetDraft(
    val targetReps: Int,
    val targetWeightKg: Double? = null,
    val targetRir: Double? = null,
    val id: String? = null,
    val targetDurationSeconds:Int? = null,
    val sourceJson:String? = null
)

/** Mirrors Swift Routine: one-off dates and weekly templates are mutually exclusive. */
data class RoutineSchedule(
    val scheduledDate: String? = null,
    val weekday: Int? = null,
    val timeMinutes: Int? = null
)

/**
 * Crea los ejercicios personalizados diferidos (`pending:<nombre>`) del editor de plan
 * SOLO al guardar: capacidad del lote validada antes de escribir, identidad por nombre
 * normalizado, y una única escritura posterior (la llamante guarda el estado al final).
 * Diferencia documentada con Apple (addCustomExercise persiste al instante).
 */
internal fun materializePendingCustoms(
    blocks: List<RoutineBlockDraft>, state: JSONObject, canCreateCustom: (Int) -> Boolean
): List<RoutineBlockDraft> {
    val pend = linkedSetOf<String>()
    blocks.forEach { b -> b.entries.forEach {
        if (it.exerciseId.startsWith(EditorBlockOps.PENDING_PREFIX)) pend += it.exerciseId.removePrefix(EditorBlockOps.PENDING_PREFIX) } }
    if (pend.isEmpty()) return blocks
    val catalog = state.getJSONArray("exercises")
    val byNorm = mutableMapOf<String, String>()
    for (i in 0 until catalog.length()) catalog.getJSONObject(i).let {
        byNorm.putIfAbsent(foldForSearch(it.optString("name")), it.getString("id")) }
    val toCreate = pend.map { foldForSearch(it) }.distinct().filter { it !in byNorm }
    val customsNow = (0 until catalog.length()).count { catalog.getJSONObject(it).optBoolean("isCustom") }
    if (toCreate.isNotEmpty())
        check(canCreateCustom(customsNow + toCreate.size - 1)) { "Límite de ejercicios personalizados alcanzado" }
    val idByName = mutableMapOf<String, String>()
    for (name in pend) {
        val norm = foldForSearch(name)
        byNorm[norm]?.let { idByName[name] = it; continue }
        val newId = UUID.randomUUID().toString()
        catalog.put(JSONObject().put("id", newId).put("name", name.trim()).put("muscleGroup", "Otros")
            .put("equipment", JSONObject.NULL).put("targetMuscle", "")
            .put("secondaryMuscles", JSONArray()).put("isCustom", true))
        byNorm[norm] = newId; idByName[name] = newId
    }
    return blocks.map { b -> b.copy(entries = b.entries.map { e ->
        if (!e.exerciseId.startsWith(EditorBlockOps.PENDING_PREFIX)) e else {
            val real = idByName.getValue(e.exerciseId.removePrefix(EditorBlockOps.PENDING_PREFIX))
            e.copy(exerciseId = real, sourceJson = e.sourceJson?.let { j ->
                runCatching { JSONObject(j).put("exerciseId", real).toString() }.getOrDefault(j) })
        } }) }
}

