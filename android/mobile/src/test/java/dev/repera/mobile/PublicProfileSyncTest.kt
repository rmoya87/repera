package dev.repera.mobile

import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

/** HTTP simulado en memoria: sin red, sin Supabase, sin cuentas. Contrato tomado de Apple syncPublicProfile. */
class PublicProfileSyncTest {
    private class Rec(val method: String, val url: String, val body: String, val headers: Map<String, String>)
    private class Fake(var failOn: String? = null) : Interceptor {
        val calls = mutableListOf<Rec>()
        override fun intercept(chain: Interceptor.Chain): Response {
            val req = chain.request()
            val b = okio.Buffer(); req.body?.writeTo(b)
            calls += Rec(req.method, req.url.toString(), b.readUtf8(), req.headers.toMultimap().mapValues { it.value.first() })
            val code = if (failOn != null && req.url.toString().contains(failOn!!)) 500 else 200
            return Response.Builder().request(req).protocol(Protocol.HTTP_1_1).code(code).message("m")
                .body("{}".toResponseBody("application/json".toMediaType())).build()
        }
    }
    private val session = SupabaseIdentity.Session("AB-12", "tok", "ref", 3600, 0)
    private fun svc(f: Fake, ok: () -> Boolean = { true }) =
        PublicProfileSync("https://x.test", "pub", OkHttpClient.Builder().addInterceptor(f).build(), ok) { 1_700_000_000_000L }

    @Test fun uploadsThenPatchesWithLowercaseIdAndCacheBust() {
        val f = Fake(); svc(f).sync(session, "  Ramón  ", byteArrayOf(1, 2, 3))
        assertEquals(listOf("POST", "PATCH"), f.calls.map { it.method })
        assertEquals("https://x.test/storage/v1/object/profile-avatars/ab-12/avatar.jpg", f.calls[0].url)
        assertEquals("true", f.calls[0].headers["x-upsert"]); assertEquals("Bearer tok", f.calls[0].headers["authorization"])
        assertEquals("https://x.test/rest/v1/profiles?id=eq.ab-12", f.calls[1].url)
        val p = JSONObject(f.calls[1].body)
        assertEquals("Ramón", p.getString("display_name"))
        assertEquals("https://x.test/storage/v1/object/public/profile-avatars/ab-12/avatar.jpg?v=1700000000", p.getString("avatar_url"))
    }

    @Test fun removingAvatarDeletesBestEffortAndEncodesSqlNull() {
        val f = Fake(failOn = "/storage/"); svc(f).sync(session, "A", null)
        assertEquals(listOf("DELETE", "PATCH"), f.calls.map { it.method })
        assertTrue(JSONObject(f.calls[1].body).isNull("avatar_url")); assertTrue(JSONObject(f.calls[1].body).has("avatar_url"))
    }

    @Test fun oversizePhotoRejectedBeforeAnyRequest() {
        val f = Fake()
        assertTrue(runCatching { svc(f).sync(session, "A", ByteArray(PublicProfileSync.MAX_AVATAR_BYTES + 1)) }.exceptionOrNull() is PublicProfileSync.PhotoTooLarge)
        assertTrue(f.calls.isEmpty())
    }

    @Test fun failedUploadNeverPatchesProfile() {
        val f = Fake(failOn = "/storage/"); assertTrue(runCatching { svc(f).sync(session, "A", byteArrayOf(1)) }.isFailure)
        assertEquals(listOf("POST"), f.calls.map { it.method })
    }

    @Test fun revocationAfterUploadStopsBeforePatch() {
        val f = Fake(); var n = 0
        // authorize se llama: inicio, send(upload) antes, tras respuesta, antes del PATCH...
        val r = runCatching { svc(f) { ++n < 4 }.sync(session, "A", byteArrayOf(1)) }
        assertTrue(r.isFailure); assertFalse(f.calls.any { it.method == "PATCH" })
    }

    @Test fun nameIsTrimmedAndLimitedTo100() {
        val f = Fake(); svc(f).sync(session, " " + "x".repeat(150) + " ", null)
        assertEquals(100, JSONObject(f.calls.last().body).getString("display_name").length)
    }

    @Test fun revokedBeforeStartMakesNoRequest() {
        val f = Fake(); assertTrue(runCatching { svc(f) { false }.sync(session, "A", null) }.isFailure)
        assertTrue(f.calls.isEmpty())
    }
}
