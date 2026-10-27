package dev.repera.mobile

import dev.repera.domain.ExerciseInput
import dev.repera.domain.ExerciseInputMode
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Port de CompletedWorkoutEditing.swift (ReperaDomain) sobre el JSON de sesión
 * de Android. Los sets REGISTRADOS son la fuente de verdad: guardar nunca
 * convierte objetivos pendientes en repeticiones realizadas, salvo que el
 * usuario añada/edite series en el editor (entonces se crean con completedAt =
 * finishedAt, como Apple).
 *
 * Alcance Android (documentado en STATUS_AND_PARITY):
 *  - fuerza: port completo (ids, reordenación entre bloques, set targets → loggedSets);
 *  - WOD: routine(from:) reconstruye movimientos desde las entradas (REST se conserva);
 *    applying usa explicitPlannedSets y, si no hay, RoutineBlock.plannedSets(for:)
 *    portado en domain (WodPlannedSets: EMOM/circuit/Tabata/rondas); los wodResults se
 *    validan contra el formato (un cambio de formato los invalida).
 */
object CompletedWorkoutEditing {

    enum class ScoreField { REPS, ROUNDS, MINUTES, SECONDS }

    private fun fmtOf(block: JSONObject) = dev.repera.domain.WodFormat.fromWire(block.optString("wodFormat"))

    private fun hasNum(o: JSONObject, k: String) = o.has(k) && !o.isNull(k)

    /** Apple scoreMatches: un histórico sin formato solo coincide con un editor de la misma unidad. */
    private fun scoreMatches(r: JSONObject, format: dev.repera.domain.WodFormat): Boolean {
        val rf = r.optString("format").takeIf { it.isNotBlank() && it != "null" }
        if (rf != null) return rf == format.wireName
        return when (format.capture.name) {
            "TOTAL_REPS" -> hasNum(r, "totalReps") || hasNum(r, "roundsCompleted")
            "ELAPSED_TIME" -> hasNum(r, "elapsedSeconds")
            else -> false
        }
    }

    private fun usesRounds(f: dev.repera.domain.WodFormat) = f == dev.repera.domain.WodFormat.AMRAP || f == dev.repera.domain.WodFormat.DEATH_BY

    /** Apple editableScore: el resultado guardado; o, para un AMRAP/total histórico con UNA sola serie sin carga
     *  en el primer movimiento, un valor inferido SOLO para mostrar (no escribe ni duplica series). */
    fun editableScore(block: JSONObject, session: JSONObject): JSONObject? {
        val format = fmtOf(block) ?: return null
        if (format.capture.name == "PER_MOVEMENT_SETS") return null
        val id = block.optString("id")
        val rs = session.optJSONArray("wodResults") ?: JSONArray()
        for (i in rs.length() - 1 downTo 0) {
            val r = rs.getJSONObject(i)
            if (r.optString("id") == id && scoreMatches(r, format)) return r
        }
        if (format.capture.name != "TOTAL_REPS") return null
        val ex = session.optJSONArray("exercises") ?: return null
        val first = (0 until ex.length()).map { ex.getJSONObject(it) }.firstOrNull { it.optString("blockId") == id } ?: return null
        val logged = first.optJSONArray("loggedSets") ?: return null
        if (logged.length() != 1) return null
        val set = logged.getJSONObject(0)
        if (hasNum(set, "weightKg") || hasNum(set, "deficitCm")) return null
        return JSONObject().put("id", id).put("format", format.wireName).put("totalReps", set.optInt("reps"))
            .apply { if (usesRounds(format)) put("roundsCompleted", 0) }
    }

    fun scoreValue(block: JSONObject, session: JSONObject, field: ScoreField): Int {
        val r = editableScore(block, session)
        return when (field) {
            ScoreField.REPS -> r?.takeIf { hasNum(it, "totalReps") }?.getInt("totalReps") ?: 0
            ScoreField.ROUNDS -> r?.takeIf { hasNum(it, "roundsCompleted") }?.getInt("roundsCompleted") ?: 0
            ScoreField.MINUTES -> maxOf(0, r?.takeIf { hasNum(it, "elapsedSeconds") }?.getInt("elapsedSeconds") ?: 0) / 60
            ScoreField.SECONDS -> maxOf(0, r?.takeIf { hasNum(it, "elapsedSeconds") }?.getInt("elapsedSeconds") ?: 0) % 60
        }
    }

