package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

@RunWith(RobolectricTestRunner::class)
class AccountDeletionCoordinatorTest {
    @Test
    fun rejectsActiveSession() {
        val state = JSONObject().put(
            "activeSession",
            JSONObject().put("id", "s1").put("title", "Fuerza")
        )
        assertThrows(AccountDeletionClient.AccountDeletionException::class.java) {
            AccountDeletionCoordinator.assertNoActiveSession(state)
        }
    }

    @Test
    fun allowsMissingOrEmptyActiveSession() {
        AccountDeletionCoordinator.assertNoActiveSession(null)
        AccountDeletionCoordinator.assertNoActiveSession(JSONObject())
        AccountDeletionCoordinator.assertNoActiveSession(
            JSONObject().put("activeSession", JSONObject().put("id", ""))
        )
    }

    @Test
    fun wipeLocalFolderRemovesDurableAccountData() {
        val context = RuntimeEnvironment.getApplication()
        val owner = "test-purge-" + java.util.UUID.randomUUID()
        val store = LocalSnapshotStore(context, owner)
        val snapshot = AccountDeletionCoordinator.emptyShellState()
        store.write(snapshot.toString().toByteArray(Charsets.UTF_8))
        assertTrue(store.read() != null)

        AccountDeletionCoordinator.wipeLocalUserFolder(context, owner)
        assertTrue(store.read() == null)
        // Idempotency is required for interrupted deletion retries.
        AccountDeletionCoordinator.wipeLocalUserFolder(context, owner)
    }

    @Test
    fun divergentDriveCopiesGetIndependentAtomicLocalBackups() {
        val context = RuntimeEnvironment.getApplication()
        val owner = "test-drive-backups-" + java.util.UUID.randomUUID()
        val local = LocalSnapshotStore(context, owner)
        val first = AccountDeletionCoordinator.emptyShellState()
            .put("syncRevision", 1).toString().toByteArray()
        val second = AccountDeletionCoordinator.emptyShellState()
            .put("syncRevision", 2).toString().toByteArray()
        local.preserveRemoteDuplicate("remote-1", first)
        local.preserveRemoteDuplicate("remote-2", second)
        local.preserveRemoteDuplicate("remote-1", first)
        val hash = java.security.MessageDigest.getInstance("SHA-256")
            .digest(owner.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
        val folder = java.io.File(context.filesDir, "users/$hash")
        val copies = folder.listFiles()?.filter {
            it.name.startsWith("remote_conflict_") && it.name.endsWith(".json")
        } ?: emptyList()
        assertEquals(2, copies.size)
        assertTrue(copies.any { it.readBytes().contentEquals(first) })
        assertTrue(copies.any { it.readBytes().contentEquals(second) })
        AccountDeletionCoordinator.wipeLocalUserFolder(context, owner)
    }

    @Test
    fun emptyShellHasNoWorkouts() {
        val shell = AccountDeletionCoordinator.emptyShellState()
        assertEquals(0, shell.getJSONArray("workouts").length())
        assertEquals(0, shell.getJSONArray("routines").length())
        assertTrue(shell.has("settings"))
    }
}
