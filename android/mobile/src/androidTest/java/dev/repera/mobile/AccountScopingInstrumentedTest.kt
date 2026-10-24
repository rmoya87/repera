package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/**
 * Aislamiento por cuenta del snapshot local (LocalSnapshotStore:
 * users/<sha256(accountId)>/). Datos sintéticos: una cuenta NUNCA lee el
 * estado de otra, y la misma cuenta reabre exactamente lo escrito.
 */
@RunWith(AndroidJUnit4::class)
class AccountScopingInstrumentedTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    private fun snapshot(marker: String): ByteArray {
        val state = JSONObject()
            .put("exercises", org.json.JSONArray())
            .put("workouts", org.json.JSONArray())
            .put("marker", marker)
            .put("syncRevision", 1)
            .put("updatedAt", "2026-10-25T00:00:00Z")
        return state.toString().toByteArray(Charsets.UTF_8)
    }

    @Test fun snapshotsAreIsolatedPerAccount() {
        val accountA = "scoping-a-" + UUID.randomUUID()
        val accountB = "scoping-b-" + UUID.randomUUID()
        val storeA = LocalSnapshotStore(context, accountA)
        val storeB = LocalSnapshotStore(context, accountB)
        storeA.write(snapshot("de-A"))
        assertNull("la cuenta B no ve el snapshot de A", storeB.read())
        val readBackA = JSONObject(String(storeA.read()!!, Charsets.UTF_8))
        assertEquals("de-A", readBackA.getString("marker"))
        storeB.write(snapshot("de-B"))
        val readBackB = JSONObject(String(storeB.read()!!, Charsets.UTF_8))
        assertEquals("de-B", readBackB.getString("marker"))
        assertNotEquals(
            JSONObject(String(storeA.read()!!, Charsets.UTF_8)).getString("marker"),
            readBackB.getString("marker"))
    }

    @Test fun reopeningSameAccountReadsSameFile() {
        val account = "scoping-c-" + UUID.randomUUID()
        LocalSnapshotStore(context, account).write(snapshot("persistente"))
        val reopened = LocalSnapshotStore(context, account)
        val state = JSONObject(String(reopened.read()!!, Charsets.UTF_8))
        assertEquals("persistente", state.getString("marker"))
        LocalSnapshotStore.validate(state.toString().toByteArray(Charsets.UTF_8))
    }
}
