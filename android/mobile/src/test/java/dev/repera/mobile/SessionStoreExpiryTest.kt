package dev.repera.mobile

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionStoreExpiryTest {

    private fun stored(expiresAt: Long) = SessionStore.StoredSession(
        uniqueId = "g-1", email = "a@b.c", displayName = "Atleta",
        userId = "user-1", accessToken = "a", refreshToken = "r",
        expiresAtEpochSeconds = expiresAt
    )

    @Test
    fun `session far from expiry does not need refresh`() {
        assertFalse(stored(10_000L).expiresWithin(60L, nowEpochSeconds = 1_000L))
    }

    @Test
    fun `session inside the margin needs refresh`() {
        assertTrue(stored(1_030L).expiresWithin(60L, nowEpochSeconds = 1_000L))
    }

    @Test
    fun `expired session needs refresh`() {
        assertTrue(stored(900L).expiresWithin(60L, nowEpochSeconds = 1_000L))
    }
}