    /** Apple changingScore: solo marca COMPLETADA; no toca prescripción, sets registrados ni otros bloques.
     *  Un score de otro formato es histórico y no se elimina. Límites: reps 5000, rondas 200, min 180, s 59. */
    fun changingScore(session: JSONObject, block: JSONObject, field: ScoreField, value: Int): JSONObject {
        val format = fmtOf(block) ?: return session
        val cap = format.capture.name
        if (cap == "PER_MOVEMENT_SETS") return session
        when (field) {
            ScoreField.REPS, ScoreField.ROUNDS -> if (cap != "TOTAL_REPS") return session
            ScoreField.MINUTES, ScoreField.SECONDS -> if (cap != "ELAPSED_TIME") return session
        }
        if (field == ScoreField.ROUNDS && !usesRounds(format)) return session
        val id = block.optString("id")
        val result = editableScore(block, session)?.let { JSONObject(it.toString()) }
            ?: JSONObject().put("id", id).apply {
                if (cap == "TOTAL_REPS") put("totalReps", 0) else put("elapsedSeconds", 0)
                if (usesRounds(format)) put("roundsCompleted", 0)
            }
        block.optString("wodTemplateId").takeIf { it.isNotBlank() }?.let { result.put("wodTemplateId", it) }
        result.put("format", format.wireName)
        val secs = maxOf(0, if (hasNum(result, "elapsedSeconds")) result.getInt("elapsedSeconds") else 0)
        when (field) {
            ScoreField.REPS -> result.put("totalReps", value.coerceIn(0, 5000))
            ScoreField.ROUNDS -> result.put("roundsCompleted", value.coerceIn(0, 200))
            ScoreField.MINUTES -> result.put("elapsedSeconds", value.coerceIn(0, 180) * 60 + secs % 60)
            ScoreField.SECONDS -> result.put("elapsedSeconds", secs / 60 * 60 + value.coerceIn(0, 59))
        }
        val updated = JSONObject(session.toString())
        val old = updated.optJSONArray("wodResults") ?: JSONArray()
        val next = JSONArray()
        for (i in 0 until old.length()) {
            val r = old.getJSONObject(i)
            if (!(r.optString("id") == id && scoreMatches(r, format))) next.put(r)
        }
        next.put(result)
        return updated.put("wodResults", next)
    }

    /** Series visibles (Apple visibleSets, live main 26 Oct): las realizadas se superponen por posición sobre las
     *  planificadas, conservando detrás las pendientes con sus valores; sin registros, las planificadas. */
    private fun visibleSets(entry: JSONObject): JSONArray {
        val planned = entry.optJSONArray("plannedSets") ?: JSONArray()
        val logged = entry.optJSONArray("loggedSets")
        if (logged == null || logged.length() == 0) return planned
        val visible = (0 until planned.length()).map { planned.getJSONObject(it) }.toMutableList()
        for (i in 0 until logged.length()) {
            val l = logged.getJSONObject(i)
            val p = JSONObject().put("id", l.getString("id")).put("targetReps", l.optInt("reps"))
            val w = if (l.has("deficitCm") && !l.isNull("deficitCm")) l.getInt("deficitCm").toDouble()
            else if (l.has("weightKg") && !l.isNull("weightKg")) l.getDouble("weightKg") else null
            if (w != null) p.put("targetWeightKg", w)
            if (l.has("durationSeconds") && !l.isNull("durationSeconds")) p.put("targetDurationSeconds", l.getInt("durationSeconds"))
            if (l.has("rir") && !l.isNull("rir")) p.put("targetRir", l.getDouble("rir"))
            if (i < visible.size) visible[i] = p else visible.add(p)
        }
        return JSONArray(visible.map { it })
    }

