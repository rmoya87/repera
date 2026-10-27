package dev.repera.mobile
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDate
import java.time.ZoneId

class MuscleWorkloadMetricsTest {
 private val today=LocalDate.of(2026,10,27)
 private val zone=ZoneId.of("Europe/Madrid")
 private fun entry(blockKind:String?,blockId:String?,logged:JSONArray=JSONArray())=JSONObject()
  .put("id","e1").put("blockId",blockId ?: JSONObject.NULL)
  .apply {if(blockKind!=null) put("blockKind",blockKind)}
  .put("exercise",JSONObject().put("id","sq").put("name","Sentadilla").put("muscleGroup","Piernas"))
  .put("plannedSets",JSONArray()).put("loggedSets",logged)
 private fun session(phase:String,finished:Boolean,e:JSONObject,wodResults:JSONArray=JSONArray())=JSONObject()
  .put("id","w1").put("phase",phase)
  .put("startedAt","2026-10-27T08:00:00Z")
  .apply {if(finished) put("finishedAt","2026-10-27T09:00:00Z")}
  .put("exercises",JSONArray().put(e)).put("wodResults",wodResults)
 private fun workSet(id:String)=JSONObject().put("id",id).put("reps",5).put("phase","work")

 @Test fun completedWodWithoutSetsCountsOneEstimated() {
  val r=MuscleWorkloadMetrics.weekly(JSONArray().put(session("finished",true,entry("wod","b1"))),today,zone)
  assertEquals(1,r.size);assertEquals("Piernas",r[0].group);assertEquals(1,r[0].sets)
 }
 @Test fun wodWithRealSetsCountsRealNotEstimated() {
  val logged=JSONArray().put(workSet("s1")).put(workSet("s2")).put(workSet("s3"))
  val r=MuscleWorkloadMetrics.weekly(JSONArray().put(session("finished",true,entry("wod","b1",logged))),today,zone)
  assertEquals(1,r.size);assertEquals(3,r[0].sets)
 }
 @Test fun nonWodEntryWithoutSetsCountsNothing() {
  val r=MuscleWorkloadMetrics.weekly(JSONArray().put(session("finished",true,entry("strength","b1"))),today,zone)
  assertTrue(r.isEmpty())
 }
 @Test fun unfinishedSessionCountsNothing() {
  val r=MuscleWorkloadMetrics.weekly(JSONArray().put(session("counting",false,entry("wod","b1"))),today,zone)
  assertTrue(r.isEmpty())
 }
 @Test fun wodResultLinkedEntryWithoutSetsCountsOne() {
  val results=JSONArray().put(JSONObject().put("id","b1").put("score","12:34"))
  val r=MuscleWorkloadMetrics.weekly(JSONArray().put(session("finished",true,entry(null,"b1"),results)),today,zone)
  assertEquals(1,r.size);assertEquals(1,r[0].sets)
 }
 @Test fun unlinkedEntryWithoutWodBlockCountsNothing() {
  val results=JSONArray().put(JSONObject().put("id","other"))
  val r=MuscleWorkloadMetrics.weekly(JSONArray().put(session("finished",true,entry(null,"b1"),results)),today,zone)
  assertTrue(r.isEmpty())
 }
}
