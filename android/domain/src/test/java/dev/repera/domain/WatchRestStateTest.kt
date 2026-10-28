package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class WatchRestStateTest {
    private val state=WatchRestState("session",false,10000,1000,7)
    @Test fun runningRestCatchesUpThroughProcessAbsence() {
        assertEquals(7500L,state.remainingAt("session",3500,7))
        assertEquals(0L,state.remainingAt("session",50000,7))
        assertEquals(state,WatchRestState.decode(state.encode()))
    }
    @Test fun pausedRestNeverConsumesAbsence() {
        assertEquals(10000L,state.copy(paused=true).remainingAt("session",500000,7))
    }
    @Test fun rebootUnknownBootWrongSessionOrClockRollbackCannotRestore() {
        assertNull(state.remainingAt("other",3500,7));assertNull(state.remainingAt("session",3500,8))
        assertNull(state.remainingAt("session",3500,null));assertNull(state.remainingAt("session",500,7))
        assertNull(WatchRestState.decode("{}"))
    }
}
