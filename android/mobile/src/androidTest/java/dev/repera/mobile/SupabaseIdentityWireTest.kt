package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class SupabaseIdentityWireTest {
    @Test fun payloadContainsOnlyGoogleIdTokenAndNonce() {
        val payload = SupabaseIdentity.requestPayload("fake-google.jwt", "random-nonce")
        assertEquals("google", payload.getString("provider"))
        assertEquals("fake-google.jwt", payload.getString("id_token"))
        assertEquals("random-nonce", payload.getString("nonce"))
        assertFalse(payload.has("client_secret"))
        assertFalse(payload.has("service_role"))
    }

    @Test fun durableSessionKeepsRefreshTokenAndExpiry() {
        val session = SupabaseIdentity.parseSession(
            JSONObject()
                .put("user", JSONObject().put("id", "supabase-user"))
                .put("access_token", "test-session")
                .put("refresh_token", "test-refresh")
                .put("token_type", "bearer")
                .put("expires_in", 3600)
        )
        assertEquals("supabase-user", session.userId)
        assertEquals("test-session", session.accessToken)
        assertEquals("test-refresh", session.refreshToken)
        assertEquals(3600, session.expiresIn)
        assertEquals(session.issuedAtEpochSeconds + 3600, session.expiresAtEpochSeconds)
    }

    @Test fun malformedSupabaseResponsesNeverAuthenticate() {
        val good = JSONObject().put("user", JSONObject().put("id", "supabase-user"))
            .put("access_token", "test-session").put("refresh_token", "test-refresh")
            .put("token_type", "bearer")
            .put("expires_in", 3600)
        assertEquals("supabase-user", SupabaseIdentity.parseSession(good).userId)
        val missingUser = JSONObject(good.toString()).apply { remove("user") }
        val emptyToken = JSONObject(good.toString()).put("access_token", "")
        val expired = JSONObject(good.toString()).put("expires_in", 0)
        // A session without refresh token cannot survive a process restart:
        // rejecting it is what makes the durable session honest.
        val noRefresh = JSONObject(good.toString()).apply { remove("refresh_token") }
        for (json in listOf(missingUser, emptyToken, expired, noRefresh)) {
            assertThrows(IllegalArgumentException::class.java) {
                SupabaseIdentity.parseSession(json)
            }
        }
    }
}
