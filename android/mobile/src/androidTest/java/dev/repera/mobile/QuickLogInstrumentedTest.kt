package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class QuickLogInstrumentedTest {
 @Test fun directLogIsAtomicIdempotentAndLeavesActiveSessionUnchanged() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-quick-direct-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(context,account)
  local.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","a").put("name","Sentadilla")))
   .put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray())
  val repo=WorkoutRepository(context,account)
  val routine=repo.createRoutine("Pierna","strength",listOf(RoutineDraftEntry("a",5)))
  repo.startRoutine(routine)
  val active=JSONObject(String(local.read()!!)).getJSONObject("activeSession").toString()
  val id=java.util.UUID.randomUUID().toString()
  repo.logQuickSets("a",listOf(QuickLogRow(8,40.0),QuickLogRow(6,45.0))," Nota real ",id)
  repo.logQuickSets("a",listOf(QuickLogRow(8,40.0)),null,id)
  val after=JSONObject(String(local.read()!!))
  assertEquals(active,after.getJSONObject("activeSession").toString())
  assertEquals(1,after.getJSONArray("workouts").length())
  val workout=after.getJSONArray("workouts").getJSONObject(0)
  assertEquals("finished",workout.getString("phase"));assertEquals("Nota real",workout.getString("notes"))
  assertEquals(14,workout.getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
  assertFalse(workout.has("appleActiveEnergyKcal"))
  val before=local.read()!!
  assertTrue(runCatching {repo.logQuickSets("a",listOf(QuickLogRow(-1)),null,java.util.UUID.randomUUID().toString())}.isFailure)
  assertArrayEquals(before,local.read()!!)
 }
}
