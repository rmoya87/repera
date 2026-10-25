package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Operaciones puras sobre el borrador de bloques (JSON con ids) del editor de
 * entreno terminado. Port de PlanView.applyReorder / moveBlock /
 * WODMovementEditor.writeSetsToMovement. No tocan Apple.
 *
 * Reglas de conversión de Apple (replicadas, con pérdidas explícitas):
 *  - ejercicio → movimiento: conserva exerciseId, nombre, series (explicitPlannedSets),
 *    unidad (cal / m) y peso de la 1.ª serie; reps = 1.ª serie (8 si no hay).
 *  - movimiento → ejercicio: NO admite REST; conserva series y unidad; DESCARTA
 *    weightFemaleKg, scaleAlternative, notes y repScheme (Apple igual). [lostFieldsOnToStrength]
 */
object EditorBlockOps {

    /** Campos de un movimiento WOD que Apple pierde al pasarlo a fuerza. */
    val lostFieldsOnToStrength = listOf("weightFemaleKg", "scaleAlternative", "notes", "repScheme")

    private fun opt(o: JSONObject, k: String): Any? = if (o.has(k) && !o.isNull(k)) o.get(k) else null

    fun exerciseToMovement(item: JSONObject, name: String): JSONObject {
        val sets = item.optJSONArray("plannedSets") ?: JSONArray()
        val first = sets.optJSONObject(0)
        val reps = first?.optInt("targetReps") ?: 8
        val unit = item.optString("quantityUnit")
        val m = JSONObject().put("id", item.optString("id").ifBlank { UUID.randomUUID().toString() })
            .put("name", name).put("reps", reps)
            .put("explicitPlannedSets", JSONArray(sets.toString()))
        opt(item, "exerciseId")?.let { m.put("exerciseId", it) }
        if (unit == "meters") m.put("distanceMeters", reps)
        if (unit == "calories") m.put("calories", reps)
        first?.let { f -> opt(f, "targetWeightKg")?.let { m.put("weightMaleKg", it) } }
        return m
    }

    /** null si es REST (Apple no lo convierte). */
    fun movementToExercise(move: JSONObject, resolvedExerciseId: String): JSONObject? {
        if (move.optBoolean("isRest")) return null
        val sets = move.optJSONArray("explicitPlannedSets")?.takeIf { it.length() > 0 }
            ?: JSONArray().put(JSONObject().put("id", UUID.randomUUID().toString())
                .put("targetReps", move.optInt("reps", 10))
                .apply { opt(move, "weightMaleKg")?.let { put("targetWeightKg", it) } })
        val item = JSONObject().put("id", move.optString("id")).put("exerciseId", resolvedExerciseId)
            .put("plannedSets", JSONArray(sets.toString()))
        when {
            opt(move, "calories") != null -> item.put("quantityUnit", "calories")
            opt(move, "distanceMeters") != null -> item.put("quantityUnit", "meters")
        }
        return item
    }

    /** WODMovementEditor.writeSetsToMovement (sin machineWork: la unidad la da el movimiento). */
    fun writeSetsToMovement(movement: JSONObject, sets: JSONArray, machineWork: Boolean) {
        movement.put("explicitPlannedSets", sets)
        val reps = (0 until sets.length()).map { sets.getJSONObject(it).optInt("targetReps") }
        if (machineWork) {
            val qty = reps.firstOrNull()
            if (qty != null) when {
                opt(movement, "calories") != null -> { movement.put("calories", qty)
                    if (opt(movement, "distanceMeters") == null) movement.remove("reps") }
                opt(movement, "distanceMeters") != null -> { movement.put("distanceMeters", qty)
                    if (opt(movement, "calories") == null) movement.remove("reps") }
                else -> movement.put("reps", qty)
            }
            if (reps.size > 1) movement.put("repScheme", JSONArray(reps)) else movement.remove("repScheme")
        } else if (reps.size <= 1) {
            movement.remove("repScheme")
            reps.firstOrNull()?.let { movement.put("reps", it) } ?: movement.remove("reps")
        } else {
            movement.put("repScheme", JSONArray(reps)); movement.remove("reps")
        }
        for (i in 0 until sets.length()) opt(sets.getJSONObject(i), "targetWeightKg")?.let {
            movement.put("weightMaleKg", it); return
        }
    }

