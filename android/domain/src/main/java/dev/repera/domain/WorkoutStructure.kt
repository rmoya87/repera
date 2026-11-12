package dev.repera.domain

import java.util.UUID

/** Opt-in structure that augments the existing WodFormat, never replaces it. */
enum class WorkoutSection { warmUp, strength, skill, metcon, accessory, coolDown }
enum class WorkoutCollaboration { solo, youGoIGo, synchronized, sharedReps, together }
enum class WorkoutResultMetric { elapsedSeconds, totalReps, loadKg, calories, distanceMeters, rounds, perMovementSets }
enum class WorkoutPhaseKind { work, rest, buyIn, main, cashOut }

data class WorkoutPhase(
    val id: String = UUID.randomUUID().toString(),
    val kind: WorkoutPhaseKind,
    val title: String,
    val movementIDs: List<String> = emptyList(),
    val repeatCount: Int? = null,
    val workSeconds: Int? = null,
    val restSeconds: Int? = null,
    val notes: String? = null,
    val children: List<WorkoutPhase> = emptyList()
)

data class WorkoutStructure(
    val version: Int = 1,
    val section: WorkoutSection? = null,
    val collaboration: WorkoutCollaboration? = null,
    val resultMetric: WorkoutResultMetric? = null,
    val phases: List<WorkoutPhase> = emptyList()
) {
    /** Ignore dangling references after Create/Edit remove or reorder. */
    fun activeMovementIDs(block: RoutineBlock): Set<String> {
        val available=block.movements.map { it.id }.toSet()
        fun collect(nodes:List<WorkoutPhase>):Set<String> =
            nodes.flatMap { phase -> phase.movementIDs + collect(phase.children) }
                .filter { it in available }.toSet()
        return collect(phases)
    }
    val summary: String get() =
        (listOfNotNull(section?.name, collaboration?.name) + phases.map {it.title}.filter {it.isNotBlank()})
            .joinToString(" · ")
}
