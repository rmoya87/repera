package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WearMeasuredEnergyTest {
    @Test fun totalIsNotInventedFromMissingSensors() {
        assertNull(WearMeasuredEnergy.verifiedTotal(null))
        assertNull(WearMeasuredEnergy.verifiedTotal(0.0))
        assertNull(WearMeasuredEnergy.verifiedTotal(Double.NaN))
        assertNull(WearMeasuredEnergy.verifiedTotal(-12.0))
    }

    @Test fun zeroOrLatePacketsCannotResetMeasuredTotal() {
        assertEquals(184.0, WearMeasuredEnergy.reconcileTotal(184.0, 0.0)!!, 0.001)
        assertEquals(184.0, WearMeasuredEnergy.reconcileTotal(184.0, 181.0)!!, 0.001)
        assertEquals(203.0, WearMeasuredEnergy.reconcileTotal(184.0, 203.0)!!, 0.001)
        assertNull(WearMeasuredEnergy.reconcileTotal(null, null))
    }

    @Test fun measuredPulseMustBePhysiologicallyValid() {
        assertNull(WearMeasuredEnergy.verifiedAveragePulse(null))
        assertNull(WearMeasuredEnergy.verifiedAveragePulse(0.0))
        assertNull(WearMeasuredEnergy.verifiedAveragePulse(Double.POSITIVE_INFINITY))
        assertNull(WearMeasuredEnergy.verifiedAveragePulse(251.0))
        assertEquals(92.0, WearMeasuredEnergy.verifiedAveragePulse(92.0)!!, 0.001)
    }
}
