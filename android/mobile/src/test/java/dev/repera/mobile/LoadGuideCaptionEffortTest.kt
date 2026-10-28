package dev.repera.mobile

import org.junit.Assert.assertTrue
import org.junit.Test

class LoadGuideCaptionEffortTest {
    @Test
    fun captionUsesEffortUnitLabel() {
        val guide = LoadGuide(
            lastSession = null,
            suggestedKg = 60.0,
            suggestionSource = "progresión",
            assumedRir = false,
            targetReps = 8,
            effectiveRir = 2.0
        )
        assertTrue(loadGuideCaption(guide, "rir").contains("RIR 2"))
        assertTrue(loadGuideCaption(guide, "rpe").contains("RPE 8"))
    }
}