    /** Formato registrado en wodResults del bloque, solo si su captura no es por-movimiento. */
    internal fun recordedFormat(session: JSONObject, blockId: String): String? {
        val rs = session.optJSONArray("wodResults") ?: return null
        for (i in 0 until rs.length()) {
            val r = rs.getJSONObject(i)
            if (r.optString("id") != blockId) continue
            val f = r.optString("format").takeIf { it.isNotBlank() } ?: return null
            val fmt = dev.repera.domain.WodFormat.fromWire(f) ?: return null
            return if (fmt.capture.name != "PER_MOVEMENT_SETS") f else null
        }
        return null
    }

    private fun captureOf(block: JSONObject): String? =
        dev.repera.domain.WodFormat.fromWire(block.optString("wodFormat"))?.capture?.name

    private fun isGlobalCapture(block: JSONObject): Boolean {
        val c = captureOf(block) ?: return false
        return c != "PER_MOVEMENT_SETS"
    }

    /** CompletedWorkoutEditing.routine(from:sourceRoutine:) → bloques editables con ids. */
    fun blocksFrom(session: JSONObject, sourceRoutine: JSONObject?): JSONArray {
        val sources = session.optJSONArray("routineBlocks")
            ?: sourceRoutine?.optJSONArray("blocks") ?: JSONArray()
        val remaining = mutableListOf<JSONObject>().also { list ->
            val ex = session.optJSONArray("exercises") ?: JSONArray()
            for (i in 0 until ex.length()) list += ex.getJSONObject(i)
        }
        val blocks = JSONArray()
        for (s in 0 until sources.length()) {
            val source = JSONObject(sources.getJSONObject(s).toString())
            val sourceId = source.getString("id")
            // Apple (live main): un snapshot sin wodFormat recupera el formato del resultado registrado
            // (si no es por-movimiento) para no perder el tiempo/score al abrir y guardar.
            if (!source.has("wodFormat") || source.isNull("wodFormat")) recordedFormat(session, sourceId)?.let { source.put("wodFormat", it) }
            val entries = remaining.filter { it.optString("blockId") == sourceId }
            remaining.removeAll { it.optString("blockId") == sourceId }
            if (source.optString("kind") == "strength") {
                val srcEx = source.optJSONArray("exercises") ?: JSONArray()
                val global = isGlobalCapture(source)
                val mapped = JSONArray()
                entries.forEachIndexed { index, entry ->
                    val srcAt = if (index < srcEx.length()) srcEx.getJSONObject(index) else null
                    val re = JSONObject()
                        .put("id", entry.getString("id"))
                        .put("exerciseId", entry.getJSONObject("exercise").getString("id"))
                        .put("plannedSets", if (global && srcAt != null)
                            (srcAt.optJSONArray("plannedSets") ?: entry.optJSONArray("plannedSets") ?: JSONArray())
                        else visibleSets(entry))
                    entry.optString("quantityUnit").takeIf { it.isNotBlank() }?.let { re.put("quantityUnit", it) }
                    if (srcAt != null && srcAt.has("restSeconds") && !srcAt.isNull("restSeconds"))
                        re.put("restSeconds", srcAt.get("restSeconds"))
                    mapped.put(re)
                }
                source.put("exercises", mapped)
                source.put("movements", JSONArray())
            }
            else {
                // Bloque WOD (routine(from:) Apple): REST se conserva, cada movimiento no-REST toma
                // su entrada de sesión por orden; sobrantes se añaden al final.
                var index = 0
                val movements = JSONArray()
                val origMoves = source.optJSONArray("movements") ?: JSONArray()
                val preserve = source.has("wodFormat") && !source.isNull("wodFormat") && isGlobalCapture(source)
                for (i in 0 until origMoves.length()) {
                    val original = origMoves.getJSONObject(i)
                    if (original.optBoolean("isRest")) movements.put(original)
                    else if (index < entries.size) {
                        movements.put(movementFor(entries[index], original, preserve)); index++
                    }
                }
                for (extra in entries.drop(index)) movements.put(movementFor(extra, null, false))
                source.put("movements", movements)
                source.put("exercises", JSONArray())
            }
            blocks.put(source)
        }
        // Históricos anteriores al snapshot (o ejercicios sin bloque).
        fun indexOfBlock(id: String) = (0 until blocks.length()).firstOrNull { blocks.getJSONObject(it).optString("id") == id }
        for (entry in remaining) {
            val blockId = entry.optString("blockId").ifBlank { entry.getString("id") }
            val kind = entry.optString("blockKind").ifBlank { "strength" }
            val exId = entry.getJSONObject("exercise").getString("id")
            val idx = indexOfBlock(blockId)
            if (kind == "strength") {
                val item = JSONObject().put("id", entry.getString("id")).put("exerciseId", exId)
                    .put("plannedSets", visibleSets(entry))
                entry.optString("quantityUnit").takeIf { it.isNotBlank() }?.let { item.put("quantityUnit", it) }
                if (idx != null) {
                    val b = blocks.getJSONObject(idx)
                    b.put("exercises", (b.optJSONArray("exercises") ?: JSONArray()).put(item))
                } else blocks.put(newBlock(entry, blockId, "strength", blocks.length() + 1)
                    .also { nb -> if (!nb.has("wodFormat")) recordedFormat(session, blockId)?.let { nb.put("wodFormat", it) } }
                    .put("exercises", JSONArray().put(item)).put("movements", JSONArray()))
            } else {
                val mv = movementFor(entry, null)
                if (idx != null) {
                    val b = blocks.getJSONObject(idx)
                    b.put("movements", (b.optJSONArray("movements") ?: JSONArray()).put(mv))
                } else blocks.put(newBlock(entry, blockId, "wod", blocks.length() + 1)
                    .also { nb -> if (!nb.has("wodFormat")) recordedFormat(session, blockId)?.let { nb.put("wodFormat", it) } }
                    .put("movements", JSONArray().put(mv)).put("exercises", JSONArray()))
            }
        }
        return blocks
    }

