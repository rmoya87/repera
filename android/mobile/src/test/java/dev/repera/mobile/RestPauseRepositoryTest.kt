package dev.repera.mobile
import androidx.test.core.app.ApplicationProvider
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
@RunWith(RobolectricTestRunner::class)
@Config(sdk=[35])
class RestPauseRepositoryTest {
 @Test fun oneClusterIsAValidMeasuredSetAndKeepsRest() {
  val context=ApplicationProvider.getApplicationContext<android.content.Context>()
  val user="one-cluster-fixture"
  val movement=JSONObject().put("id","ex").put("name","Back squat").put("equipment","Barra")
  val state=JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray().put(movement))
   .put("activeSession",JSONObject().put("id","session").put("title","Prueba").put("currentIndex",0)
    .put("exercises",JSONArray().put(JSONObject().put("id","entry").put("exercise",movement)
     .put("plannedSets",JSONArray()).put("loggedSets",JSONArray()))))
  val store=LocalSnapshotStore(context,user)
  store.write(state.toString().toByteArray())
  WorkoutRepository(context,user).logRestPauseSet(listOf(8 to 15),40.0)
  val ex=JSONObject(String(store.read()!!)).getJSONObject("activeSession").getJSONArray("exercises").getJSONObject(0)
  val set=ex.getJSONArray("loggedSets").getJSONObject(0)
  assertEquals(8,set.getInt("reps"));assertEquals(8,ex.getInt("completedReps"))
  assertEquals(1,set.getJSONArray("clusters").length())
  assertEquals(15,set.getJSONArray("clusters").getJSONObject(0).getInt("restSeconds"))
 }
}
