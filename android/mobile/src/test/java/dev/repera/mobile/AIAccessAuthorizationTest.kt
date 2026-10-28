package dev.repera.mobile
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.*
import org.junit.Test
class AIAccessAuthorizationTest {
 private val session=SupabaseIdentity.Session("fixture","synthetic-only","synthetic-refresh",3600,0)
 @Test fun revokedTokenOperationsNeverSendRequests() {
  var calls=0
  val http=OkHttpClient.Builder().addInterceptor {calls++;error("must not send")}.build()
  val store=AIAccessStore(http) {false}
  assertTrue(store.refresh(session) is AIAccessStore.LoadResult.Failed)
  assertTrue(store.create(session,"Fixture","30d",false) is AIAccessStore.CreateResult.Failed)
  assertNotNull(store.revoke(session,"fixture-token"));assertEquals(0,calls)
 }
 @Test fun tokenResponseAfterAccountChangeNeverEscapesAsCreatedResult() {
  var allowed=true
  val http=OkHttpClient.Builder().addInterceptor {chain ->
   allowed=false
   Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1).code(200).message("OK")
    .body("{}".toResponseBody("application/json".toMediaType())).build()
  }.build()
  assertTrue(AIAccessStore(http) {allowed}.create(session,"Fixture","30d",false) is AIAccessStore.CreateResult.Failed)
 }
}