    private fun spec(m: JSONObject): dev.repera.domain.WodMovementSpec = dev.repera.domain.WodMovementSpec(
        id = m.optString("id"),
        reps = if (m.has("reps") && !m.isNull("reps")) m.getInt("reps") else null,
        repScheme = m.optJSONArray("repScheme")?.let { a -> (0 until a.length()).map { a.getInt(it) } },
        distanceMeters = if (m.has("distanceMeters") && !m.isNull("distanceMeters")) m.getInt("distanceMeters") else null,
        calories = if (m.has("calories") && !m.isNull("calories")) m.getInt("calories") else null,
        weightMaleKg = if (m.has("weightMaleKg") && !m.isNull("weightMaleKg")) m.getDouble("weightMaleKg") else null,
        isRest = m.optBoolean("isRest"),
        explicitPlannedSets = m.optJSONArray("explicitPlannedSets")?.let { a ->
            (0 until a.length()).map { i -> a.getJSONObject(i).let { s ->
                dev.repera.domain.PlannedSetValue(s.optInt("targetReps"),
                    if (s.has("targetWeightKg") && !s.isNull("targetWeightKg")) s.getDouble("targetWeightKg") else null,
                    if (s.has("targetRir") && !s.isNull("targetRir")) s.getDouble("targetRir") else null) } }
        })

    /** RoutineBlock.plannedSets(for:) de Apple para un movimiento sin series explícitas. */
    internal fun derivedSetsFor(block: JSONObject, movement: JSONObject): JSONArray = derivedSets(block, movement)

    private fun derivedSets(block: JSONObject, movement: JSONObject): JSONArray {
        val all = block.optJSONArray("movements") ?: JSONArray()
        val values = dev.repera.domain.WodPlannedSets.forMovement(
            dev.repera.domain.WodFormat.fromWire(block.optString("wodFormat")),
            if (block.has("rounds") && !block.isNull("rounds")) block.getInt("rounds") else null,
            (0 until all.length()).map { spec(all.getJSONObject(it)) }, spec(movement))
        return JSONArray().apply {
            values.forEach { v ->
                put(JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", v.targetReps)
                    .apply { v.targetWeightKg?.let { put("targetWeightKg", it) }; v.targetRir?.let { put("targetRir", it) } })
            }
        }
    }

