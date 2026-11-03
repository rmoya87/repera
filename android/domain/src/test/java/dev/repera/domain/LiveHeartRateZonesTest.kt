package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LiveHeartRateZonesTest {
    @Test fun personalizedMaximumChangesZoneWithoutInventingHeartRate() {
        assertEquals(4, LiveHeartRateZones.zone(150, 180.0))
        assertEquals(3, LiveHeartRateZones.zone(150, 200.0))
        assertNull(LiveHeartRateZones.zone(null, 180.0))
    }

    @Test fun zonesMatchAppleWatchCutoffs() {
        assertEquals(1, LiveHeartRateZones.zone(113))
        assertEquals(2, LiveHeartRateZones.zone(114))
        assertEquals(2, LiveHeartRateZones.zone(132))
        assertEquals(3, LiveHeartRateZones.zone(133))
        assertEquals(3, LiveHeartRateZones.zone(151))
        assertEquals(4, LiveHeartRateZones.zone(152))
        assertEquals(4, LiveHeartRateZones.zone(170))
        assertEquals(5, LiveHeartRateZones.zone(171))
    }

    @Test fun missingOrInvalidReadingsHaveNoZone() {
        assertNull(LiveHeartRateZones.zone(null))
        assertNull(LiveHeartRateZones.zone(0))
        assertNull(LiveHeartRateZones.zone(24))
        assertNull(LiveHeartRateZones.zone(251))
        assertNull(LiveHeartRateZones.zone(120, Double.NaN))
        assertNull(LiveHeartRateZones.zone(120, 0.0))
    }
}
