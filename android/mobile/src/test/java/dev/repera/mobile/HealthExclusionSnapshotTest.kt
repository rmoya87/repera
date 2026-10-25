package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class HealthExclusionSnapshotTest {
    @Test fun linkedHealthIdAndWindowAreReadWithoutChangingState() {
        val state=JSONObject().put("workouts",JSONArray().put(JSONObject().put("id","local")
            .put("startedAt","2026-10-25T10:00:00Z").put("finishedAt","2026-10-25T11:00:00Z")
            .put("healthConnectRecordId","health")))
        val bytes=state.toString().toByteArray();val windows=HealthExclusionSnapshot.windows(bytes)
        assertEquals(1,windows.size);assertEquals("health",windows.single().linkedHealthId)
        assertEquals(3600_000,windows.single().endMillis-windows.single().startMillis)
        assertEquals(state.toString(),String(bytes))
        assertTrue(HealthExclusionSnapshot.windows(null).isEmpty())
    }
}
