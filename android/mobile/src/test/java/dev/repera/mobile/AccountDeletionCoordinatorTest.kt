package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

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
    fun emptyShellHasNoWorkouts() {
        val shell = AccountDeletionCoordinator.emptyShellState()
        assertEquals(0, shell.getJSONArray("workouts").length())
        assertEquals(0, shell.getJSONArray("routines").length())
        assertTrue(shell.has("settings"))
    }
}
