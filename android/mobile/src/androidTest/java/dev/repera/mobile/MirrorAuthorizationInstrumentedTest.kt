package dev.repera.mobile

import androidx.test.platform.app.InstrumentationRegistry
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.*
import org.junit.Test

/** Disposable account IDs and intercepted requests. No real backend or session store. */
class MirrorAuthorizationInstrumentedTest {
    private val session=SupabaseIdentity.Session("synthetic-guard","synthetic-only","synthetic-refresh",3600,0)
    private val context get()=InstrumentationRegistry.getInstrumentation().targetContext
    @Test fun revokedMirrorDoesNotFetchRecoverUploadOrAcknowledgeDeletes() {
        val id="synthetic-guard-"+java.util.UUID.randomUUID()
        var calls=0
        val http=OkHttpClient.Builder().addInterceptor {calls++;error("must not execute")}.build()
        val store=WorkoutMirrorStore(context,id,http) {false}
        store.noteDeleted("synthetic-deleted")
        val result=store.sync(session,WorkoutRepository(context,id))
        assertFalse(result.ok);assertEquals(0,calls)
        assertTrue(store.pendingDeletes().contains("synthetic-deleted"))
    }
    @Test fun revocationWhileMirrorReadsCannotApplyResponse() {
        val id="synthetic-guard-"+java.util.UUID.randomUUID()
        var allowed=true;var calls=0
        val http=OkHttpClient.Builder().addInterceptor {chain ->
            calls++;allowed=false
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1)
                .code(200).message("OK").body("[]".toResponseBody("application/json".toMediaType())).build()
        }.build()
        val current=session.copy(userId=id)
        val result=WorkoutMirrorStore(context,id,http) {allowed}.sync(current,WorkoutRepository(context,id))
        assertFalse(result.ok);assertEquals(1,calls)
        assertNull(LocalSnapshotStore(context,id).read())
    }
    @Test fun revokedTrainingContextNeverReadsOrUploadsAccountData() {
        val id="synthetic-context-"+java.util.UUID.randomUUID()
        var calls=0
        val http=OkHttpClient.Builder().addInterceptor {calls++;error("must not execute")}.build()
        val result=AITrainingContextStore(context,id,http) {false}.sync(session.copy(userId=id),WorkoutRepository(context,id))
        assertFalse(result.ok);assertEquals(0,calls)
    }
}
