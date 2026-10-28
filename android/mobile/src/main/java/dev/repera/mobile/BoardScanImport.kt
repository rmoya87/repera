package dev.repera.mobile

import dev.repera.domain.RoutineBlock
import dev.repera.domain.RoutineBlockKind
import dev.repera.domain.WODMovement
import org.json.JSONArray
import org.json.JSONObject

/**
 * Convierte los bloques del escáner de pizarra (BoardScanLiteParser, dominio)
 * al JSON wire que consume iOS (Routine/RoutineBlock Codable). Sin pérdida:
 * conserva pesos H/M, ondas, notas, escalados, RIR/% de las series y descansos.
 */
object BoardScanImport {

    fun wireMovement(move: WODMovement): JSONObject {
        val item = JSONObject()
            .put("id", move.id)
            .put("name", move.name)
            .put("isRest", move.isRest)
        move.exerciseId?.let { item.put("exerciseId", it) }
        move.reps?.let { item.put("reps", it) }
        move.repScheme?.let { scheme ->
            item.put("repScheme", JSONArray().apply { scheme.forEach { put(it) } })
        }
        move.distanceMeters?.let { item.put("distanceMeters", it) }
        move.calories?.let { item.put("calories", it) }
        move.weightMaleKg?.let { item.put("weightMaleKg", it) }
        move.weightFemaleKg?.let { item.put("weightFemaleKg", it) }
        move.restSeconds?.let { item.put("restSeconds", it) }
        move.scaleAlternative?.let { item.put("scaleAlternative", it) }
        move.notes?.let { item.put("notes", it) }
        move.explicitPlannedSets?.let { sets ->
            item.put("explicitPlannedSets", JSONArray().apply {
                sets.forEach { put(wirePlannedSet(it)) }
            })
        }
        return item
    }

    fun wirePlannedSet(set: dev.repera.domain.PlannedSet): JSONObject {
        val item = JSONObject()
            .put("id", set.id)
            .put("targetReps", set.targetReps)
        set.targetDurationSeconds?.let { item.put("targetDurationSeconds", it) }
        set.targetWeightKg?.let { item.put("targetWeightKg", it) }
        set.targetRir?.let { item.put("targetRir", it) }
        set.targetPercent1RM?.let { item.put("targetPercent1RM", it) }
        if (set.targetPercent1RMIsMinimum) item.put("targetPercent1RMIsMinimum", true)
        return item
    }

    fun wireBlock(block: RoutineBlock): JSONObject {
        val item = JSONObject()
            .put("id", block.id)
            .put("title", block.title)
            .put("kind", if (block.kind == RoutineBlockKind.STRENGTH) "strength" else "wod")
        if (block.kind == RoutineBlockKind.STRENGTH) {
            item.put("exercises", JSONArray().apply {
                block.exercises.forEach { ex ->
                    val e = JSONObject()
                        .put("id", ex.id)
                        .put("exerciseId", ex.exerciseId)
                        .put("plannedSets", JSONArray().apply {
                            ex.plannedSets.forEach { put(wirePlannedSet(it)) }
                        })
                    ex.restSeconds?.let { e.put("restSeconds", it) }
                    put(e)
                }
            })
        } else {
            item.put("movements", JSONArray().apply {
                block.movements.forEach { put(wireMovement(it)) }
            })
            block.wodFormat?.let { item.put("wodFormat", it.raw) }
        }
        block.timeCapMinutes?.let { item.put("timeCapMinutes", it) }
        block.emomIntervalSeconds?.let { item.put("emomIntervalSeconds", it) }
        block.rounds?.let { item.put("rounds", it) }
        block.workSeconds?.let { item.put("workSeconds", it) }
        block.restSeconds?.let { item.put("restSeconds", it) }
        block.restBetweenRoundsSeconds?.let { item.put("restBetweenRoundsSeconds", it) }
        block.wodNotes?.let { item.put("wodNotes", it) }
        return item
    }
}
