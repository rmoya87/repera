package dev.repera.domain

import java.util.UUID

/** Mirrors iPhone/Watch planned work-set progression and logged-set identity. */
data class PrescribedSet(
    val quantity: Int,
    val weightKg: Double? = null,
    val rir: Double? = null
)

enum class SetPhase { WARMUP, WORK }

data class RecordedSet(
    val id: String = UUID.randomUUID().toString(),
    val quantity: Int,
    val weightKg: Double?,
    val phase: SetPhase = SetPhase.WORK,
    val completedAtMillis: Long
)

object SetPrescription {
    fun nextWorkSet(plan: List<PrescribedSet>, logged: List<RecordedSet>): PrescribedSet? {
        val completedWork = logged.count { it.phase == SetPhase.WORK }
        return plan.drop(completedWork).firstOrNull() ?: plan.lastOrNull()
    }

    /** Replaces an existing set, never appends a duplicate on edit. */
    fun replaceLoggedSet(
        logged: List<RecordedSet>,
        edited: RecordedSet
    ): List<RecordedSet>? {
        val index = logged.indexOfFirst { it.id == edited.id }
        if (index == -1) return null
        return logged.toMutableList().apply { this[index] = edited }
    }

    fun completedWorkReps(logged: List<RecordedSet>): Int =
        logged.filter { it.phase == SetPhase.WORK }.sumOf { it.quantity.coerceAtLeast(0) }
}
