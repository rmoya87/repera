package dev.repera.mobile

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Contratos RPC Center (accept/book/cancel/send) con HTTP fake — sin secretos. */
class BusinessCenterRpcContractTest {
    @Test fun acceptBookCancelSendUseExactRpcBodies() {
        val seen = mutableListOf<Pair<String, JSONObject>>()
        val http = OkHttpClient.Builder().addInterceptor { chain ->
            val request = chain.request()
            assertEquals("Bearer synthetic-only", request.header("Authorization"))
            val buffer = okio.Buffer()
            request.body!!.writeTo(buffer)
            seen += request.url.encodedPath.substringAfterLast('/') to JSONObject(buffer.readUtf8())
            Response.Builder().request(request).protocol(Protocol.HTTP_1_1).code(200).message("OK")
                .body("[]".toResponseBody("application/json".toMediaType())).build()
        }.build()
        val session = SupabaseIdentity.Session("user", "synthetic-only", "synthetic-refresh", 3600, 0)
        val store = BusinessCenterStore(http)
        store.accept(session, BusinessCenterStore.Invitation("inv-1", "org1", "athlete", null, null, null))
        store.book(session,
            BusinessCenterStore.Occurrence("occ-1", "org1", "class", "WOD",
                "2026-11-01T18:00:00Z", null, 12, "active"),
            BusinessCenterStore.Pass("pass-1", "org1", "c1", "class", 10, 3,
                "2026-01-01T00:00:00Z", "2027-01-01T00:00:00Z", "active"))
        store.cancel(session, BusinessCenterStore.Booking("book-1", "org1", "c1", "occ-1", "booked"))
        store.sendMessage(session, "org1", "Hola", "Cuerpo válido")
        assertEquals(
            listOf("accept_org_invitation", "book_service_occurrence",
                "cancel_service_booking", "athlete_send_org_message"),
            seen.map { it.first })
        assertEquals("inv-1", seen[0].second.getString("p_invitation_id"))
        assertEquals("occ-1", seen[1].second.getString("p_occurrence"))
        assertEquals("pass-1", seen[1].second.getString("p_pass"))
        assertTrue(seen[1].second.getString("p_request").isNotBlank())
        assertEquals("book-1", seen[2].second.getString("p_booking"))
        assertTrue(seen[2].second.getString("p_request").isNotBlank())
        assertEquals("org1", seen[3].second.getString("p_org"))
        assertEquals("Hola", seen[3].second.getString("p_title"))
        assertEquals("Cuerpo válido", seen[3].second.getString("p_body"))
    }

    @Test fun shortMessageBodyNeverHitsNetwork() {
        var called = false
        val store = BusinessCenterStore(OkHttpClient.Builder().addInterceptor {
            called = true; error("must not call")
        }.build())
        var rejected = false
        try {
            store.sendMessage(
                SupabaseIdentity.Session("u", "t", "r", 3600, 0),
                "org", "T", "x")
        } catch (_: IllegalArgumentException) {
            rejected = true
        }
        assertTrue(rejected)
        assertFalse(called)
    }
}
