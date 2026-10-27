package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class WatchInputDraftTest {
    private fun draft()=WatchInputDraft("session",2,3,8,40.0,2.0,30,"reps",0,false,false)
    @Test fun roundTripKeepsUnconfirmedValuesAndScope() {
        val d=draft();assertEquals(d,WatchInputDraft.decode(d.encode()))
        assertTrue(d.matches("session",2,3))
        assertFalse(d.matches("other",2,3));assertFalse(d.matches("session",1,3))
        assertFalse(d.matches("session",2,4))
    }
    @Test fun optionalValuesRemainAbsent() {
        val d=draft().copy(weightKg=null,rir=null,unit="meters",quantity=500)
        assertEquals(d,WatchInputDraft.decode(d.encode()))
    }
    @Test fun malformedOrUnsupportedDraftNeverReplacesPrescription() {
        assertNull(WatchInputDraft.decode("{}"));assertNull(WatchInputDraft.decode("broken"))
        assertNull(WatchInputDraft.decode(draft().encode().replace("\"version\":1","\"version\":2")))
        assertNull(WatchInputDraft.decode(draft().encode().replace("\"quantity\":8","\"quantity\":-1")))
    }
}
