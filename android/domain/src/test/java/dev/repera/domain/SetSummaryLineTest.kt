package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class SetSummaryLineTest {

    @Test fun weightTimesRepsIsTheStrengthShape() {
        assertEquals("50×8", SetSummaryLine.displayLine(reps = 8, weightKg = 50.0))
        assertEquals("22,5×5", SetSummaryLine.displayLine(reps = 5, weightKg = 22.5))
        assertEquals("—×12", SetSummaryLine.displayLine(reps = 12))
    }

    @Test fun nonRepUnitsLeadWithUnitAndOptionalClock() {
        assertEquals("40 cal", SetSummaryLine.displayLine(reps = 40, quantityUnit = "calories"))
        assertEquals("40 cal · 1:00",
            SetSummaryLine.displayLine(reps = 40, quantityUnit = "calories", durationSeconds = 60))
        assertEquals("500 m", SetSummaryLine.displayLine(reps = 500, quantityUnit = "meters"))
    }

    @Test fun jumpRopeStyleShowsTimesAndClock() {
        assertEquals("30 veces · 0:45",
            SetSummaryLine.displayLine(reps = 30, durationSeconds = 45))
        assertEquals("100 veces · 2:00",
            SetSummaryLine.displayLine(reps = 100, durationSeconds = 120))
    }

    @Test fun deficitAndDurationVariants() {
        assertEquals("20 cm × 5", SetSummaryLine.displayLine(reps = 5, deficitCm = 20.0))
        assertEquals("80×3 · 1:30",
            SetSummaryLine.displayLine(reps = 3, weightKg = 80.0, durationSeconds = 90))
    }

    @Test fun prescriptionLineMatchesIos() {
        assertEquals("8 @ 50 kg", SetSummaryLine.prescriptionLine(8, 50.0, "Press banca"))
        assertEquals("8 @ 22,5 kg", SetSummaryLine.prescriptionLine(8, 22.5, "Press banca"))
        assertEquals("12 reps", SetSummaryLine.prescriptionLine(12, null, "Dominadas"))
        assertEquals("Dominadas", SetSummaryLine.prescriptionLine(null, null, "Dominadas"))
        assertEquals("Dominadas", SetSummaryLine.prescriptionLine(0, null, "Dominadas"))
    }
}
