package dev.repera.domain

/** Serie planificada sin identidad (los ids se asignan al materializar en JSON). */
data class PlannedSetValue(val targetReps: Int, val targetWeightKg: Double? = null, val targetRir: Double? = null)

/** Movimiento WOD (campos de prescripción de WODMovement.swift). */
data class WodMovementSpec(
    val id: String,
    val reps: Int? = null,
    val repScheme: List<Int>? = null,
    val distanceMeters: Int? = null,
    val calories: Int? = null,
    val weightMaleKg: Double? = null,
    val isRest: Boolean = false,
    val explicitPlannedSets: List<PlannedSetValue>? = null
)

/**
 * Port de WODMovement.plannedSetsFromReps / repeatingPlannedSets / plannedSetsPadded /
 * isAscendingRepRange y de RoutineBlock.plannedSets(for:) (Models.swift ReperaDomain).
 * Reglas Apple: las series editadas (explicit) mandan; después ola explícita (padded en
 * EMOM/circuit); después reglas por formato (EMOM/circuit repiten por rondas, Tabata
 * reparte ventanas de trabajo entre estaciones, For Time/RFQ repiten por rondas).
 */
object WodPlannedSets {
    fun isAscendingRepRange(scheme: List<Int>?): Boolean {
        if (scheme == null || scheme.size != 2) return false
        val lo = scheme[0]; val hi = scheme[1]
        return lo < hi && (hi - lo) <= 20
    }

    fun fromReps(m: WodMovementSpec): List<PlannedSetValue> {
        val weight = m.weightMaleKg
        val scheme = m.repScheme
        if (scheme != null && scheme.isNotEmpty() && !isAscendingRepRange(scheme))
            return scheme.map { PlannedSetValue(maxOf(1, it), weight) }
        val r = if (scheme != null && isAscendingRepRange(scheme)) scheme[1]
        else m.calories ?: m.distanceMeters ?: m.reps ?: 10
        return listOf(PlannedSetValue(maxOf(1, r), weight))
    }

    fun repeating(m: WodMovementSpec, count: Int): List<PlannedSetValue> {
        val base = fromReps(m)
        if (count <= 1 || base.size != 1) return base
        val t = base[0]
        return List(count) { PlannedSetValue(t.targetReps, t.targetWeightKg, t.targetRir) }
    }

    fun padded(m: WodMovementSpec, count: Int): List<PlannedSetValue> {
        val base = fromReps(m)
        if (count <= 0) return emptyList()
        if (base.isEmpty()) return List(count) { PlannedSetValue(m.reps ?: 10, m.weightMaleKg) }
        if (base.size >= count) return base.take(count)
        val last = base.last()
        return base + List(count - base.size) { PlannedSetValue(last.targetReps, last.targetWeightKg, last.targetRir) }
    }

    /** RoutineBlock.plannedSets(for:). `movements` = todos los movimientos del bloque (con REST). */
    fun forMovement(
        format: WodFormat?, rounds: Int?, movements: List<WodMovementSpec>, movement: WodMovementSpec
    ): List<PlannedSetValue> {
        if (movement.isRest) return emptyList()
        movement.explicitPlannedSets?.takeIf { it.isNotEmpty() }?.let { return it }
        val base = fromReps(movement)
        val emomRounds = maxOf(1, rounds ?: 1)
        val scheme = movement.repScheme
        if (scheme != null && scheme.isNotEmpty() && !isAscendingRepRange(scheme)) {
            return if (format == WodFormat.EMOM || format == WodFormat.CIRCUIT) padded(movement, emomRounds) else base
        }
        if (format == null) return base
        return when (format) {
            WodFormat.EMOM, WodFormat.CIRCUIT -> repeating(movement, emomRounds)
            WodFormat.TABATA -> {
                val workIntervals = maxOf(1, rounds ?: 8)
                val active = movements.filter { !it.isRest }
                val stationTotal = maxOf(1, active.size)
                val station = active.indexOfFirst { it.id == movement.id }.let { if (it < 0) 0 else it }
                val count = maxOf(0, (workIntervals + stationTotal - 1 - station) / stationTotal)
                if (count > 0) repeating(movement, count) else emptyList()
            }
            WodFormat.FOR_TIME, WodFormat.ROUNDS_FOR_QUALITY -> {
                val n = rounds
                if (n == null || n <= 1) base else repeating(movement, n)
            }
            else -> base
        }
    }
}