    fun restMovement(): JSONObject = JSONObject().put("id", UUID.randomUUID().toString())
        .put("name", "REST").put("isRest", true).put("restSeconds", 60)

    fun newBlock(kind: String, number: Int, wodFormat: String? = null): JSONObject {
        val b = JSONObject().put("id", UUID.randomUUID().toString())
            .put("title", "Bloque $number").put("kind", kind)
        if (kind == "strength") b.put("exercises", JSONArray()).put("movements", JSONArray())
        else { b.put("movements", JSONArray()).put("exercises", JSONArray()); wodFormat?.let { b.put("wodFormat", it) } }
        return b
    }

    fun removeBlock(blocks: JSONArray, index: Int) { if (index in 0 until blocks.length()) blocks.remove(index) }

    fun moveBlock(blocks: JSONArray, from: Int, to: Int): Boolean {
        if (from !in 0 until blocks.length() || to !in 0 until blocks.length() || from == to) return false
        val b = blocks.get(from); blocks.remove(from)
        val rest = (0 until blocks.length()).map { blocks.get(it) }.toMutableList()
        rest.add(to, b)
        for (i in rest.indices) blocks.put(i, rest[i])
        return true
    }

    /** Reordena dentro de un array: quita `from` e inserta en `to` (índice final). */
    fun reorder(arr: JSONArray, from: Int, to: Int): Boolean {
        if (from !in 0 until arr.length() || to !in 0 until arr.length() || from == to) return false
        val list = (0 until arr.length()).map { arr.get(it) }.toMutableList()
        list.add(to, list.removeAt(from))
        list.forEachIndexed { i, o -> arr.put(i, o) }
        return true
    }

    /** Plan: entrada de fuerza → movimiento WOD (explicitPlannedSets = series, como Apple). */
    fun planStrengthToMovement(itemId: String?, exerciseId: String, name: String,
                               sets: List<PlannedSetDraft>, unit: String): JSONObject {
        val item = JSONObject().put("id", itemId ?: UUID.randomUUID().toString()).put("exerciseId", exerciseId)
            .put("plannedSets", draftSetsToJson(sets))
        if (unit.isNotBlank()) item.put("quantityUnit", unit)
        return exerciseToMovement(item, name)
    }

    /** Plan: movimiento WOD → entrada de fuerza. Devuelve el ítem y los campos que Apple descarta y que tenían valor. */
    fun planMovementToStrength(move: JSONObject, exerciseId: String): Pair<JSONObject, List<String>> {
        val item = movementToExercise(move, exerciseId) ?: error("REST no se convierte")
        val lost = lostFieldsOnToStrength.filter { move.has(it) && !move.isNull(it) }
        return item to lost
    }

    fun draftSetsToJson(sets: List<PlannedSetDraft>): JSONArray = JSONArray().apply {
        sets.forEach { s ->
            put(JSONObject().put("id", s.id ?: UUID.randomUUID().toString()).put("targetReps", s.targetReps)
                .apply { s.targetWeightKg?.let { put("targetWeightKg", it) }; s.targetRir?.let { put("targetRir", it) } })
        }
    }

    fun jsonToDraftSets(a: JSONArray): List<PlannedSetDraft> = (0 until a.length()).map {
        val o = a.getJSONObject(it)
        PlannedSetDraft(o.optInt("targetReps", 8),
            if (o.has("targetWeightKg") && !o.isNull("targetWeightKg")) o.getDouble("targetWeightKg") else null,
            if (o.has("targetRir") && !o.isNull("targetRir")) o.getDouble("targetRir") else null,
            o.optString("id").ifBlank { null })
    }.ifEmpty { listOf(PlannedSetDraft(8)) }

    /**
     * Unidad de cardio (Picker "Unidad de cardio" de Apple): Calorías/Metros solo si el ejercicio admite ambas
     * (supportsCaloriesAndMeters); si no, la unidad por defecto. Sin elección explícita se conserva la de la
     * prescripción original (quantityUnit o calories/distanceMeters), no se pisa con la por defecto.
     */
    fun resolveQuantityUnit(name: String, equipment: String?, requested: String?, original: JSONObject?): String {
        // Reglas literales de Apple (AppleCardioUnits), no la heurística genérica de ExerciseInput.
        val default = if (dev.repera.domain.AppleCardioUnits.allowsCalorieOrDistanceToggle(name, equipment))
            dev.repera.domain.AppleCardioUnits.defaultQuantityUnit(name, equipment)
        else dev.repera.domain.ExerciseInput.defaultQuantityUnit(name, equipment)
        if (!dev.repera.domain.AppleCardioUnits.allowsCalorieOrDistanceToggle(name, equipment)) return default
        if (requested == "calories" || requested == "meters") return requested
        val fromJson = original?.optString("quantityUnit")?.takeIf { it == "calories" || it == "meters" }
        if (fromJson != null) return fromJson
        if (original != null && opt(original, "calories") != null) return "calories"
        if (original != null && opt(original, "distanceMeters") != null) return "meters"
        return default
    }

