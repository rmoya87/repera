package dev.repera.mobile

import android.content.Context
import dev.repera.domain.ExerciseInput
import dev.repera.domain.ExerciseInputMode
import dev.repera.domain.WodFormat
import dev.repera.domain.ResultCapture
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
class WorkoutRepository(context: Context, googleId: String) {
    private val local = LocalSnapshotStore(context, googleId)
    private val prefs = context.getSharedPreferences("repera.local.writer", Context.MODE_PRIVATE)
    private val writerId: String by lazy {
        prefs.getString("writerId", null) ?: UUID.randomUUID().toString().also {
            prefs.edit().putString("writerId", it).apply()
        }
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
        schedule: RoutineSchedule = RoutineSchedule()
    ): String {
        val cleaned = title.trim()
        require(cleaned.isNotBlank() && cleaned.length <= 100) { "Escribe un título válido" }
        require(format in setOf("strength", "amrap", "forTime")) { "Tipo de rutina no permitido" }
        require(entries.isNotEmpty()) { "Añade al menos un ejercicio" }
        require(entries.map { it.exerciseId }.distinct().size == entries.size) {
            "No se puede repetir el mismo ejercicio en esta plantilla"
        }
        require(entries.size <= 60) { "Demasiados movimientos" }
        require(timeCapMinutes in 1..180 && rounds in 1..100)
        require(schedule.scheduledDate == null || schedule.weekday == null) {
            "Un entreno no puede ser semanal y de fecha concreta a la vez"
        }
        require(schedule.weekday == null || schedule.weekday in 1..7)
        require(schedule.timeMinutes == null || schedule.timeMinutes in 0..1439)
        val scheduledDay = schedule.scheduledDate?.let { LocalDate.parse(it) }
        val state = requireState()
        val catalog = state.getJSONArray("exercises")
        val byId = (0 until catalog.length()).associate {
            val exercise = catalog.getJSONObject(it)
            exercise.getString("id") to exercise
        }
        val block = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("title", if (format == "strength") "Fuerza" else if (format == "amrap") "AMRAP" else "For Time")
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
                repeat(entry.sets) {
                    val set = JSONObject().put("id", UUID.randomUUID().toString())
                        .put("targetReps", entry.quantity)
                    if (entry.weightKg != null) set.put("targetWeightKg", entry.weightKg)
                    planned.put(set)
                }
                exercises.put(JSONObject().put("id", UUID.randomUUID().toString())
                    .put("exerciseId", entry.exerciseId).put("plannedSets", planned)
                    .put("quantityUnit", ExerciseInput.defaultQuantityUnit(
                        movement.getString("name"), movement.optString("equipment"))))
            }
            block.put("exercises", exercises)
        } else {
            val movements = JSONArray()
            for (entry in entries) {
                val movement = byId[entry.exerciseId] ?: error("Ejercicio no encontrado")
                require(entry.quantity in 1..10000)
                movements.put(JSONObject()
                    .put("id", UUID.randomUUID().toString())
                    .put("exerciseId", entry.exerciseId)
                    .put("name", movement.getString("name"))
                    .put("reps", entry.quantity)
                    .put("isRest", false))
            }
            block.put("movements", movements)
                .put("wodFormat", format)
                .put("timeCapMinutes", timeCapMinutes)
            if (format == "forTime") block.put("rounds", rounds)
        }
        val id = UUID.randomUUID().toString()
        val nativeRoutine = JSONObject()
            .put("id", id)
            .put("title", cleaned)
            .put("blocks", JSONArray().put(block))
            .put("progression", "off")
            .put("isFavorite", false)
        if (scheduledDay != null) {
            // Swift Routine.scheduledDate stores the user's calendar start-of-day as a Date.
            nativeRoutine.put("scheduledDate", scheduledDay.atStartOfDay(ZoneId.systemDefault())
                .toInstant().toString())
        } else if (schedule.weekday != null) {
            nativeRoutine.put("weekday", schedule.weekday)
        }
        if (schedule.timeMinutes != null)
            nativeRoutine.put("scheduledTimeMinutes", schedule.timeMinutes)
        state.getJSONArray("routines").put(nativeRoutine)
        save(state)
        return id
    }

    @Synchronized fun active(): ActiveWorkout? {
        val state = loadOrNull() ?: return null
        return state.optJSONObject("activeSession")?.let { summarize(it) }
    }

    @Synchronized fun startStrengthRoutine(id: String): ActiveWorkout = startRoutine(id)

    @Synchronized fun startRoutine(id: String): ActiveWorkout {
        val state = loadOrNull() ?: error("Importa primero un historial o crea tus datos locales")
        check(state.isNull("activeSession")) { "Ya existe una sesión activa" }
        val routines = state.getJSONArray("routines")
        val routine = (0 until routines.length()).map { routines.getJSONObject(it) }
            .firstOrNull { it.optString("id") == id } ?: error("Rutina no encontrada")
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
        val planned = JSONArray()
        for (blockIndex in 0 until blocks.length()) {
            val block = blocks.getJSONObject(blockIndex)
            if (block.optString("kind") == "wod") {
                WodSessionAssembler.append(block, catalog, planned)
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
                val item = JSONObject()
                    .put("id", UUID.randomUUID().toString())
                    .put("exercise", JSONObject(exercise.toString()))
                    .put("plannedSets", JSONArray((entry.optJSONArray("plannedSets") ?: JSONArray()).toString()))
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
        val session = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("title", routine.getString("title"))
            .put("routineId", id)
            .put("exercises", planned)
            .put("currentIndex", 0)
            .put("phase", "ready")
            .put("startedAt", nowISO8601())
            .put("wodResults", JSONArray())
            .put("routineBlocks", JSONArray(blocks.toString()))
            .put("routePoints", JSONArray())
        state.put("activeSession", session)
        save(state)
        return summarize(session)
    }

    /**
     * Swift ReperaStore.startQuickLog: one selected real exercise, three targets
     * copied from the latest saved workout when available; never invent recorded sets.
     */
    @Synchronized fun startQuickLog(exerciseId: String): ActiveWorkout {
        val state = requireState()
        check(state.isNull("activeSession")) { "Ya existe una sesión activa" }
        val catalog = state.getJSONArray("exercises")
        val exercise = (0 until catalog.length()).map { catalog.getJSONObject(it) }
            .firstOrNull { it.optString("id") == exerciseId }
            ?: error("Ejercicio no encontrado")
        val history = state.getJSONArray("workouts")
        val inputMode = inputMode(exercise)
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
                .put("targetReps", lastReps ?: if (inputMode == ExerciseInputMode.MACHINE_WORK) 0 else 8)
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
        durationSeconds: Int? = null
    ): ActiveWorkout {
        require(setId == null || setId.isNotBlank())
        require(quantity >= 0) { "Cantidad inválida" }
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0)) { "Peso inválido" }
        require(rir == null || (rir.isFinite() && rir >= 0)) { "RIR inválido" }
        require(durationSeconds == null || durationSeconds in 1..86400) { "Duración inválida" }
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
        if (inputMode == ExerciseInputMode.MACHINE_WORK || inputMode == ExerciseInputMode.REPS_AND_TIME) {
            check(weightKg == null && rir == null && !warmup) { "Cardio no admite lastre, RIR o calentamiento de fuerza" }
        }
        check(inputMode.showsWeight || weightKg == null) {
            "Este ejercicio no registra peso"
        }
        check(!exercise.optBoolean("isCompleted")) { "Ejercicio ya completado" }
        val logged = exercise.getJSONArray("loggedSets")
        val set = JSONObject()
            .put("id", setId ?: UUID.randomUUID().toString())
            .put("reps", quantity)
            .put("completedAt", nowISO8601())
            .put("phase", if (warmup) "warmup" else "work")
            .put("kind", "straight")
            .put("toFailure", false)
            .put("drops", JSONArray())
            .put("clusters", JSONArray())
        if (weightKg != null) set.put("weightKg", weightKg)
        if (rir != null) set.put("rir", rir)
        val unit = quantityUnit ?: exercise.optString("quantityUnit")
            .takeIf { it in setOf("reps", "calories", "meters") }
            ?: ExerciseInput.defaultQuantityUnit(
                movement.getString("name"), movement.optString("equipment"))
        if (inputMode == ExerciseInputMode.MACHINE_WORK) {
            check(unit == "meters" || unit == "calories")
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
        movementIndex: Int, intervalIndex: Int, quantity: Int, weightKg: Double?
    ): ActiveWorkout {
        require(movementIndex >= 0 && intervalIndex >= 0 && quantity >= 0)
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
            WodFormat.EMOM, WodFormat.TABATA, WodFormat.CIRCUIT ->
                sourceBlock?.optInt("rounds", if (format == WodFormat.TABATA) 8 else 0)
                    ?.takeIf { it > 0 }
            else -> null
        }
        if (maximumInterval != null && format != WodFormat.CIRCUIT)
            require(intervalIndex < maximumInterval) { "Intervalo fuera de la programación" }
        val movements = (0 until exercises.length()).map { exercises.getJSONObject(it) }
            .filter { it.optString("blockId") == blockId }
        require(movementIndex < movements.size) { "Movimiento fuera del bloque" }
        val exercise = movements[movementIndex]
        val set = JSONObject()
            .put("id", UUID.randomUUID().toString())
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

    @Synchronized fun finish(): Unit {
        val state = requireState()
        finishInPlace(state, requireActive(state))
    }

    /**
     * Apply a wearable action idempotently. Reject mismatched sessions/indices and
     * preserve original set ID so a lost acknowledgement cannot duplicate the set.
     * Called only after the phone has a verified signed-in account.
     */
    @Synchronized fun logWearSet(
        sessionId: String, exerciseIndex: Int, setId: String, quantity: Int, weightKg: Double?
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
        val active = requireActive(state)
        check(active.optString("id") == sessionId) { "La sesión del reloj ya no es la activa" }
        check(active.optInt("currentIndex") == exerciseIndex) {
            "El ejercicio activo ha cambiado"
        }
        val exercise = active.getJSONArray("exercises").getJSONObject(exerciseIndex)
        check(exercise.optString("blockKind") != "wod" && !exercise.optBoolean("isCompleted")) {
            "El reloj solo puede registrar series de fuerza abiertas"
        }
        logCurrentSet(quantity, weightKg, rir = null, warmup = false, setId = setId)
        return true
    }

    /** Undo a saved strength set without changing the identity or timestamp of any other set. */
    @Synchronized fun deleteCurrentSet(setId: String): ActiveWorkout {
        val state = requireState()
        val session = requireActive(state)
        val exercise = session.getJSONArray("exercises").getJSONObject(session.getInt("currentIndex"))
        check(exercise.optString("blockKind") != "wod") { "Usa el editor WOD para estos movimientos" }
        check(!exercise.optBoolean("isCompleted")) { "No se puede editar un ejercicio cerrado" }
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
        quantityUnit: String? = null, durationSeconds: Int? = null
    ): ActiveWorkout {
        require(quantity >= 0 && (weightKg == null || (weightKg.isFinite() && weightKg >= 0)))
        require(durationSeconds == null || durationSeconds in 1..86400)
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
        val original = logged.getJSONObject(index)
        original.put("reps", quantity)
        if (weightKg == null) original.remove("weightKg") else original.put("weightKg", weightKg)
        if (quantityUnit != null) {
            if (inputMode(movement) == ExerciseInputMode.MACHINE_WORK) {
                check(quantityUnit in setOf("calories", "meters"))
                check(ExerciseInput.supportsCaloriesAndMeters(
                    movement.getString("name"), movement.optString("equipment")) ||
                    quantityUnit == ExerciseInput.defaultQuantityUnit(
                        movement.getString("name"), movement.optString("equipment")))
            } else check(quantityUnit == "reps")
            original.put("quantityUnit", quantityUnit)
        }
        if (durationSeconds != null) original.put("durationSeconds", durationSeconds)
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
        save(state)
    }

    private fun inputMode(exercise: JSONObject): ExerciseInputMode =
        ExerciseInput.mode(
            exercise.getString("name"),
            exercise.optString("equipment").takeIf { it.isNotBlank() },
            exercise.optString("targetMuscle").takeIf { it.isNotBlank() },
            exercise.optString("muscleGroup")
        )

    private fun supportsSimpleInput(exercise: JSONObject) =
        inputMode(exercise).basicRecorderAvailable

    private fun nowISO8601(): String = DateTimeFormatter
        .ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")
        .withZone(ZoneOffset.UTC)
        .format(Instant.now())

    private fun loadOrNull(): JSONObject? = local.read()?.let { bytes ->
        LocalSnapshotStore.validate(bytes)
        JSONObject(String(bytes, Charsets.UTF_8))
    }

    private fun requireState() = loadOrNull() ?: error("No hay estado local")
    private fun requireActive(state: JSONObject): JSONObject =
        state.optJSONObject("activeSession") ?: error("No hay sesión activa")

    private fun save(state: JSONObject) {
        state.put("syncRevision", state.optInt("syncRevision", 0) + 1)
        state.put("updatedAt", nowISO8601())
        state.put("lastWriterDeviceId", writerId)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
    }

    private fun copyIfPresent(source: JSONObject, target: JSONObject, vararg keys: String) {
        for (key in keys) if (source.has(key) && !source.isNull(key)) target.put(key, source.get(key))
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
            title = session.getString("title"),
            index = index,
            total = exercises.length(),
            exerciseName = current.getJSONObject("exercise").getString("name"),
            completedSets = logged.length(),
            prescribedQuantity = next?.optInt("targetReps"),
            prescribedWeightKg = next?.takeIf { it.has("targetWeightKg") && !it.isNull("targetWeightKg") }
                ?.getDouble("targetWeightKg"),
            allowsWeight = inputMode(current.getJSONObject("exercise")).showsWeight,
            quantityUnit = current.optString("quantityUnit").takeIf { it in setOf("calories","meters","reps") }
                ?: ExerciseInput.defaultQuantityUnit(
                    current.getJSONObject("exercise").getString("name"),
                    current.getJSONObject("exercise").optString("equipment")),
            durationInput = inputMode(current.getJSONObject("exercise")) in
                setOf(ExerciseInputMode.MACHINE_WORK, ExerciseInputMode.REPS_AND_TIME),
            cardioToggle = ExerciseInput.supportsCaloriesAndMeters(
                current.getJSONObject("exercise").getString("name"),
                current.getJSONObject("exercise").optString("equipment")),
            wod = wod,
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
    val durationSeconds: Int? = null
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
    val allowsWeight: Boolean,
    val sets: List<WorkoutSetSummary>,
    val quantityUnit: String = "reps",
    val durationInput: Boolean = false,
    val cardioToggle: Boolean = false,
    val wod: WodExecution? = null
)

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
    val restBetweenRoundsSeconds: Int? = null
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

data class RoutineDraftEntry(
    val exerciseId: String,
    val quantity: Int,
    val sets: Int = 3,
    val weightKg: Double? = null
)

/** Mirrors Swift Routine: one-off dates and weekly templates are mutually exclusive. */
data class RoutineSchedule(
    val scheduledDate: String? = null,
    val weekday: Int? = null,
    val timeMinutes: Int? = null
)
