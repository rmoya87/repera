package dev.repera.mobile

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AndroidMapProviderChoiceTest {
    @Test fun freeUsesOpenMapEvenWithKey() {
        assertFalse(AndroidMapProviderChoice.useGoogle(false, false))
        assertFalse(AndroidMapProviderChoice.useGoogle(false, true))
    }
    @Test fun proWithoutKeyFallsBackToOpenMap() {
        assertFalse(AndroidMapProviderChoice.useGoogle(true, false))
    }
    @Test fun proWithKeyUsesGoogleMaps() {
        assertTrue(AndroidMapProviderChoice.useGoogle(true, true))
    }
}
