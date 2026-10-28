package dev.repera.domain
import org.junit.Assert.assertEquals
import org.junit.Test

class WearBlockHeaderTest {
    private fun h(f: WodFormat?, header: String? = null, cap: Int? = null, rounds: Int? = null, interval: Int? = null,
                  work: Int? = null, rest: Int? = null, strength: Boolean = false) =
        WearBlockHeader.display(strength, f, header, cap, rounds, interval, work, rest)
    @Test fun strengthFallbacks() {
        assertEquals("Fuerza", h(null))
        assertEquals("Press", h(null, header = "Press"))
        assertEquals("Fuerza", h(WodFormat.AMRAP, strength = true, header = ""))
    }
    @Test fun amrapAndForTime() {
        assertEquals("AMRAP 12'", h(WodFormat.AMRAP))
        assertEquals("AMRAP 20'", h(WodFormat.AMRAP, cap = 20))
        assertEquals("For Time (TC 12')", h(WodFormat.FOR_TIME))
        assertEquals("5 RFT (TC 15')", h(WodFormat.FOR_TIME, cap = 15, rounds = 5))
    }
    @Test fun emomVariants() {
        assertEquals("EMOM 10'", h(WodFormat.EMOM))
        assertEquals("EMOM 12'", h(WodFormat.EMOM, cap = 12))
        assertEquals("Every 2' × 6", h(WodFormat.EMOM, cap = 12, interval = 120))
        assertEquals("Every 2' × 4", h(WodFormat.EMOM, rounds = 4, interval = 120))
        assertEquals("Every 3'", h(WodFormat.EMOM, interval = 180))
    }
    @Test fun othersAndHeaderFallbacks() {
        assertEquals("Tabata 20/10 ×8", h(WodFormat.TABATA))
        assertEquals("Tabata 30/15 ×4", h(WodFormat.TABATA, work = 30, rest = 15, rounds = 4))
        assertEquals("Ladder", h(WodFormat.LADDER))
        assertEquals("Mi ladder", h(WodFormat.LADDER, header = "Mi ladder"))
        assertEquals("3 RFQ", h(WodFormat.ROUNDS_FOR_QUALITY, rounds = 3))
        assertEquals("Rounds for Quality", h(WodFormat.ROUNDS_FOR_QUALITY))
        assertEquals("Circuito", h(WodFormat.CIRCUIT))
    }
}
