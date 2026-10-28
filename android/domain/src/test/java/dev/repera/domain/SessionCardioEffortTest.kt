package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port de SessionCardioEffortTests.swift (iOS). */
class SessionCardioEffortTest {

    @Test fun hardEffortRaisesLowScore() {
        val sample = SessionCardioSample(
            averageHeartRateBpm = 165.0, maxHeartRateBpm = 185.0,
            durationMinutes = 20.0)
        val analyzed = SessionCardioEffort.analyze(sample)
        assertNotNull(analyzed)
        assertEquals(CardioEffortBand.HARD, analyzed!!.band)
        assertEquals(1, SessionCardioEffort.scoreDelta(5, analyzed))
    }

    @Test fun easyEffortLowersHighScore() {
        val sample = SessionCardioSample(
            averageHeartRateBpm = 105.0, maxHeartRateBpm = 120.0,
            durationMinutes = 40.0)
        val analyzed = SessionCardioEffort.analyze(sample)!!
        assertEquals(CardioEffortBand.EASY, analyzed.band)
        assertEquals(-2, SessionCardioEffort.scoreDelta(9, analyzed))
    }

    @Test fun applyUpdatesReviewText() {
        val base = SessionReview(
            overallScore = 5, level = AthleteLevel.INTERMEDIATE,
            headline = "Fran: Intermedio · 5/10",
            vsStandardSummary = "Tu tiempo fue 8:30.")
        val sample = SessionCardioSample(
            averageHeartRateBpm = 170.0, maxHeartRateBpm = 188.0,
            heartRateBpmSamples = List(20) { 172.0 }, durationMinutes = 9.0)
        val updated = SessionCardioEffort.apply(base, sample)
        assertTrue(updated.overallScore > base.overallScore)
        assertTrue(updated.vsStandardSummary!!.contains("FC media"))
        // Resumen previo conservado delante (iOS concatena).
        assertTrue(updated.vsStandardSummary!!.startsWith("Tu tiempo fue 8:30."))
        // Titular reescrito con la nueva nota.
        assertTrue(updated.headline.contains("${updated.overallScore}/10"))
    }

    @Test fun noSignalLeavesReviewUntouched() {
        val base = SessionReview(overallScore = 7, headline = "WOD · 7/10")
        val same = SessionCardioEffort.apply(base, SessionCardioSample())
        assertEquals(7, same.overallScore)
        assertEquals("WOD · 7/10", same.headline)
    }

    @Test fun kcalOnlySignalUsesDensity() {
        val analyzed = SessionCardioEffort.analyze(SessionCardioSample(
            activeEnergyKcal = 500.0, durationMinutes = 40.0))!!
        // 12.5 kcal/min ≥ 12 → intensidad 0.80 → HARD
        assertEquals(CardioEffortBand.HARD, analyzed.band)
        assertTrue(analyzed.summary.contains("kcal"))
    }
}
