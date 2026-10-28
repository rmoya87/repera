package dev.repera.mobile

import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.*
import org.junit.Test

/** Synthetic interceptor only. Never reaches Supabase or reads device credentials. */
class AIInboxAuthorizationTest {
    private val session=SupabaseIdentity.Session("fixture","synthetic-only","synthetic-refresh",3600,0)
    private fun fetch(inbox:AITrainingInbox) {
        val method=AITrainingInbox::class.java.getDeclaredMethod("fetchPending",SupabaseIdentity.Session::class.java,String::class.java)
        method.isAccessible=true;method.invoke(inbox,session,"fixture")
    }
    @Test fun revokedBeforeFetchMakesNoRequest() {
        var called=false
        val http=OkHttpClient.Builder().addInterceptor {called=true;error("must not execute")}.build()
        assertThrows(java.lang.reflect.InvocationTargetException::class.java) {
            fetch(AITrainingInbox(http) {false})
        }
        assertFalse(called)
    }
    @Test fun revocationDuringFetchRejectsResponse() {
        var allowed=true;var calls=0
        val http=OkHttpClient.Builder().addInterceptor {chain ->
            calls++;allowed=false
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1)
                .code(200).message("OK").body("[]".toResponseBody("application/json".toMediaType())).build()
        }.build()
        assertThrows(java.lang.reflect.InvocationTargetException::class.java) {
            fetch(AITrainingInbox(http) {allowed})
        }
        assertEquals(1,calls)
    }
    @Test fun unchangedAuthorityAcceptsSyntheticResponse() {
        val http=OkHttpClient.Builder().addInterceptor {chain ->
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1)
                .code(200).message("OK").body("[]".toResponseBody("application/json".toMediaType())).build()
        }.build()
        fetch(AITrainingInbox(http) {true})
    }
}