    private fun newBlock(entry: JSONObject, id: String, kind: String, n: Int): JSONObject {
        val b = JSONObject().put("id", id)
            .put("title", entry.optString("blockHeader").ifBlank { "Bloque $n" })
            .put("kind", kind)
        entry.optString("wodFormat").takeIf { it.isNotBlank() }?.let { b.put("wodFormat", it) }
        val pairs = listOf("blockTimeCapMinutes" to "timeCapMinutes", "blockIntervalSeconds" to "emomIntervalSeconds",
            "blockRounds" to "rounds", "blockWorkSeconds" to "workSeconds", "blockRestSeconds" to "restSeconds",
            "blockRestBetweenRoundsSeconds" to "restBetweenRoundsSeconds")
        for ((from, to) in pairs) if (entry.has(from) && !entry.isNull(from)) b.put(to, entry.get(from))
        return b
    }

    private fun movementFor(entry: JSONObject, original: JSONObject?, preservePrescription: Boolean = false): JSONObject {
        val sets = if (preservePrescription)
            (original?.optJSONArray("explicitPlannedSets")?.takeIf { it.length() > 0 }
                ?: entry.optJSONArray("plannedSets") ?: JSONArray())
        else visibleSets(entry)
        val first = sets.optJSONObject(0)
        val unit = entry.optString("quantityUnit")
        val reps = first?.optInt("targetReps")
        val m = JSONObject().put("id", entry.getString("id"))
            .put("exerciseId", entry.getJSONObject("exercise").getString("id"))
            .put("name", entry.getJSONObject("exercise").optString("name"))
            .put("explicitPlannedSets", sets)
        if (reps != null) m.put("reps", reps)
        if (sets.length() > 1) m.put("repScheme", JSONArray((0 until sets.length()).map { sets.getJSONObject(it).optInt("targetReps") }))
        if (unit == "meters" && reps != null) m.put("distanceMeters", reps)
        if (unit == "calories" && reps != null) m.put("calories", reps)
        val w = original?.takeIf { it.has("weightMaleKg") && !it.isNull("weightMaleKg") }?.get("weightMaleKg")
            ?: first?.takeIf { it.has("targetWeightKg") && !it.isNull("targetWeightKg") }?.get("targetWeightKg")
        if (w != null) m.put("weightMaleKg", w)
        for (k in listOf("weightFemaleKg", "scaleAlternative", "notes"))
            if (original != null && original.has(k) && !original.isNull(k)) m.put(k, original.get(k))
        return m
    }

