package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class ActiveSessionDraftTest {
 private fun sets(vararg r:Int)=JSONArray().apply {r.forEach {put(JSONObject().put("reps",it))}}
 private fun session():JSONObject {
  fun ex(id:String)=JSONObject().put("id",id).put("blockId","b").put("exercise",JSONObject().put("id","sq").put("name","Sentadilla")).put("plannedSets",sets(5)).put("loggedSets",JSONArray().put(JSONObject().put("reps",5)))
  val block=JSONObject().put("id","b").put("kind","strength").put("exercises",JSONArray()
   .put(JSONObject().put("id","i1").put("exerciseId","sq").put("plannedSets",sets(5)))
   .put(JSONObject().put("id","i2").put("exerciseId","sq").put("plannedSets",sets(5))))
  return JSONObject().put("exercises",JSONArray().put(ex("i1")).put(ex("i2"))).put("routineBlocks",JSONArray().put(block))
 }
 @Test fun editsOnlyTheItemWithThatIdAndKeepsLoggedResults() {
  val s=session()
  assertTrue(ActiveSessionDraft.update(s,"i2",sets(8,8),"reps"))
  val e=s.getJSONArray("exercises");assertEquals(1,e.getJSONObject(0).getJSONArray("plannedSets").length())
  assertEquals(2,e.getJSONObject(1).getJSONArray("plannedSets").length())
  assertEquals(1,e.getJSONObject(1).getJSONArray("loggedSets").length())
  val items=s.getJSONArray("routineBlocks").getJSONObject(0).getJSONArray("exercises")
  assertEquals(1,items.getJSONObject(0).getJSONArray("plannedSets").length());assertEquals(2,items.getJSONObject(1).getJSONArray("plannedSets").length())
 }
 @Test fun draftEditNeverRewritesRecordedSetsContent() { // Apple testDraftNeverReplacesConfirmedLoggedSets
  val s=session()
  val before=s.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").toString()
  assertTrue(ActiveSessionDraft.update(s,"i1",sets(7,10,6),null))
  val e=s.getJSONArray("exercises").getJSONObject(0)
  assertEquals(before,e.getJSONArray("loggedSets").toString())
  assertEquals(3,e.getJSONArray("plannedSets").length())
 }
 @Test fun emptyListIsPersistedAndSameValueReportsNoChange() {
  val s=session()
  assertTrue(ActiveSessionDraft.update(s,"i1",JSONArray(),null))
  assertEquals(0,s.getJSONArray("exercises").getJSONObject(0).getJSONArray("plannedSets").length())
  assertFalse(ActiveSessionDraft.update(s,"i1",JSONArray(),null))
  assertFalse(ActiveSessionDraft.update(s,"missing",sets(1),null))
 }
 @Test fun legacyIdFallsBackToOccurrenceAndWodWritesExplicitPlannedSets() {
  val s=session();s.getJSONArray("exercises").getJSONObject(1).put("id","legacy")
  assertTrue(ActiveSessionDraft.update(s,"legacy",sets(9),null))
  val items=s.getJSONArray("routineBlocks").getJSONObject(0).getJSONArray("exercises")
  assertEquals(9,items.getJSONObject(1).getJSONArray("plannedSets").getJSONObject(0).getInt("reps"))
  assertEquals(5,items.getJSONObject(0).getJSONArray("plannedSets").getJSONObject(0).getInt("reps"))
  val w=JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","m1").put("blockId","w").put("exercise",JSONObject().put("id","x").put("name","Thruster")).put("plannedSets",sets(1))))
   .put("routineBlocks",JSONArray().put(JSONObject().put("id","w").put("kind","wod").put("movements",JSONArray().put(JSONObject().put("id","m1").put("name","Thruster")))))
  assertTrue(ActiveSessionDraft.update(w,"m1",sets(12),null))
  assertEquals(12,w.getJSONArray("routineBlocks").getJSONObject(0).getJSONArray("movements").getJSONObject(0).getJSONArray("explicitPlannedSets").getJSONObject(0).getInt("reps"))
 }
 @Test fun reviseDropsPercentOnlyWhenAbsoluteKgChangesAndKeepsCompletedIds() {
  val existing=JSONArray().put(JSONObject().put("id","p1").put("targetReps",5).put("targetWeightKg",100.0).put("targetPercent1RM",80.0).put("targetPercent1RMIsMinimum",true))
   .put(JSONObject().put("id","p2").put("targetReps",5).put("targetWeightKg",100.0).put("targetPercent1RM",80.0))
  val out=ActiveSessionDraft.revise(existing,listOf(
   ActiveSessionDraft.Row("r1",5,weightKg=100.0,completed=true),
   ActiveSessionDraft.Row("r2",0,weightKg=102.5)),"weightKg")
  assertEquals("p1",out.getJSONObject(0).getString("id"));assertEquals(80.0,out.getJSONObject(0).getDouble("targetPercent1RM"),0.0)
  assertTrue(out.getJSONObject(0).getBoolean("targetPercent1RMIsMinimum"))
  assertEquals("r2",out.getJSONObject(1).getString("id"));assertFalse(out.getJSONObject(1).has("targetPercent1RM"))
  assertEquals(1,out.getJSONObject(1).getInt("targetReps"))
  assertEquals(0,ActiveSessionDraft.revise(existing,emptyList(),"weightKg").length())
 }
 @Test fun replaceRecordedSetsCountsWorkPhaseAndDropsOnly() {
  val s=session()
  val sets=JSONArray().put(JSONObject().put("reps",5)).put(JSONObject().put("reps",3).put("phase","warmup"))
   .put(JSONObject().put("reps",6).put("kind","dropset").put("drops",JSONArray().put(JSONObject().put("reps",4))))
  assertTrue(ActiveSessionDraft.replaceRecordedSets(s,"i1",sets))
  assertEquals(15,s.getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
  assertFalse(ActiveSessionDraft.replaceRecordedSets(s,"i1",sets))
  assertFalse(ActiveSessionDraft.replaceRecordedSets(s,"zz",sets))
  assertTrue(ActiveSessionDraft.replaceRecordedSets(s,"i1",JSONArray()))
  assertEquals(0,s.getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
 }
 @Test fun removePendingOnlyDropsUncoveredPlannedSetsAndKeepsResults() {
  val s=session()
  val e=s.getJSONArray("exercises").getJSONObject(0)
  e.put("plannedSets",JSONArray().put(JSONObject().put("id","a").put("targetReps",5)).put(JSONObject().put("id","b").put("targetReps",5)).put(JSONObject().put("id","c").put("targetReps",5)))
  e.put("loggedSets",JSONArray().put(JSONObject().put("id","l1").put("reps",5)))
  assertFalse(ActiveSessionDraft.removePending(s,"i1","a"))
  assertFalse(ActiveSessionDraft.removePending(s,"i1","zz"))
  assertTrue(ActiveSessionDraft.removePending(s,"i1","b"))
  assertEquals(listOf("a","c"),(0 until 2).map {e.getJSONArray("plannedSets").getJSONObject(it).getString("id")})
  assertEquals(1,e.getJSONArray("loggedSets").length())
  assertTrue(ActiveSessionDraft.removePending(s,"i1","c"))
  assertEquals(1,e.getJSONArray("plannedSets").length())
 }
 private fun planned(vararg ids:String)=JSONArray().apply {ids.forEach {put(JSONObject().put("id",it).put("targetReps",5))}}
 @Test fun removePendingIgnoresWarmupsAndCountsDropSetOnce() {
  val s=session();val e=s.getJSONArray("exercises").getJSONObject(0)
  e.put("plannedSets",planned("a","b","c"))
  e.put("loggedSets",JSONArray().put(JSONObject().put("id","w").put("reps",5).put("phase","warmup"))
   .put(JSONObject().put("id","d").put("reps",5).put("kind","dropset").put("drops",JSONArray().put(JSONObject().put("reps",4)))))
  // 1 work set recorded (warmup excluded, drop set = one set): "a" is covered, "b" is pending
  assertFalse(ActiveSessionDraft.removePending(s,"i1","a"))
  assertTrue(ActiveSessionDraft.removePending(s,"i1","b"))
  assertEquals(2,e.getJSONArray("loggedSets").length())
 }
 @Test fun removePendingTargetsTheRequestedExerciseWhenItemsRepeatAndAfterDeletingALoggedSet() {
  val s=session()
  val a=s.getJSONArray("exercises").getJSONObject(0);val b=s.getJSONArray("exercises").getJSONObject(1)
  a.put("plannedSets",planned("a1","a2"));b.put("plannedSets",planned("b1","b2"))
  a.put("loggedSets",JSONArray());b.put("loggedSets",JSONArray())
  assertTrue(ActiveSessionDraft.removePending(s,"i2","b1"))
  assertEquals(2,a.getJSONArray("plannedSets").length());assertEquals(1,b.getJSONArray("plannedSets").length())
  assertFalse(ActiveSessionDraft.removePending(s,"i1","b2"))
  // a logged set is recorded then deleted: its planned slot becomes pending again
  a.put("loggedSets",JSONArray().put(JSONObject().put("id","l").put("reps",5)))
  assertFalse(ActiveSessionDraft.removePending(s,"i1","a1"))
  a.put("loggedSets",JSONArray())
  assertTrue(ActiveSessionDraft.removePending(s,"i1","a1"))
 }
 @Test fun editPendingChangesOnlyUncoveredRowAndDropsPercentOnlyWhenKgChanges() {
  val s=session();val e=s.getJSONArray("exercises").getJSONObject(0)
  e.put("plannedSets",JSONArray().put(JSONObject().put("id","a").put("targetReps",5).put("targetWeightKg",100.0).put("targetPercent1RM",80.0))
   .put(JSONObject().put("id","b").put("targetReps",5).put("targetWeightKg",100.0).put("targetPercent1RM",80.0).put("targetPercent1RMIsMinimum",true)))
  e.put("loggedSets",JSONArray().put(JSONObject().put("id","l").put("reps",5)))
  assertFalse(ActiveSessionDraft.editPending(s,"i1","a",8,100.0,true))
  assertTrue(ActiveSessionDraft.editPending(s,"i1","b",0,100.0,true))
  val b=e.getJSONArray("plannedSets").getJSONObject(1)
  assertEquals(1,b.getInt("targetReps"));assertEquals(80.0,b.getDouble("targetPercent1RM"),0.0)
  assertTrue(ActiveSessionDraft.editPending(s,"i1","b",6,105.0,true))
  val b2=e.getJSONArray("plannedSets").getJSONObject(1)
  assertFalse(b2.has("targetPercent1RM"));assertFalse(b2.has("targetPercent1RMIsMinimum"));assertEquals(105.0,b2.getDouble("targetWeightKg"),0.0)
  assertEquals(100.0,e.getJSONArray("plannedSets").getJSONObject(0).getDouble("targetWeightKg"),0.0)
  assertFalse(ActiveSessionDraft.editPending(s,"i1","b",6,105.0,true))
 }
}
