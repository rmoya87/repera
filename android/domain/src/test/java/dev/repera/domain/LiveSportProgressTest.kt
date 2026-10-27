package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Port 1:1 de LiveSportProgressTests.swift (referencia Apple 5890215d).
 * Un registro de Comenzar no contiene series, pero algunos deportes
 * representan tiempo cardio real: entran en Progreso sin inventar
 * kcal, FC ni carga muscular.
 */
class LiveSportProgressTest {
    private val zone: ZoneId = ZoneId.of("UTC")
    private val now: LocalDate = LocalDate.of(2026, 9, 13) // 1_790_000_000 aprox.
    private val nowMillis: Long = Instant.parse("2026-09-13T12:00:00Z").toEpochMilli()

    private fun activity(
        sportID: String,
        durationSeconds: Double = 1800.0
    ) = StatsWorkout(
        epochMillis = nowMillis,
        durationMinutes = durationSeconds / 60.0,
        finished = true,
        activeEnergyKcal = null,
        exercises = emptyList(),
        liveSportID = sportID
    )

    @Test fun runningWithoutIndividualExercisesCountsAsCardioAndTraining() {
        val run = activity("running")
        assertTrue(run.exercises.isEmpty())
        assertTrue(StatsEngine.isCardioWorkout(run))
        val summary = StatsEngine.progressHealthSummary(
            workouts = listOf(run), range = ProgressTimeRange.TODAY, now = now, zone = zone)
        assertEquals(1, summary.sessionCount)
        assertEquals(30.0, summary.averageMinutes!!, 0.001)
        assertEquals(30.0, summary.averageCardioMinutes!!, 0.001)
        assertEquals(0.0, summary.totalKcal, 0.001) // No inventar sensores.
        val series = StatsEngine.dailyMetricSeries(
            workouts = listOf(run), metric = "cardioMinutes",
            range = ProgressTimeRange.TODAY, now = now, zone = zone)
        assertEquals(30.0, series.sumOf { it.value }, 0.001)
    }

    @Test fun indoorStrengthDoesNotBecomeCardioArtificially() {
        val strength = activity("strength")
        assertFalse(StatsEngine.isCardioWorkout(strength))
        val summary = StatsEngine.progressHealthSummary(
            workouts = listOf(strength), range = ProgressTimeRange.TODAY, now = now, zone = zone)
        assertEquals(1, summary.sessionCount)
        assertEquals(30.0, summary.averageMinutes!!, 0.001)
        assertNull(summary.averageCardioMinutes)
    }

    @Test fun outdoorSportsCountInCardioMinutes() {
        for (sport in listOf("running", "cycling", "walking", "hiking", "trail",
            "mountainBike", "gravel", "tennis", "padel", "surfing",
            "swimming", "skiing", "hiit", "hyrox")) {
            assertTrue("Falta cardio para $sport", StatsEngine.isCardioWorkout(activity(sport)))
        }
    }

    @Test fun newWaterWinterTeamAndOtherSportsContributeCardioMinutes() {
        val sports = listOf(
            "windsurfing", "kitesurfing", "kayaking", "rowing", "canoeing",
            "sailing", "iceSkating", "snowboarding", "crossCountrySkiing",
            "soccer", "basketball", "volleyball", "climbing", "dance",
            "skateboarding")
        for (sport in sports) {
            val item = activity(sport, durationSeconds = 1200.0)
            assertTrue("Falta cardio para $sport", StatsEngine.isCardioWorkout(item))
            val summary = StatsEngine.progressHealthSummary(
                workouts = listOf(item), range = ProgressTimeRange.TODAY, now = now, zone = zone)
            assertEquals(20.0, summary.averageCardioMinutes!!, 0.001)
            assertEquals(0.0, summary.totalKcal, 0.001) // Salud no aportó sensores.
        }
    }

    @Test fun pilatesDoesNotInventDistanceOrCardioLoad() {
        val item = activity("pilates", durationSeconds = 2400.0)
        assertFalse(StatsEngine.isCardioWorkout(item))
        assertNull(item.activeEnergyKcal)
    }

    @Test fun catalogKeepsAllPersistedIdsAndGroups() {
        // IDs persistidos de Apple: 53 deportes (live main), 10 grupos, orden conservado.
        assertEquals(53, LiveSport.entries.size)
        assertEquals(10, LiveSport.groups.size)
        for (sport in LiveSport.entries) {
            assertEquals(sport, LiveSport.byId(sport.id))
            assertTrue(LiveSport.groups.contains(sport.group))
        }
        // El set cardio de Apple (live main) tiene 45 deportes: ni golf, ni fuerza, ni pilates.
        assertEquals(45, LiveSport.cardioLiveSports.size)
        assertFalse(LiveSport.cardioLiveSports.contains("golf"))
        assertFalse(LiveSport.cardioLiveSports.contains("strength"))
        assertFalse(LiveSport.cardioLiveSports.contains("pilates"))
    }
}
