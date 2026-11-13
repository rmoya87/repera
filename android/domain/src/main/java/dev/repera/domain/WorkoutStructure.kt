package dev.repera.domain

import java.util.UUID

/** Opt-in structure that augments the existing WodFormat, never replaces it. */
enum class WorkoutSection { warmUp, strength, skill, metcon, accessory, coolDown }
enum class WorkoutCollaboration { solo, youGoIGo, synchronized, sharedReps, together }
enum class WorkoutResultMetric { elapsedSeconds, totalReps, loadKg, calories, distanceMeters, rounds, perMovementSets }
enum class WorkoutPhaseKind { work, rest, buyIn, main, cashOut }

enum class WorkoutSetMethod { standard, superset, triset, giantSet, cluster, dropSet, restPause, tempo, isometric }

data class WorkoutStrengthTechnique(
    val method: WorkoutSetMethod,
    val tempo: String? = null,
    val pauseSeconds: Int? = null,
    val intraSetRestSeconds: Int? = null,
    val clusterReps: Int? = null,
    val dropPercentages: List<Double> = emptyList()
) {
    val isValid: Boolean get() =
        (tempo == null || Regex("""^[0-9Xx]{4}$""").matches(tempo)) &&
        (pauseSeconds == null || pauseSeconds in 0..300) &&
        (intraSetRestSeconds == null || intraSetRestSeconds in 0..300) &&
        (clusterReps == null || clusterReps in 1..100) &&
        dropPercentages.size <= 8 && dropPercentages.all {it.isFinite() && it in 0.0..100.0}
}

data class WorkoutPhaseResult(
    val id: String = UUID.randomUUID().toString(),
    val phaseID: String,
    val iteration: Int,
    val participantIndex: Int? = null,
    val movementID: String? = null,
    val completedReps: Int? = null,
    val roundsCompleted: Int? = null,
    val elapsedSeconds: Int? = null,
    val measuredValue: Double? = null,
    val measuredMetric: WorkoutResultMetric? = null,
    val notes: String? = null
) {
    val isValid: Boolean get() = iteration in 1..200 &&
        (participantIndex == null || participantIndex in 1..2) &&
        (completedReps == null || completedReps in 0..100000) &&
        (roundsCompleted == null || roundsCompleted in 0..10000) &&
        (elapsedSeconds == null || elapsedSeconds in 0..86400) &&
        (measuredValue == null || (measuredValue.isFinite() && measuredValue in 0.0..1000000.0 && measuredMetric != null))
}

data class WorkoutPhase(
    val id: String = UUID.randomUUID().toString(),
    val kind: WorkoutPhaseKind,
    val title: String,
    val movementIDs: List<String> = emptyList(),
    val repeatCount: Int? = null,
    val workSeconds: Int? = null,
    val restSeconds: Int? = null,
    val notes: String? = null,
    val technique: WorkoutStrengthTechnique? = null,
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
        val available=(block.movements.map { it.id }+block.exercises.map { it.id }).toSet()
        fun collect(nodes:List<WorkoutPhase>):Set<String> =
            nodes.flatMap { phase -> phase.movementIDs + collect(phase.children) }
                .filter { it in available }.toSet()
        return collect(phases)
    }
    val summary: String get() =
        (listOfNotNull(section?.name, collaboration?.name) + phases.map {it.title}.filter {it.isNotBlank()})
            .joinToString(" · ")
}
