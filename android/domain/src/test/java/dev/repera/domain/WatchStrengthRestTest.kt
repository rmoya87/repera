package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class WatchStrengthRestTest {
    @Test fun warmupNeverStartsPhoneStyleFortyFiveSecondRest() {
        assertEquals(0,WatchStrengthRest.afterConfirmedSet(120,true,0,3))
    }
    @Test fun intermediateWorkSetUsesExactPrescribedRest() {
        assertEquals(120,WatchStrengthRest.afterConfirmedSet(120,false,1,3))
    }
    @Test fun lastOrUnplannedWorkSetDoesNotStartRest() {
        assertEquals(0,WatchStrengthRest.afterConfirmedSet(120,false,3,3))
        assertEquals(0,WatchStrengthRest.afterConfirmedSet(120,false,1,0))
    }
    @Test fun missingOrNegativeRestCannotStartTimer() {
        assertEquals(0,WatchStrengthRest.afterConfirmedSet(0,false,1,3))
        assertEquals(0,WatchStrengthRest.afterConfirmedSet(-20,false,1,3))
    }
}
