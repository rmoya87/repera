package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class ActiveSessionPlanTest {
 private fun e(id:String,block:String,reps:Int=0)=JSONObject().put("id","$id-$block").put("blockId",block)
  .put("exercise",JSONObject().put("id",id).put("name",id))
  .put("loggedSets",JSONArray().apply {if(reps>0) put(JSONObject().put("id","set-$block-$id").put("reps",reps))})
  .put("completedReps",reps).put("isCompleted",reps>0)
 @Test fun reorderAndRemovePreserveCurrentByIdentityAndNeverDuplicateLoggedWork() {
  val session=JSONObject().put("id","session").put("startedAt","2026-10-25T20:00:00Z").put("notes","nota")
   .put("phase","counting").put("currentIndex",1).put("wodResults",JSONArray().put(JSONObject().put("score",8)))
   .put("exercises",JSONArray().put(e("a","one",5)).put(e("b","two",6)).put(e("a","three",7)))
  val fresh=JSONObject().put("routineBlocks",JSONArray().put(JSONObject().put("id","three")))
   .put("exercises",JSONArray().put(e("a","three")).put(e("b","new"))).put("currentIndex",0)
  ActiveSessionPlan.refresh(session,fresh)
  val result=session.getJSONArray("exercises")
  assertEquals(2,result.length());assertEquals(7,result.getJSONObject(0).getInt("completedReps"))
  assertEquals(6,result.getJSONObject(1).getInt("completedReps"));assertEquals(1,session.getInt("currentIndex"))
  assertEquals("set-three-a",result.getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0).getString("id"))
  assertEquals("session",session.getString("id"));assertEquals("counting",session.getString("phase"))
  assertEquals("nota",session.getString("notes"));assertEquals(8,session.getJSONArray("wodResults").getJSONObject(0).getInt("score"))
 }
 @Test fun repeatedMovementConsumesPriorOnlyOnceAndRemovedSelectionClamps() {
  val session=JSONObject().put("currentIndex",1).put("exercises",JSONArray().put(e("a","one",5)).put(e("removed","old",7)))
  val fresh=JSONObject().put("routineBlocks",JSONArray()).put("exercises",JSONArray().put(e("a","one")).put(e("a","two")))
  ActiveSessionPlan.refresh(session,fresh)
  assertEquals(5,session.getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
  assertEquals(0,session.getJSONArray("exercises").getJSONObject(1).getInt("completedReps"))
  assertEquals(1,session.getInt("currentIndex"))
 }
 @Test fun stableItemIdsKeepResultsWhenRepeatedExerciseIsReordered() {
  fun item(id:String,reps:Int)=JSONObject().put("id",id).put("blockId","b").put("exercise",JSONObject().put("id","sq").put("name","Sentadilla"))
   .put("loggedSets",JSONArray().apply {if(reps>0) put(JSONObject().put("id","s$id").put("reps",reps))}).put("completedReps",reps).put("isCompleted",reps>0)
  val session=JSONObject().put("currentIndex",1).put("exercises",JSONArray().put(item("i1",5)).put(item("i2",8)))
  val fresh=JSONObject().put("routineBlocks",JSONArray()).put("exercises",JSONArray().put(item("i2",0)).put(item("i1",0)))
  ActiveSessionPlan.refresh(session,fresh)
  val r=session.getJSONArray("exercises")
  assertEquals(8,r.getJSONObject(0).getInt("completedReps"));assertEquals(5,r.getJSONObject(1).getInt("completedReps"))
  assertEquals(0,session.getInt("currentIndex"))
 }
 @Test fun legacyRandomIdsStillMatchByExerciseOnce() {
  fun item(id:String,reps:Int)=JSONObject().put("id",id).put("blockId","b").put("exercise",JSONObject().put("id","sq").put("name","Sentadilla"))
   .put("loggedSets",JSONArray()).put("completedReps",reps).put("isCompleted",reps>0)
  val session=JSONObject().put("currentIndex",0).put("exercises",JSONArray().put(item("old1",5)).put(item("old2",8)))
  val fresh=JSONObject().put("routineBlocks",JSONArray()).put("exercises",JSONArray().put(item("n1",0)).put(item("n2",0)))
  ActiveSessionPlan.refresh(session,fresh)
  val r=session.getJSONArray("exercises")
  assertEquals(5,r.getJSONObject(0).getInt("completedReps"));assertEquals(8,r.getJSONObject(1).getInt("completedReps"))
 }
}