    /** duplicatingContent de Apple: ids nuevos en todo el árbol (bloque, ítems, series) y sin supersetGroup. */
    fun freshIds(json: String?): String? {
        if (json == null) return null
        fun walk(v: Any?) {
            when (v) {
                is JSONObject -> {
                    if (v.has("id")) v.put("id", UUID.randomUUID().toString())
                    v.remove("supersetGroup")
                    v.keys().asSequence().toList().forEach { walk(v.opt(it)) }
                }
                is JSONArray -> for (i in 0 until v.length()) walk(v.opt(i))
            }
        }
        return runCatching { JSONObject(json).also { walk(it) }.toString() }.getOrDefault(json)
    }

    /** Copia de un bloque de otra rutina con ids nuevos (Añadir rutina). */
    fun duplicateBlockInfo(b: RoutineBlockInfo): RoutineBlockInfo = b.copy(
        id = UUID.randomUUID().toString(), sourceJson = freshIds(b.sourceJson),
        entries = b.entries.map { e -> e.copy(id = UUID.randomUUID().toString(), sourceJson = freshIds(e.sourceJson),
            plannedSets = e.plannedSets?.map { it.copy(id = null) }) })

    /** WODTemplate.makeBlock: movimientos repetidos se mantienen; sin coincidencia de catálogo se conservan por nombre. */
    fun templateToBlockInfo(t: dev.repera.domain.WodTemplate, catalog: List<ExerciseEntry>): RoutineBlockInfo? {
        // Escalera con movimientos repetidos (21-15-9 + varios): el modelo de escalera del editor (un esquema por
        // bloque) no lo representa sin cambiar su semántica; se rechaza en vez de reinterpretarlo.
        if (t.format == dev.repera.domain.WodFormat.LADDER) return null
        val byName = catalog.associateBy { it.name.lowercase() }
        val entries = t.movements.map { m ->
            val ex = byName[m.name.lowercase()]
            val item = JSONObject().put("id", UUID.randomUUID().toString()).put("name", m.name).put("isRest", false)
            ex?.let { item.put("exerciseId", it.id) }
            m.reps?.let { item.put("reps", it) }; m.distanceMeters?.let { item.put("distanceMeters", it) }
            m.calories?.let { item.put("calories", it) }; m.weightMaleKg?.let { item.put("weightMaleKg", it) }
            m.weightFemaleKg?.let { item.put("weightFemaleKg", it) }; m.notes?.let { item.put("notes", it) }
            RoutineBlockEntryInfo(exerciseId = ex?.id ?: "", name = m.name,
                quantity = m.reps ?: m.calories ?: m.distanceMeters ?: 10, id = item.getString("id"), sourceJson = item.toString())
        }
        val block = JSONObject().put("id", UUID.randomUUID().toString()).put("title", t.name).put("kind", "wod")
            .put("wodFormat", t.format.wireName).put("emomIntervalSeconds", t.emomIntervalSeconds ?: 60)
            .put("wodTemplateId", t.id)
        t.notes?.let { block.put("wodNotes", it) }
        return RoutineBlockInfo(title = t.name, format = t.format.wireName,
            timeCapMinutes = t.timeCapMinutes ?: 12, rounds = t.rounds ?: 1, emomIntervalSeconds = t.emomIntervalSeconds ?: 60,
            workSeconds = t.workSeconds ?: 20, restSeconds = t.restSeconds ?: 10, entries = entries,
            id = block.getString("id"), sourceJson = block.toString())
    }

    const val PENDING_PREFIX = "pending:"

