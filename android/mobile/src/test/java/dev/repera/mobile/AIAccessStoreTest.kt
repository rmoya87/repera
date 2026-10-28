package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

class AIAccessStoreTest {

    private fun tokenRow(
        revokedAt: String? = null,
        expiresAt: String? = null,
        scopes: List<String>? = listOf("training:write")
    ): JSONObject {
        val row = JSONObject()
            .put("id", "tok-1")
            .put("label", "Mi entrenador IA")
            .put("token_prefix", "rpa_ab12")
            .put("created_at", "2026-10-01T10:00:00Z")
        if (expiresAt != null) row.put("expires_at", expiresAt)
        if (revokedAt != null) row.put("revoked_at", revokedAt)
        if (scopes != null) row.put("scopes", JSONArray(scopes))
        return row
    }

    @Test
    fun parsesTokenList() {
        val tokens = AIAccessStore.parseTokens(JSONArray().put(tokenRow()))
        val token = tokens.single()
        assertEquals("tok-1", token.id)
        assertEquals("Mi entrenador IA", token.label)
        assertTrue(token.canWrite)
    }

    @Test
    fun activeWhenNotRevokedAndNoExpiry() {
        val token = AIAccessStore.parseTokens(JSONArray().put(tokenRow())).single()
        assertTrue(token.isActive)
    }

    @Test
    fun inactiveWhenRevoked() {
        val token = AIAccessStore.parseTokens(JSONArray()
            .put(tokenRow(revokedAt = Instant.now().toString()))).single()
        assertFalse(token.isActive)
    }

    @Test
    fun inactiveWhenExpired() {
        val token = AIAccessStore.parseTokens(JSONArray()
            .put(tokenRow(expiresAt = "2020-01-01T00:00:00Z"))).single()
        assertFalse(token.isActive)
    }

    @Test
    fun activeWhenExpiryInFuture() {
        val token = AIAccessStore.parseTokens(JSONArray()
            .put(tokenRow(expiresAt = "2099-01-01T00:00:00Z"))).single()
        assertTrue(token.isActive)
    }

    @Test
    fun readOnlyScopeIsNotWrite() {
        val token = AIAccessStore.parseTokens(JSONArray()
            .put(tokenRow(scopes = listOf("training:read")))).single()
        assertFalse(token.canWrite)
    }
}