    /**
     * CompletedWorkoutEditing.applying(_:to:catalog:): devuelve una COPIA de la
     * sesión con el contenido del editor aplicado. Mantiene ids, tiempos, ruta,
     * Salud y técnicas de los ejercicios que sobreviven, incluso movidos de bloque.
     */
    fun applying(title: String, blocks: JSONArray, original: JSONObject, catalog: JSONArray): JSONObject {
        val updated = JSONObject(original.toString())
        updated.put("title", title)
        updated.put("routineBlocks", JSONArray(blocks.toString()))
        val unused = mutableListOf<JSONObject>().also { l ->
            val ex = original.optJSONArray("exercises") ?: JSONArray()
            for (i in 0 until ex.length()) l += JSONObject(ex.getJSONObject(i).toString())
        }
        val catalogById = (0 until catalog.length()).associate { catalog.getJSONObject(it).getString("id") to catalog.getJSONObject(it) }
        val output = JSONArray()
        val finishedAt = original.optString("finishedAt").ifBlank { null }

        for (b in 0 until blocks.length()) {
            val block = blocks.getJSONObject(b)
            val blockId = block.getString("id")
            val kind = block.optString("kind")
            data class Item(val id: String, val exerciseId: String?, val name: String?, val sets: JSONArray?, val unit: String?, val movement: JSONObject?)
            val items = mutableListOf<Item>()
            if (kind == "strength") {
                val ex = block.optJSONArray("exercises") ?: JSONArray()
                for (i in 0 until ex.length()) ex.getJSONObject(i).let {
                    items += Item(it.getString("id"), it.getString("exerciseId"), null,
                        it.optJSONArray("plannedSets") ?: JSONArray(), it.optString("quantityUnit").ifBlank { null }, null)
                }
            } else {
                val mv = block.optJSONArray("movements") ?: JSONArray()
                for (i in 0 until mv.length()) mv.getJSONObject(i).let {
                    if (it.optBoolean("isRest")) return@let
                    val explicit = it.optJSONArray("explicitPlannedSets")?.takeIf { s -> s.length() > 0 }
                    val derived = explicit ?: derivedSets(block, it)
                    items += Item(it.getString("id"), it.optString("exerciseId").ifBlank { null }, it.optString("name"),
                        derived, if (it.has("calories") && !it.isNull("calories")) "calories"
                        else if (it.has("distanceMeters") && !it.isNull("distanceMeters")) "meters" else null, it)
                }
            }
            for (item in items) {
                // ID de la sesión antes que nombre: distingue repetidos y arrastres entre bloques.
                val idx = unused.indexOfFirst { it.getString("id") == item.id }.takeIf { it >= 0 }
                    ?: unused.indexOfFirst {
                        it.optString("blockId") == blockId && (item.exerciseId == it.getJSONObject("exercise").optString("id") ||
                            (item.name != null && it.getJSONObject("exercise").optString("name").equals(item.name, ignoreCase = true)))
                    }.takeIf { it >= 0 }
                val old = idx?.let { unused.removeAt(it) }
                val exercise = item.exerciseId?.let { catalogById[it] }?.let { JSONObject(it.toString()) }
                    ?: old?.getJSONObject("exercise")
                    ?: JSONObject().put("id", UUID.randomUUID().toString()).put("name", item.name ?: "Ejercicio")
                        .put("muscleGroup", "Otros").put("isCustom", true)
                val sets = item.sets ?: old?.optJSONArray("plannedSets") ?: JSONArray()
                val entry = old ?: JSONObject().put("id", item.id).put("loggedSets", JSONArray())
                    .put("completedReps", 0).put("isCompleted", false)
                entry.put("exercise", exercise)
                entry.put("plannedSets", sets)
                if (item.unit != null) entry.put("quantityUnit", item.unit) else entry.remove("quantityUnit")
                entry.put("blockId", blockId).put("blockKind", kind).put("blockHeader", block.optString("title"))
                for (k in listOf("wodFormat")) if (block.has(k) && !block.isNull(k)) entry.put(k, block.get(k)) else entry.remove(k)
                val map = listOf("blockTimeCapMinutes" to "timeCapMinutes", "blockIntervalSeconds" to "emomIntervalSeconds",
                    "blockRounds" to "rounds", "blockWorkSeconds" to "workSeconds", "blockRestSeconds" to "restSeconds",
                    "blockRestBetweenRoundsSeconds" to "restBetweenRoundsSeconds")
                for ((to, from) in map) if (block.has(from) && !block.isNull(from)) entry.put(to, block.get(from)) else entry.remove(to)
                entry.remove("supersetGroup")
                // Sets completados: no se reconstruyen al editar la prescripción de un WOD con
                // resultado GLOBAL (dos hechos distintos que no se contaminan).
                val perMovement = !block.has("wodFormat") || block.isNull("wodFormat") || !isGlobalCapture(block)
                val oldLogged = old?.optJSONArray("loggedSets")
                if (old != null && oldLogged != null && oldLogged.length() > 0 && perMovement) {
                    val deficit = ExerciseInput.mode(exercise.optString("name"),
                        exercise.optString("equipment").takeIf { it.isNotBlank() },
                        exercise.optString("targetMuscle").takeIf { it.isNotBlank() },
                        exercise.optString("muscleGroup"), exercise.optString("sportTag")) == ExerciseInputMode.HSPU_DEFICIT
                    val rebuilt = JSONArray()
                    for (i in 0 until sets.length()) {
                        val set = sets.getJSONObject(i)
                        val prev = (0 until oldLogged.length()).map { oldLogged.getJSONObject(it) }
                            .firstOrNull { it.getString("id") == set.getString("id") }
                        // Apple: solo los UUID ya registrados son resultados; una serie nueva o sin confirmar
                        // NO se convierte en LoggedSet al guardar el editor.
                        if (prev == null) continue
                        val reps = maxOf(0, set.optInt("targetReps"))
                        val tw = if (set.has("targetWeightKg") && !set.isNull("targetWeightKg")) set.getDouble("targetWeightKg") else null
                        val rir = if (set.has("targetRir") && !set.isNull("targetRir")) set.getDouble("targetRir") else null
                        val ls = prev?.let { JSONObject(it.toString()) } ?: JSONObject().put("id", set.getString("id"))
                            .put("completedAt", finishedAt ?: java.time.Instant.now().toString())
                            .put("phase", "work").put("kind", "straight").put("toFailure", false)
                            .put("drops", JSONArray()).put("clusters", JSONArray())
                        ls.put("reps", reps)
                        if (deficit) { if (tw != null) ls.put("deficitCm", Math.round(tw).toInt()) else ls.remove("deficitCm"); ls.remove("weightKg") }
                        else { if (tw != null) ls.put("weightKg", tw) else ls.remove("weightKg"); ls.remove("deficitCm") }
                        if (set.has("targetDurationSeconds") && !set.isNull("targetDurationSeconds")) ls.put("durationSeconds", set.getInt("targetDurationSeconds")) else ls.remove("durationSeconds")
                        if (rir != null) ls.put("rir", rir) else ls.remove("rir")
                        if (prev != null) ls.put("toFailure", rir == 0.0 && prev.optBoolean("toFailure"))
                        // Apple f7109bd7 (editableSetRow): la unidad editada por
                        // serie manda sobre la del ejercicio y la previa.
                        val unit = set.optString("targetQuantityUnit")
                            .takeIf { it == "reps" || it == "meters" }
                            ?: item.unit ?: prev?.optString("quantityUnit")?.ifBlank { null }
                        if (unit != null) ls.put("quantityUnit", unit)
                        rebuilt.put(ls)
                    }
                    entry.put("loggedSets", rebuilt)
                    entry.put("completedReps", (0 until rebuilt.length()).sumOf { i ->
                        val l = rebuilt.getJSONObject(i)
                        if (l.optString("phase", "work") != "work") 0 else l.optInt("reps") +
                            (l.optJSONArray("drops")?.let { d -> (0 until d.length()).sumOf { d.getJSONObject(it).optInt("reps") } } ?: 0)
                    })
                }
                output.put(entry)
            }
        }
        updated.put("exercises", output)
        updated.put("currentIndex", if (output.length() == 0) 0 else minOf(original.optInt("currentIndex"), output.length() - 1))
        // wodResults (Apple, live main 26 Oct): cambiar el formato NO borra un resultado real; cada marca conserva su
        // formato y unidades; solo borrar el bloque borra su resultado. Nunca se convierten segundos en reps.
        val results = original.optJSONArray("wodResults") ?: JSONArray()
        val kept = JSONArray()
        for (i in 0 until results.length()) {
            val r = JSONObject(results.getJSONObject(i).toString())
            val block = (0 until blocks.length()).map { blocks.getJSONObject(it) }.firstOrNull { it.optString("id") == r.optString("id") } ?: continue
            val current = dev.repera.domain.WodFormat.fromWire(block.optString("wodFormat"))
            if (current == null) { kept.put(r); continue }
            if (r.optString("format").isBlank()) {
                val rb = original.optJSONArray("routineBlocks")
                val fromBlock = rb?.let { arr -> (0 until arr.length()).map { arr.getJSONObject(it) }.firstOrNull { it.optString("id") == r.optString("id") } }
                    ?.optString("wodFormat")?.takeIf { it.isNotBlank() }
                val ex = original.optJSONArray("exercises")
                val fromEx = ex?.let { arr -> (0 until arr.length()).map { arr.getJSONObject(it) }.firstOrNull { it.optString("blockId") == r.optString("id") } }
                    ?.optString("wodFormat")?.takeIf { it.isNotBlank() }
                (fromBlock ?: fromEx)?.let { r.put("format", it) }
            }
            val recorded = r.optString("format").takeIf { it.isNotBlank() }
            if (recorded != null && recorded != current.wireName) { kept.put(r); continue }
            val capture = current.capture.name
            if (capture == "ELAPSED_TIME" && !r.has("elapsedSeconds")) { kept.put(r); continue }
            if (capture == "TOTAL_REPS" && !r.has("totalReps") && !r.has("roundsCompleted")) { kept.put(r); continue }
            if (capture == "PER_MOVEMENT_SETS") { kept.put(r); continue }
            r.put("format", current.wireName)
            kept.put(r)
        }
        updated.put("wodResults", kept)
        return updated
    }
}
