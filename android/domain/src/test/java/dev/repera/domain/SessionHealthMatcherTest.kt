package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionHealthMatcherTest {

    private val own = "dev.repera"
    private fun candidate(id: String, startMin: Long, endMin: Long, pkg: String) =
        SessionHealthMatcher.CandidateSession(id, startMin * 60_000, endMin * 60_000, pkg)
    private fun hr(tSec: Long, bpm: Int, pkg: String) =
        SessionHealthMatcher.HeartSample(tSec * 1_000, bpm, pkg)

    // Sesión Repera de 60 min: 10:00-11:00.
    private val sStart = 10 * 60 * 60_000L
    private val sEnd = 11 * 60 * 60_000L

    @Test fun singleExternalCandidateWithStrongOverlapMatches() {
        val result = SessionHealthMatcher.associate(
            sStart, sEnd,
            listOf(candidate("w1", 602, 658, "com.garmin.android")),
            own
        )
        assertEquals("w1", (result as SessionHealthMatcher.Association.Matched).session.id)
    }

    @Test fun twoExternalCandidatesWithSimilarOverlapAreAmbiguous() {
        val result = SessionHealthMatcher.associate(
            sStart, sEnd,
            listOf(
                candidate("w1", 600, 660, "com.garmin.android"),
                candidate("w2", 601, 659, "com.strava")
            ),
            own
        )
        assertEquals(SessionHealthMatcher.Association.Ambiguous, result)
    }

    @Test fun dominantCandidateWinsWhenSecondIsClearlyWeaker() {
        val result = SessionHealthMatcher.associate(
            sStart, sEnd,
            listOf(
                candidate("w1", 600, 660, "com.garmin.android"),   // 60 min
                candidate("w2", 600, 648, "com.strava")            // 48 min < 85% de 60
            ),
            own
        )
        assertEquals("w1", (result as SessionHealthMatcher.Association.Matched).session.id)
    }

    @Test fun briefCandidateCoveringLittleOfSessionDoesNotMatch() {
        // Un entreno de 10 min dentro de la hora no es prueba de identidad.
        val result = SessionHealthMatcher.associate(
            sStart, sEnd,
            listOf(candidate("w1", 610, 620, "com.garmin.android")),
            own
        )
        assertEquals(SessionHealthMatcher.Association.None, result)
    }

    @Test fun sameAppPhoneAndWatchDuplicatesCollapseToOneSeries() {
        val phone = (0 until 10).map { hr(it * 30L, 120 + it, "com.wear.app") }
        val watch = (0 until 10).map { hr(it * 30L + 1, 120 + it, "com.wear.app.watch") }
        val merged = SessionHealthMatcher.mergeHeartRate(phone + watch)
        val series = (merged as SessionHealthMatcher.HeartMerge.Merged).series
        assertEquals(10, series.size)
    }

    @Test fun duplicatedExternalRecordsAreNotDoubleCounted() {
        val a = listOf(hr(0, 130, "com.ext.a"), hr(30, 132, "com.ext.a"))
        val b = listOf(hr(0, 130, "com.ext.b"), hr(30, 132, "com.ext.b"))
        val merged = SessionHealthMatcher.mergeHeartRate(a + b)
        val series = (merged as SessionHealthMatcher.HeartMerge.Merged).series
        assertEquals(2, series.size)
        assertEquals(130, series[0].second)
    }

    @Test fun foreignSignalInsideWindowIsAmbiguousAndRefineSkips() {
        val real = (0 until 10).map { hr(it * 30L, 120, "com.wear.app") }
        val foreign = (0 until 10).map { hr(it * 30L + 5, 165, "com.other.sport") }
        val merged = SessionHealthMatcher.mergeHeartRate(real + foreign)
        assertEquals(SessionHealthMatcher.HeartMerge.Ambiguous, merged)
    }

    @Test fun singleOriginPassesThroughUnchanged() {
        val one = (0 until 5).map { hr(it * 60L, 100 + it, "com.wear.app") }
        val merged = SessionHealthMatcher.mergeHeartRate(one)
        val series = (merged as SessionHealthMatcher.HeartMerge.Merged).series
        assertEquals(5, series.size)
    }

    @Test fun emptyEvidenceIsEmpty() {
        assertEquals(SessionHealthMatcher.HeartMerge.Empty,
            SessionHealthMatcher.mergeHeartRate(emptyList()))
        assertEquals(SessionHealthMatcher.Association.None,
            SessionHealthMatcher.associate(sStart, sEnd, emptyList(), own))
    }
}