    /** Nombres de ejercicios personalizados aún no creados (WOD→fuerza sin catálogo). Solo borrador. */
    fun pendingCustomNames(blocks: JSONArray): List<String> {
        val out = linkedSetOf<String>()
        for (b in 0 until blocks.length()) {
            val ex = blocks.getJSONObject(b).optJSONArray("exercises") ?: continue
            for (i in 0 until ex.length()) {
                val id = ex.getJSONObject(i).optString("exerciseId")
                if (id.startsWith(PENDING_PREFIX)) out += id.removePrefix(PENDING_PREFIX)
            }
        }
        return out.toList()
    }

    /** Sustituye pending:<nombre> por el id real (mapa nombre→id). Devuelve una copia. */
    fun resolvePending(blocks: JSONArray, idByName: Map<String, String>): JSONArray {
        val copy = JSONArray(blocks.toString())
        for (b in 0 until copy.length()) {
            val ex = copy.getJSONObject(b).optJSONArray("exercises") ?: continue
            for (i in 0 until ex.length()) {
                val item = ex.getJSONObject(i)
                val id = item.optString("exerciseId")
                if (id.startsWith(PENDING_PREFIX))
                    item.put("exerciseId", idByName.getValue(id.removePrefix(PENDING_PREFIX)))
            }
        }
        return copy
    }

    /** Mueve (y convierte si cambia de tipo) el ítem `itemId` al bloque destino. Devuelve false si no procede. */
    fun moveItem(
        blocks: JSONArray, sourceBlock: Int, itemId: String, targetBlock: Int, beforeId: String?,
        nameFor: (String) -> String, resolveExerciseId: (JSONObject) -> String?
    ): Boolean {
        if (sourceBlock !in 0 until blocks.length() || targetBlock !in 0 until blocks.length()) return false
        val src = blocks.getJSONObject(sourceBlock); val dst = blocks.getJSONObject(targetBlock)
        val srcStrength = src.optString("kind") == "strength"; val dstStrength = dst.optString("kind") == "strength"
        val srcKey = if (srcStrength) "exercises" else "movements"
        val dstKey = if (dstStrength) "exercises" else "movements"
        val srcArr = src.optJSONArray(srcKey) ?: return false
        val dstArr = dst.optJSONArray(dstKey) ?: JSONArray().also { dst.put(dstKey, it) }
        val idx = (0 until srcArr.length()).firstOrNull { srcArr.getJSONObject(it).optString("id") == itemId } ?: return false
        if (sourceBlock == targetBlock && beforeId == itemId) return false
        val item = srcArr.getJSONObject(idx)
        val converted: JSONObject = when {
            srcStrength == dstStrength -> item
            srcStrength -> exerciseToMovement(item, nameFor(item.optString("exerciseId")))
            else -> {
                if (item.optBoolean("isRest")) return false
                val id = resolveExerciseId(item) ?: return false
                movementToExercise(item, id) ?: return false
            }
        }
        srcArr.remove(idx)
        val list = (0 until dstArr.length()).map { dstArr.get(it) }.toMutableList()
        val pos = beforeId?.let { b -> list.indexOfFirst { (it as JSONObject).optString("id") == b }.takeIf { it >= 0 } } ?: list.size
        list.add(pos, converted)
        while (dstArr.length() > 0) dstArr.remove(0)
        list.forEachIndexed { i, o -> dstArr.put(i, o) }
        return true
    }

    /** Bloque cuyo rango vertical (raíz) contiene `y`; null si cae fuera de todos (drop inválido). */
    fun dropBlockIndex(y: Float, bounds: List<Pair<Float, Float>?>): Int? =
        bounds.indices.firstOrNull { i -> bounds[i]?.let { y >= it.first && y <= it.second } == true }

    /** Id del primer ítem cuyo centro queda por debajo de `y` (insertar antes de él); null = al final. */
    fun dropBeforeId(y: Float, items: List<Pair<String, Pair<Float, Float>>>): String? =
        items.sortedBy { it.second.first }.firstOrNull { (it.second.first + it.second.second) / 2f > y }?.first
}

/** Geometría (coordenadas de raíz) registrada por el editor para resolver soltar entre bloques. */
internal class EditorGeometry {
    val blocks = mutableMapOf<Int, Pair<Float, Float>>()
    val items = mutableMapOf<Int, MutableMap<String, Pair<Float, Float>>>()
    fun blockBounds(count: Int): List<Pair<Float, Float>?> = (0 until count).map { blocks[it] }
}
