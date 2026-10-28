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
    @Test fun techniquesRoundTripDropAndRestPause() {
        val drop=draft().copy(kind="dropset",drops=listOf(6 to 35.0,4 to 30.0),rir=null)
        assertEquals(drop,WatchInputDraft.decode(drop.encode()))
        val rp=draft().copy(kind="restpause",clusters=listOf(8 to 15,5 to 15),quantity=13)
        assertEquals(rp,WatchInputDraft.decode(rp.encode()))
        val legacy=draft().encode()
        val decoded=WatchInputDraft.decode(legacy)!!
        assertEquals("straight",decoded.kind)
        assertTrue(decoded.drops.isEmpty());assertTrue(decoded.clusters.isEmpty())
    }
    @Test fun malformedOrUnsupportedDraftNeverReplacesPrescription() {
        assertNull(WatchInputDraft.decode("{}"));assertNull(WatchInputDraft.decode("broken"))
        assertNull(WatchInputDraft.decode(draft().encode().replace("\"version\":1","\"version\":2")))
        assertNull(WatchInputDraft.decode(draft().encode().replace("\"quantity\":8","\"quantity\":-1")))
        assertNull(WatchInputDraft.decode(draft().copy(kind="dropset",drops=listOf(5 to 40.0)).encode()
            .replace("\"kind\":\"dropset\"","\"kind\":\"dropset\"").let {
                // dropset without drops
                org.json.JSONObject(it).put("drops",org.json.JSONArray()).toString()
            }))
    }
}
