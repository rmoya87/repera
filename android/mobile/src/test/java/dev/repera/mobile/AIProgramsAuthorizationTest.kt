package dev.repera.mobile
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.*
import org.junit.Test
class AIProgramsAuthorizationTest {
 private val session=SupabaseIdentity.Session("fixture","synthetic-only","synthetic-refresh",3600,0)
 private val program=AITrainingProgramsStore.Program("p","Plan","Fuerza","2026-10-26",null,4,emptyList(),"proposed",1)
 @Test fun revokedReadAndChangeNeverSendRequests() {
  var calls=0
  val http=OkHttpClient.Builder().addInterceptor {calls++;error("must not send")}.build()
  val store=AITrainingProgramsStore(http) {false}
  assertTrue(store.refresh(session) is AITrainingProgramsStore.LoadResult.Failed)
  assertNotNull(store.changeStatus(session,program,"active"));assertEquals(0,calls)
 }
 @Test fun accountChangeDuringReadRejectsOldPrograms() {
  var allowed=true
  val http=OkHttpClient.Builder().addInterceptor {chain ->
   allowed=false
   Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1).code(200).message("OK")
    .body("[]".toResponseBody("application/json".toMediaType())).build()
  }.build()
  assertTrue(AITrainingProgramsStore(http) {allowed}.refresh(session) is AITrainingProgramsStore.LoadResult.Failed)
 }
}
