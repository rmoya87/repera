package dev.repera.mobile

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Un reintento tras timeout reutiliza `p_request`; tras ACK del servidor se genera uno nuevo. */
class BusinessBookingRequestIdTest {
    private val occurrence = BusinessCenterStore.Occurrence("occ-rid", "org1", "class", "WOD",
        "2026-11-01T18:00:00Z", null, 12, "active")
    private val pass = BusinessCenterStore.Pass("pass-rid", "org1", "c1", "class", 10, 3,
        "2026-01-01T00:00:00Z", "2027-01-01T00:00:00Z", "active")

    private fun store(codes: ArrayDeque<Int>, seen: MutableList<JSONObject>, body: String = "[]") =
        BusinessCenterStore(OkHttpClient.Builder().addInterceptor { chain ->
            val request = chain.request()
            seen += JSONObject(okio.Buffer().also { request.body!!.writeTo(it) }.readUtf8())
            val code = codes.removeFirst()
            if (code == 0) throw java.io.IOException("timeout")
            Response.Builder().request(request).protocol(Protocol.HTTP_1_1).code(code).message("x")
                .body(body.toResponseBody("application/json".toMediaType())).build()
        }.build())

    @Test fun bookRetryReusesRequestIdUntilAcknowledged() {
        val seen = mutableListOf<JSONObject>()
        val session = SupabaseIdentity.Session("user-rid", "synthetic-only", "synthetic-refresh", 3600, 0)
        val store = store(ArrayDeque(listOf(0, 503, 200, 200)), seen)
        assertTrue(runCatching { store.book(session, occurrence, pass) }.isFailure)
        assertTrue(runCatching { store.book(session, occurrence, pass) }.isFailure)
        store.book(session, occurrence, pass)
        store.book(session, occurrence, pass)
        val ids = seen.map { it.getString("p_request") }
        assertEquals(ids[0], ids[1])
        assertEquals(ids[0], ids[2])
        assertNotEquals(ids[2], ids[3])
    }

    @Test fun reusedIdIsDroppedAndCancelUsesItsOwnIntent() {
        val seen = mutableListOf<JSONObject>()
        val session = SupabaseIdentity.Session("user-rid-2", "synthetic-only", "synthetic-refresh", 3600, 0)
        val rejecting = store(ArrayDeque(listOf(409)), seen, """{"message":"REQUEST_ID_REUSED"}""")
        assertTrue(runCatching { rejecting.book(session, occurrence, pass) }.isFailure)
        val ok = store(ArrayDeque(listOf(0, 200)), seen)
        val booking = BusinessCenterStore.Booking("book-rid", "org1", "c1", "occ-rid", "booked")
        assertTrue(runCatching { ok.cancel(session, booking) }.isFailure)
        ok.cancel(session, booking)
        assertEquals(seen[1].getString("p_request"), seen[2].getString("p_request"))
        assertNotEquals(seen[0].getString("p_request"), seen[1].getString("p_request"))
    }
}
