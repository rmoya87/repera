package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Apple uniqueExternalActivities, parte de solapamiento con sesiones nativas. JVM only (no E2E con Health Connect). */
class NativeOverlapDedupTest {
    private val w = StatsWorkout(1_000_000L, 30.0, true, liveSportID = "running")
    private fun a(type: String, start: Long, min: Double) = HealthMuscleMapper.ExternalActivity(start, type, min)

    @Test fun sameTypeCloseStartAndDurationIsDropped() {
        val kept = HealthMuscleMapper.dropNativeOverlaps(listOf(
            a("running", 1_000_000L + 89_000L, 32.9),
            a("running", 1_000_000L + 90_000L, 30.0),
            a("running", 1_000_000L, 33.0),
            a("cycling", 1_000_000L, 30.0)), listOf(w))
        assertEquals(listOf(90_000L + 1_000_000L, 1_000_000L, 1_000_000L), kept.map { it.epochMillis })
        assertEquals(listOf("running", "running", "cycling"), kept.map { it.type })
    }

    @Test fun unfinishedOrClassicSessionsDropNothing() {
        val list = listOf(a("running", 1_000_000L, 30.0))
        assertEquals(list, HealthMuscleMapper.dropNativeOverlaps(list, listOf(w.copy(finished = false))))
        assertEquals(list, HealthMuscleMapper.dropNativeOverlaps(list, listOf(w.copy(liveSportID = null))))
    }
}
