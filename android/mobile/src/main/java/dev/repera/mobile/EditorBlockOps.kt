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
}
