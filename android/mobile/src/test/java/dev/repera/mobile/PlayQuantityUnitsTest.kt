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
class PlayQuantityUnitsTest {
 private fun checkMovement(name:String,equipment:String,unit:String,kg:Double?) {
  val c=ApplicationProvider.getApplicationContext<android.content.Context>()
  val user="units-$name"
  val move=JSONObject().put("id","ex").put("name",name).put("equipment",equipment)
  val state=JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray().put(move))
   .put("activeSession",JSONObject().put("id","session").put("title","Prueba").put("currentIndex",0)
    .put("exercises",JSONArray().put(JSONObject().put("id","entry").put("exercise",move)
     .put("plannedSets",JSONArray()).put("loggedSets",JSONArray()))))
  val store=LocalSnapshotStore(c,user);store.write(state.toString().toByteArray())
  val repo=WorkoutRepository(c,user)
  assertTrue(repo.active()!!.repsMetersToggle)
  repo.logCurrentSet(20,kg,quantityUnit=unit)
  var set=JSONObject(String(store.read()!!)).getJSONObject("activeSession").getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0)
  assertEquals(unit,set.getString("quantityUnit"));assertEquals(20,set.getInt("reps"))
  val id=set.getString("id")
  val other=if(unit=="meters") "reps" else "meters"
  repo.reviseCurrentSet(id,12,kg,other)
  set=JSONObject(String(store.read()!!)).getJSONObject("activeSession").getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0)
  assertEquals(id,set.getString("id"));assertEquals(other,set.getString("quantityUnit"));assertEquals(12,set.getInt("reps"))
 }
 @Test fun walkingLungeAcceptsMetersAndRepsWithWeight()=checkMovement("Walking lunge","Mancuernas","meters",16.0)
 @Test fun bearCrawlAcceptsMetersWithoutWeight()=checkMovement("Bear crawl","Peso corporal","meters",null)
 @Test fun broadJumpAcceptsRepsAndMeters()=checkMovement("Burpee broad jump","Peso corporal","reps",null)
}
