package dev.repera.mobile
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class PlannedWorkoutStatusTest {
 private fun session()=JSONObject().put("id","s").put("title","Fuerza").put("startedAt","2026-10-27T18:00:00Z")
  .put("currentIndex",1).put("exercises",JSONArray()
   .put(JSONObject().put("exercise",JSONObject().put("name","Sentadilla")).put("loggedSets",JSONArray().put(JSONObject())))
   .put(JSONObject().put("exercise",JSONObject().put("name","Press")).put("loggedSets",JSONArray())))
 @Test fun usesOnlyActualSessionCounters() {
  val s=PlannedWorkoutStatus.fromState(JSONObject().put("activeSession",session()))!!
  assertEquals("Fuerza",s.title);assertEquals("Press",s.exercise);assertEquals("2/2",s.exerciseProgress);assertEquals(1,s.completedSets)
  assertEquals(1793124000000L,s.startedEpochMillis)
 }
 @Test fun notStartedFinishedAndAbsentDoNotPublish() {
  assertNull(PlannedWorkoutStatus.fromState(JSONObject()))
  assertNull(PlannedWorkoutStatus.fromState(JSONObject().put("activeSession",session().put("finishedAt","2026-10-27T19:00:00Z"))))
  assertNull(PlannedWorkoutStatus.fromState(JSONObject().put("activeSession",session().put("startedAt","invalid"))))
 }
}
