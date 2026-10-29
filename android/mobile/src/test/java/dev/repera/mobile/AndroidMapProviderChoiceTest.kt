package dev.repera.mobile

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AndroidMapProviderChoiceTest {
    @Test fun anyPlanWithoutKeyFallsBackToOpenMap() {
        assertFalse(AndroidMapProviderChoice.useGoogle(false))
    }
    @Test fun freeAndProWithKeyUseGoogleMaps() {
        assertTrue(AndroidMapProviderChoice.useGoogle(true))
    }
}
