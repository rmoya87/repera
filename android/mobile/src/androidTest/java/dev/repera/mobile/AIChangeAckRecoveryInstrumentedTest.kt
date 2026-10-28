package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.Callable
import java.util.concurrent.Executors
class AIChangeAckRecoveryInstrumentedTest {
 private val context get()=InstrumentationRegistry.getInstrumentation().targetContext
 @Test fun successfulReplayDoesNotPresentAlreadyAppliedChangeAgain() {
  val id="test-ai-ack-"+java.util.UUID.randomUUID()
  val prefs=context.getSharedPreferences("repera.ai.change.acks.$id",0)
  assertTrue(prefs.edit().putStringSet("acks",setOf("old")).commit())
  val seen=mutableListOf<String>()
  val http=OkHttpClient.Builder().addInterceptor {chain ->
   seen.add(chain.request().method)
   val body=if(chain.request().method=="GET") """[{"id":"old","operation":"delete_workout","payload":{}}]""" else ""
   Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1).code(200).message("OK")
    .body(body.toResponseBody("application/json".toMediaType())).build()
  }.build()
  val result=AIChangeRequestStore(context,id,http).refresh(SupabaseIdentity.Session(id,"synthetic-only","synthetic-refresh",3600,0))
  assertTrue(result is AIChangeRequestStore.RefreshResult.Loaded)
  assertTrue((result as AIChangeRequestStore.RefreshResult.Loaded).pending.isEmpty())
  assertEquals(listOf("GET","PATCH"),seen);assertTrue(prefs.getStringSet("acks",emptySet())!!.isEmpty())
 }
 @Test fun independentInstancesCannotLoseQueuedAckOrConcurrentAckDuringReplay() {
  val id="test-ai-ack-"+java.util.UUID.randomUUID()
  val queue=AIChangeRequestStore::class.java.getDeclaredMethod("queueAck",String::class.java).apply {isAccessible=true}
  val pool=Executors.newFixedThreadPool(6)
  try {
   pool.invokeAll((0 until 60).map {n ->Callable {queue.invoke(AIChangeRequestStore(context,id),"id-$n")}}).forEach {it.get()}
   val prefs=context.getSharedPreferences("repera.ai.change.acks.$id",0)
   assertEquals(60,prefs.getStringSet("acks",emptySet())!!.size)
  } finally {pool.shutdownNow()}
 }
}
