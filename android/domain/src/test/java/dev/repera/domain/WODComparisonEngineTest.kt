package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WODComparisonEngineTest {
    private fun amrap(
        rounds: Int = 8,
        extra: Int = 3,
        prescription: String = "amrap-12-burpees-10",
        rx: Boolean? = true,
        scaling: String = ""
    ) = ComparableWodResult(
        format = "amrap",
        prescriptionFingerprint = prescription,
        isRx = rx,
        scalingFingerprint = scaling,
        roundsCompleted = rounds,
        extraReps = extra,
        repsPerRound = 10,
        timeCapSeconds = 720
    )

    @Test fun amrapRanksRoundsPlusExtraReps() {
        val result = WODComparisonEngine.compare(
            previous = amrap(rounds = 8, extra = 3),
            current = amrap(rounds = 9, extra = 5)
        )
        assertEquals(12, result?.improvement)
        assertEquals("reps", result?.unit)
    }

    @Test fun requiresExactPrescriptionAndDeclaredRx() {
        assertNull(WODComparisonEngine.compare(
            amrap(), amrap(prescription = "different")))
        assertNull(WODComparisonEngine.compare(
            amrap(), amrap(rx = null)))
        assertNull(WODComparisonEngine.compare(
            amrap(), amrap(rx = false, scaling = "new")))
        assertNull(WODComparisonEngine.compare(
            amrap(extra = 10), amrap()))
    }

    @Test fun scaledVersionsMustHaveSameDocumentedModifications() {
        val before = amrap(rx = false, scaling = "kg:40")
        assertNull(WODComparisonEngine.compare(before, amrap(rx = false, scaling = "")))
        assertNull(WODComparisonEngine.compare(before, amrap(rx = false, scaling = "kg:35")))
        assertEquals(12, WODComparisonEngine.compare(
            before, amrap(rounds = 9, extra = 5, rx = false, scaling = "kg:40")
        )?.improvement)
    }

    @Test fun forTimeExcludesTimeCappedOrIncompleteFinishes() {
        fun timed(seconds: Int, cap: Int? = 1200) = ComparableWodResult(
            format = "forTime",
            prescriptionFingerprint = "3 rounds wall-ball",
            isRx = true,
            scalingFingerprint = "",
            elapsedSeconds = seconds,
            timeCapSeconds = cap
        )
        assertEquals(30, WODComparisonEngine.compare(
            timed(700), timed(670)
        )?.improvement)
        assertNull(WODComparisonEngine.compare(timed(1200), timed(900)))
    }
    @Test fun typedLoadComparisonKeepsHalfKilogramDifferences() {
        fun load(value:Double, signature:String="same")=ComparableWodResult(
            format="maxEffort",prescriptionFingerprint=signature,isRx=true,
            scalingFingerprint="",timeCapSeconds=600,
            measuredMetric="loadKg",measuredValue=value
        )
        val compared=WODComparisonEngine.compareMeasurement(load(87.5),load(90.0))
        assertEquals(2.5,compared?.improvement)
        assertEquals("kg",compared?.unit)
        assertNull(WODComparisonEngine.compareMeasurement(load(87.5),load(90.0,"different")))
        assertNull(WODComparisonEngine.compareMeasurement(
            load(87.5),load(90.0).copy(measuredMetric="distanceMeters")
        ))
    }

}
