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
 *  - bloques WOD: se conservan tal cual (Android no tiene editor de movimientos);
 *    las entradas WOD se reasignan por id/bloque con las reglas de Apple y los
 *    wodResults se validan contra el formato (un cambio de formato los invalida).
 *  - DESVIACIÓN: Block.plannedSets(for:) de Apple (rellenos EMOM/Tabata/rondas)
 *    no está portado; para un movimiento WOD sin explicitPlannedSets se conservan
 *    las series previas de la sesión.
 */
object CompletedWorkoutEditing {

    /** Series visibles: las registradas si existen; si no, las planificadas. */
    private fun visibleSets(entry: JSONObject): JSONArray {
        val logged = entry.optJSONArray("loggedSets")
        if (logged == null || logged.length() == 0)
            return entry.optJSONArray("plannedSets") ?: JSONArray()
        val out = JSONArray()
        for (i in 0 until logged.length()) {
            val l = logged.getJSONObject(i)
            val p = JSONObject().put("id", l.getString("id")).put("targetReps", l.optInt("reps"))
            val w = if (l.has("deficitCm") && !l.isNull("deficitCm")) l.getInt("deficitCm").toDouble()
            else if (l.has("weightKg") && !l.isNull("weightKg")) l.getDouble("weightKg") else null
            if (w != null) p.put("targetWeightKg", w)
            if (l.has("rir") && !l.isNull("rir")) p.put("targetRir", l.getDouble("rir"))
            out.put(p)
        }
        return out
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
            // Bloques WOD: se conservan (sin editor de movimientos en Android).
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
                    .put("exercises", JSONArray().put(item)).put("movements", JSONArray()))
            } else {
                val mv = movementFor(entry, null)
                if (idx != null) {
                    val b = blocks.getJSONObject(idx)
                    b.put("movements", (b.optJSONArray("movements") ?: JSONArray()).put(mv))
                } else blocks.put(newBlock(entry, blockId, "wod", blocks.length() + 1)
                    .put("movements", JSONArray().put(mv)).put("exercises", JSONArray()))
            }
        }
        return blocks
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

    private fun movementFor(entry: JSONObject, original: JSONObject?): JSONObject {
        val sets = visibleSets(entry)
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
                    items += Item(it.getString("id"), it.optString("exerciseId").ifBlank { null }, it.optString("name"),
                        explicit, if (it.has("calories") && !it.isNull("calories")) "calories"
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
                        val reps = maxOf(0, set.optInt("targetReps"))
                        val tw = if (set.has("targetWeightKg") && !set.isNull("targetWeightKg")) set.getDouble("targetWeightKg") else null
                        val rir = if (set.has("targetRir") && !set.isNull("targetRir")) set.getDouble("targetRir") else null
                        val ls = prev?.let { JSONObject(it.toString()) } ?: JSONObject().put("id", set.getString("id"))
                            .put("completedAt", finishedAt ?: java.time.Instant.now().toString())
                            .put("phase", "work").put("kind", "straight").put("toFailure", false)
                            .put("drops", JSONArray()).put("clusters", JSONArray())
                        ls.put("reps", reps)
                        if (deficit) { if (tw != null) ls.put("deficitCm", Math.round(tw).toInt()) else ls.remove("deficitCm"); ls.remove("weightKg") }
                        else { if (tw != null) ls.put("weightKg", tw) else ls.remove("weightKg") }
                        if (rir != null) ls.put("rir", rir) else ls.remove("rir")
                        if (prev != null) ls.put("toFailure", rir == 0.0 && prev.optBoolean("toFailure"))
                        val unit = item.unit ?: prev?.optString("quantityUnit")?.ifBlank { null }
                        if (unit != null) ls.put("quantityUnit", unit)
                        rebuilt.put(ls)
                    }
                    entry.put("loggedSets", rebuilt)
                    entry.put("completedReps", (0 until rebuilt.length()).sumOf { i ->
                        val l = rebuilt.getJSONObject(i)
                        if (l.optString("phase") == "warmup") 0 else l.optInt("reps") +
                            (l.optJSONArray("drops")?.let { d -> (0 until d.length()).sumOf { d.getJSONObject(it).optInt("reps") } } ?: 0)
                    })
                }
                output.put(entry)
            }
        }
        updated.put("exercises", output)
        updated.put("currentIndex", if (output.length() == 0) 0 else minOf(original.optInt("currentIndex"), output.length() - 1))
        // wodResults: solo los de bloques con captura global y mismo formato.
        val results = original.optJSONArray("wodResults") ?: JSONArray()
        val kept = JSONArray()
        for (i in 0 until results.length()) {
            val r = JSONObject(results.getJSONObject(i).toString())
            val block = (0 until blocks.length()).map { blocks.getJSONObject(it) }.firstOrNull { it.optString("id") == r.optString("id") } ?: continue
            val format = dev.repera.domain.WodFormat.fromWire(block.optString("wodFormat")) ?: continue
            if (!isGlobalCapture(block)) continue
            val rf = r.optString("format").ifBlank { null }
            if (rf != null && rf != format.wireName) continue
            r.put("format", format.wireName)
            when (captureOf(block)) {
                "TOTAL_REPS" -> {
                    if (!r.has("totalReps") && !r.has("roundsCompleted")) continue
                    r.remove("elapsedSeconds")
                    if (format != dev.repera.domain.WodFormat.AMRAP && format != dev.repera.domain.WodFormat.DEATH_BY) r.remove("roundsCompleted")
                }
                "ELAPSED_TIME" -> {
                    if (!r.has("elapsedSeconds")) continue
                    r.remove("roundsCompleted"); r.remove("totalReps")
                }
                else -> continue
            }
            kept.put(r)
        }
        updated.put("wodResults", kept)
        return updated
    }
}
