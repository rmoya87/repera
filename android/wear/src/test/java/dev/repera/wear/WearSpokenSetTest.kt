package dev.repera.wear

import org.junit.Assert.*
import org.junit.Test

class WearSpokenSetTest {
    @Test fun acceptsExplicitUnitsOnly() {
        assertEquals(WearSpokenSet(12, 45.5), WearSpokenSet.parse("12 repeticiones 45,5 kilos"))
        assertEquals(WearSpokenSet(4, null), WearSpokenSet.parse("4 reps"))
        assertEquals(WearSpokenSet(null, 20.0), WearSpokenSet.parse("20 kg"))
    }

    @Test fun doesNotGuessUnlabelledOrInvalidValues() {
        assertNull(WearSpokenSet.parse("15 40"))
        assertNull(WearSpokenSet.parse("999 reps"))
        assertNull(WearSpokenSet.parse("800 kg"))
        assertNull(WearSpokenSet.parse("12 segundos"))
    }

    @Test fun acceptsSingularSpanishLabels() {
        assertEquals(WearSpokenSet(1, 15.0), WearSpokenSet.parse("1 repeticion 15 kilo"))
    }
}
