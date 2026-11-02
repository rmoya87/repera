package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.util.UUID

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class WearTimerMirrorStoreTest {
    private fun snapshot(id: String, phase: String, updatedAt: Long) =
        JSONObject()
            .put("id", id)
            .put("modeRaw", "intervals")
            .put("phase", phase)
            .put("configuredSeconds", 3600)
            .put("elapsedSeconds", 80)
            .put("round", 2)
            .put("updatedAtMillis", updatedAt)

    @Test
    fun finishedCannotBeResurrectedByOldRunningPackets() {
        val store = WearTimerMirrorStore(
            RuntimeEnvironment.getApplication(), UUID.randomUUID().toString()
        )
        val id = UUID.randomUUID().toString()
        val now = System.currentTimeMillis()
        assertTrue(store.accept(snapshot(id, "running", now - 2_000)))
        assertEquals(id, store.current()!!.getString("id"))
        assertTrue(store.accept(snapshot(id, "finished", now - 1_000)))
        assertNull(store.current())
        assertFalse(store.accept(snapshot(id, "running", now - 1_500)))
        assertFalse(store.accept(snapshot(id, "running", now)))
        assertNull(store.current())
    }

    @Test
    fun lateTerminalFromOtherTimerDoesNotHideNewTimer() {
        val store = WearTimerMirrorStore(
            RuntimeEnvironment.getApplication(), UUID.randomUUID().toString()
        )
        val first = UUID.randomUUID().toString()
        val second = UUID.randomUUID().toString()
        val now = System.currentTimeMillis()
        assertTrue(store.accept(snapshot(first, "running", now - 2_000)))
        assertTrue(store.accept(snapshot(second, "running", now - 1_000)))
        assertFalse(store.accept(snapshot(first, "finished", now)))
        assertEquals(second, store.current()!!.getString("id"))
    }

    @Test
    fun malformedAndFuturePacketsAreRejected() {
        val store = WearTimerMirrorStore(
            RuntimeEnvironment.getApplication(), UUID.randomUUID().toString()
        )
        val now = System.currentTimeMillis()
        assertFalse(store.accept(snapshot("not-a-uuid", "running", now)))
        assertFalse(store.accept(snapshot(UUID.randomUUID().toString(), "running", now + 90_000)))
        assertNull(store.current())
    }
}
