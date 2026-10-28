package dev.repera.domain

import kotlin.math.abs

/**
 * Port 1:1 de [PlannedSet].compactSummary / compactRepsSummary (Models.swift Apple,
 * incl. 35be5a8d: rama de segundos de sosten). Formato de listas:
 * `3×8 · 60 kg`, `2×3, 2×1 · 150 kg`, `3 @ 100, 2 @ 110`, `3 reps · 30s`, `45s`.
 */
object PlannedSetSummary {

    private fun sameWeight(a: Double?, b: Double?): Boolean = when {
        a == null && b == null -> true
        a != null && b != null -> abs(a - b) < 0.05
        else -> false
    }

    private fun weightLabel(w: Double?): String =
        w?.let { "${ReperaNumberFormat.decimal(it)} kg" } ?: "—"

    fun compactSummary(sets: List<PlannedSet>): String {
        if (sets.isEmpty()) return "—"
        if (sets.any { it.targetDurationSeconds != null }) {
            return sets.joinToString(", ") { set ->
                val seconds = set.targetDurationSeconds?.let { "${it}s" } ?: "—"
                if (set.targetReps == 1) seconds else "${set.targetReps} reps · $seconds"
            }
        }
        if (sets.any { it.targetPercent1RM != null }) {
            val groups = mutableListOf<PercentGroup>()
            for (set in sets) {
                val last = groups.lastOrNull()
                if (last != null && last.reps == set.targetReps &&
                    last.percent == set.targetPercent1RM &&
                    last.isMinimum == set.targetPercent1RMIsMinimum) {
                    last.count += 1
                } else {
                    groups.add(PercentGroup(set.targetReps, set.targetPercent1RM,
                        set.targetPercent1RMIsMinimum, 1))
                }
            }
            return groups.joinToString(", ") { g ->
                val reps = if (g.count > 1) "${g.count}×${g.reps}" else "${g.reps}"
                reps + (g.percent?.let {
                    " @ ${if (g.isMinimum) ">" else ""}${ReperaNumberFormat.decimal(it)}% 1RM"
                } ?: "")
            }
        }
        val groups = mutableListOf<WeightGroup>()
        for (set in sets) {
            val last = groups.lastOrNull()
            if (last != null && last.reps == set.targetReps &&
                sameWeight(last.weight, set.targetWeightKg)) {
                last.count += 1
            } else {
                groups.add(WeightGroup(set.targetReps, set.targetWeightKg, 1))
            }
        }
        val allSameWeight = groups.all { sameWeight(it.weight, groups[0].weight) }
        if (allSameWeight) {
            val scheme = groups.joinToString(", ") { g ->
                if (g.count == 1) "${g.reps}" else "${g.count}×${g.reps}"
            }
            return "$scheme · ${weightLabel(groups[0].weight)}"
        }
        return groups.joinToString(", ") { g ->
            val repsPart = if (g.count == 1) "${g.reps}" else "${g.count}×${g.reps}"
            "$repsPart @ ${weightLabel(g.weight)}"
        }
    }

    private data class PercentGroup(val reps: Int, val percent: Double?, val isMinimum: Boolean, var count: Int)
    private data class WeightGroup(val reps: Int, val weight: Double?, var count: Int)

    /** Solo el esquema de series/reps (sin peso): `3×8` o `2×3, 2×1`. */
    fun compactRepsSummary(sets: List<PlannedSet>): String {
        if (sets.isEmpty()) return "—"
        data class Group(val reps: Int, var count: Int)
        val groups = mutableListOf<Group>()
        for (set in sets) {
            val last = groups.lastOrNull()
            if (last != null && last.reps == set.targetReps) last.count += 1
            else groups.add(Group(set.targetReps, 1))
        }
        return groups.joinToString(", ") { g ->
            if (g.count == 1) "${g.reps}" else "${g.count}×${g.reps}"
        }
    }
}
