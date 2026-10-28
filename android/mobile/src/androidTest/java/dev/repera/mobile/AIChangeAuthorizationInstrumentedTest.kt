package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import okhttp3.OkHttpClient
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
class AIChangeAuthorizationInstrumentedTest {
 @Test fun revokedProposalCannotReadMutateOrSendDecision() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val id="test-ai-revoked-"+java.util.UUID.randomUUID()
  var calls=0
  val http=OkHttpClient.Builder().addInterceptor {calls++;error("must not execute")}.build()
  val session=SupabaseIdentity.Session(id,"synthetic-only","synthetic-refresh",3600,0)
  val store=AIChangeRequestStore(context,id,http) {false}
  val repository=WorkoutRepository(context,id)
  val change=AIChangeRequestStore.Change("c","delete_workout","target",null,JSONObject(),null)
  assertTrue(store.refresh(session) is AIChangeRequestStore.RefreshResult.Failed)
  assertFalse(store.syncCustomExercises(session,repository))
  for(approved in listOf(false,true)) assertTrue(store.decide(session,change,approved,repository,
   WorkoutMirrorStore(context,id,http) {false}) is AIChangeRequestStore.DecideResult.Failed)
  assertEquals(0,calls);assertNull(LocalSnapshotStore(context,id).read())
 }
}
