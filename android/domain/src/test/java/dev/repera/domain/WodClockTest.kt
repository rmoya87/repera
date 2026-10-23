package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class WodClockTest {
    @Test fun forTimeNeverStopsAtCap() {
        val spec = WodClockSpec(WodFormat.FOR_TIME, blockTimeCapMinutes = 12)
        assertEquals(0, WodClock.timeCapSeconds(spec))
        assertEquals(13 * 60 + 17, WodClock.face(spec, 13 * 60 + 17).primarySeconds)
        assertEquals("TC superado", WodClock.face(spec, 13 * 60 + 17).label)
    }

    @Test fun emomEveryTwoMinutesFourIntervals() {
        val spec = WodClockSpec(WodFormat.EMOM, intervalSeconds = 120, plannedIntervals = 4)
        assertEquals(480, WodClock.timeCapSeconds(spec))
        assertEquals(120, WodClock.face(spec, 0).primarySeconds)
        assertEquals(1, WodClock.face(spec, 119).primarySeconds)
        assertEquals(120, WodClock.face(spec, 120).primarySeconds)
        assertTrue(WodClock.face(spec, 480).finishedIntervals)
        assertEquals("Finalizado", WodClock.face(spec, 480).label)
    }

    @Test fun tabata20And10EightRounds() {
        val spec = WodClockSpec(WodFormat.TABATA, rounds = 8, workSeconds = 20, restSeconds = 10)
        assertEquals(240, WodClock.timeCapSeconds(spec))
        assertEquals(20, WodClock.face(spec, 0).primarySeconds)
        assertEquals("Descanso", WodClock.face(spec, 20).label)
        assertEquals(10, WodClock.face(spec, 20).primarySeconds)
        assertEquals(20, WodClock.face(spec, 30).primarySeconds)
        assertEquals("Finalizado", WodClock.face(spec, 240).label)
    }

    @Test fun circuitNeverAddsRestAfterFinalRound() {
        val spec = WodClockSpec(WodFormat.CIRCUIT, stations = 2, rounds = 3,
            intervalSeconds = 45, restBetweenRoundsSeconds = 25)
        assertEquals(320, WodClock.timeCapSeconds(spec)) // six 45-second stations + 2*25 s rest
        assertEquals("Descanso · ronda 1", WodClock.face(spec, 90).label)
        assertEquals("Estación 1/2 · R2", WodClock.face(spec, 115).label)
        assertEquals("Finalizado", WodClock.face(spec, 320).label)
    }

    @Test fun amrapCountsDownRatherThanFakePerMovementSets() {
        val spec = WodClockSpec(WodFormat.AMRAP, blockTimeCapMinutes = 12)
        assertEquals(720, WodClock.face(spec, 0).primarySeconds)
        assertEquals(0, WodClock.face(spec, 720).primarySeconds)
        assertFalse(WodClock.face(spec, 720).countsUp)
        assertEquals("Finalizado", WodClock.face(spec, 720).label)
        assertTrue(WodClock.face(spec, 720).finishedIntervals)
    }
}
