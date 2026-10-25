package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Contrato de LiveSportHistoryView/LiveSportEvolutionView (Apple 5890215d):
 *  agregados solo con métricas medidas; nunca se fabrican kcal/pulso/distancia. */
class LiveSportHistoryTest {

    private fun session(
        sport: String, duration: Double? = 1800.0, meters: Double? = null,
        kcal: Double? = null, bpm: Double? = null, route: String? = null,
        finished: Boolean = true
    ) = LiveSportHistory.LiveSession(
        id = java.util.UUID.randomUUID().toString(), title = sport,
        sportID = sport,
        startedEpochMillis = 1_790_000_000_000L,
        finishedEpochMillis = if (finished) 1_790_001_800_000L else null,
        activeDurationSeconds = duration, recordedDistanceMeters = meters,
        averageHeartRateBpm = bpm, activeEnergyKcal = kcal, liveRouteID = route)

    @Test fun durationFormatMatchesApple() {
        assertEquals("30:00", LiveSportHistory.formatDuration(1800.0))
        assertEquals("1:30:00", LiveSportHistory.formatDuration(5400.0))
        assertEquals("00:00", LiveSportHistory.formatDuration(-5.0))
        assertEquals("09:05", LiveSportHistory.formatDuration(545.0))
    }

    @Test fun gpsSportSummarizesKilometers() {
        val sessions = listOf(
            session("running", 1800.0, 5000.0),
            session("running", 1200.0, 3700.0),
            session("cycling", 3600.0, 20000.0))
        val s = LiveSportHistory.summary(LiveSport.RUNNING, sessions)
        assertEquals(2, s.activityCount)
        assertEquals(8.7, s.totalKilometers, 0.001)
        assertEquals(3000.0, s.totalDurationSeconds, 0.001)
        assertEquals("2 actividades · 8.7 km",
            LiveSportHistory.activitySummaryLine(LiveSport.RUNNING, sessions))
    }

    @Test fun indoorSportSummarizesDurationWithoutInventingDistance() {
        val sessions = listOf(session("padel", 3000.0), session("padel", 2400.0))
        val s = LiveSportHistory.summary(LiveSport.PADEL, sessions)
        assertEquals(2, s.activityCount)
        assertEquals(0.0, s.totalKilometers, 0.001)
        assertEquals("2 actividades · 1:30:00",
            LiveSportHistory.activitySummaryLine(LiveSport.PADEL, sessions))
    }

    @Test fun measuredEnergyAndHeartRateOnlyWhenPresent() {
        val none = LiveSportHistory.summary(LiveSport.RUNNING,
            listOf(session("running", 1800.0, 5000.0)))
        assertNull(none.measuredEnergyKcal)
        assertNull(none.measuredHeartRateBpm)
        val measured = LiveSportHistory.summary(LiveSport.RUNNING, listOf(
            session("running", 1800.0, 5000.0, kcal = 320.0, bpm = 150.0),
            session("running", 1800.0, 5000.0, kcal = null, bpm = 170.0)))
        assertEquals(320.0, measured.measuredEnergyKcal!!, 0.001)
        assertEquals(160.0, measured.measuredHeartRateBpm!!, 0.001)
    }

    @Test fun unfinishedSessionsNeverAppear() {
        val sessions = listOf(session("running", finished = false))
        assertTrue(LiveSportHistory.sportsWithActivity(sessions).isEmpty())
        assertTrue(LiveSportHistory.sessionsOf(LiveSport.RUNNING, sessions).isEmpty())
    }

    @Test fun eligibilityKeepsOnlyCompleteAttemptsWithinTwentyPercent() {
        val attempts = listOf(
            session("running", 1800.0, 5000.0, route = "r1"),   // 5,0 km: dentro
            session("running", 900.0, 2500.0, route = "r1"),    // 2,5 km: cortada
            session("running", 3600.0, 7000.0, route = "r1"),   // 7,0 km: fuera (+40%)
            session("running", 1900.0, 5900.0, route = "r1"))   // 5,9 km: dentro (+18%)
        val eligible = LiveSportHistory.eligibleAttempts(attempts, 5.0)
        assertEquals(2, eligible.size)
        // Ruta desconocida (<0,2 km): entra cualquier intento con distancia.
        assertEquals(4, LiveSportHistory.eligibleAttempts(attempts, 0.0).size)
    }

    @Test fun evolutionValueUsesPaceOrSpeedBySport() {
        val run = session("running", 1800.0, 5000.0)
        assertEquals(1800.0,
            LiveSportHistory.evolutionValue(run,
                LiveSportHistory.EvolutionMetric.DURATION, LiveSport.RUNNING)!!, 0.001)
        assertEquals(6.0, // 30 min / 5 km = 6 min/km
            LiveSportHistory.evolutionValue(run,
                LiveSportHistory.EvolutionMetric.PACE, LiveSport.RUNNING)!!, 0.001)
        assertEquals(10.0, // 5 km / 0,5 h = 10 km/h
            LiveSportHistory.evolutionValue(run,
                LiveSportHistory.EvolutionMetric.PACE, LiveSport.CYCLING)!!, 0.001)
        assertNull(LiveSportHistory.evolutionValue(
            session("running", 1800.0, null),
            LiveSportHistory.EvolutionMetric.PACE, LiveSport.RUNNING))
    }

    @Test fun routeDistanceUsesHaversine() {
        // 1 grado de latitud ~= 111,19 km.
        val points = listOf(
            CardioRouteAnalysis.Sample(0.0, 40.0, -3.0),
            CardioRouteAnalysis.Sample(60.0, 41.0, -3.0))
        val km = CardioRouteAnalysis.routeDistanceMeters(points) / 1000.0
        assertEquals(111.19, km, 0.5)
        assertEquals(0.0, CardioRouteAnalysis.routeDistanceMeters(points.take(1)), 0.001)
    }
}
