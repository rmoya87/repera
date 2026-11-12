package dev.repera.mobile
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
class MeasuredEnergyTest {
 private fun w(id:String,a:String,b:String)=JSONObject().put("id",id).put("startedAt",a).put("finishedAt",b)
 private fun state(vararg w:JSONObject)=JSONObject().put("workouts",JSONArray().apply {w.forEach {put(it)}})
 @Test fun writesMeasuredKcalOnceAndNeverOverwrites() {
  val s=state(w("a","2026-01-01T10:00:00Z","2026-01-01T11:00:00Z"))
  assertTrue(SessionReviewSupport.applyMeasuredEnergy(s,"a",120.0,"r1"))
  assertEquals(120.0,s.getJSONArray("workouts").getJSONObject(0).getDouble("appleActiveEnergyKcal"),0.0)
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(s,"a",300.0,"r1"))
  assertEquals(120.0,s.getJSONArray("workouts").getJSONObject(0).getDouble("appleActiveEnergyKcal"),0.0)
 }
 @Test fun lateActiveKcalFillsZeroNotWristTotalOrPulse() {
  val workout=w("a","2026-11-12T07:07:00Z","2026-11-12T07:52:00Z")
   .put("appleActiveEnergyKcal",0.0).put("wearTotalEnergyKcal",265.0)
   .put("appleAverageHeartRateBpm",103.0)
  val state=state(workout)
  assertTrue(SessionReviewSupport.applyMeasuredEnergy(state,"a",219.0,"watch"))
  assertEquals(219.0,workout.getDouble("appleActiveEnergyKcal"),0.0)
  assertEquals(265.0,workout.getDouble("wearTotalEnergyKcal"),0.0)
  assertEquals(103.0,workout.getDouble("appleAverageHeartRateBpm"),0.0)
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(state,"a",221.0,"phone"))
 }
 @Test fun ignoresMissingNonPositiveAndUnknownSession() {
  val s=state(w("a","2026-01-01T10:00:00Z","2026-01-01T11:00:00Z"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(s,"a",null,"r1"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(s,"a",0.0,"r1"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(s,"a",Double.NaN,"r1"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(s,"a",Double.POSITIVE_INFINITY,"r1"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(s,"a",Double.NEGATIVE_INFINITY,"r1"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(s,"zzz",50.0,"r1"))
  assertFalse(s.getJSONArray("workouts").getJSONObject(0).has("appleActiveEnergyKcal"))
 }
 @Test fun skipsWhenAnotherSavedWorkoutOverlapsOrTimesAreMissing() {
  val overlap=state(w("a","2026-01-01T10:00:00Z","2026-01-01T11:00:00Z"),w("b","2026-01-01T10:30:00Z","2026-01-01T11:30:00Z"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(overlap,"a",100.0,"r1"))
  val apart=state(w("a","2026-01-01T10:00:00Z","2026-01-01T11:00:00Z"),w("b","2026-01-01T11:00:00Z","2026-01-01T12:00:00Z"))
  assertTrue(SessionReviewSupport.applyMeasuredEnergy(apart,"a",100.0,"r1"))
  val noTimes=state(JSONObject().put("id","a"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(noTimes,"a",100.0,"r1"))
 }
 @Test fun skipsWhenRecordIdMissingOrAlreadyLinkedToAnotherWorkout() {
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(state(w("a","2026-01-01T10:00:00Z","2026-01-01T11:00:00Z")),"a",100.0,null))
  val linked=state(w("a","2026-01-01T10:00:00Z","2026-01-01T11:00:00Z"),
   w("b","2026-01-01T12:00:00Z","2026-01-01T13:00:00Z").put(dev.repera.domain.HealthSessionLink.SNAPSHOT_FIELD,"r1"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(linked,"a",100.0,"r1"))
  assertTrue(SessionReviewSupport.applyMeasuredEnergy(linked,"a",100.0,"r2"))
 }
 /** Demonstrates the claim the guard relies on: two DISJOINT local sessions can never both
  *  associate with the same Health record, because each needs >= max(60 s, 60% of the record). */
 @Test fun twoDisjointSessionsNeverBothMatchOneLongRecord() {
  val min=60_000L
  var checked=0
  for(recMin in listOf(1,2,3,10,60,120,300)) {
   val rec=dev.repera.domain.SessionHealthMatcher.CandidateSession("r",0L,recMin*min,"ext")
   for(s1 in listOf(1,5,30,90,200)) for(gap in listOf(0,1,10,60)) for(s2 in listOf(1,5,30,90,200)) for(off in listOf(-100,-30,0,10,45)) {
    val a0=off*min; val a1=a0+s1*min; val b0=a1+gap*min; val b1=b0+s2*min
    val m1=dev.repera.domain.SessionHealthMatcher.associate(a0,a1,listOf(rec),"own") is dev.repera.domain.SessionHealthMatcher.Association.Matched
    val m2=dev.repera.domain.SessionHealthMatcher.associate(b0,b1,listOf(rec),"own") is dev.repera.domain.SessionHealthMatcher.Association.Matched
    assertFalse("rec=$recMin s1=$s1 gap=$gap s2=$s2 off=$off",m1&&m2); checked++
   }
  }
  assertTrue(checked>500)
 }
 @Test fun correctedWindowReplacesMeasuredHeartRateAndRetainsVerifiedEnergy() {
  val w=w("a","2026-11-05T06:45:00Z","2026-11-05T07:45:00Z")
   .put("userEditedDuration",true)
   .put(dev.repera.domain.HealthSessionLink.SNAPSHOT_FIELD,"record-1")
   .put("originalSensorEnergyKcal",230.0)
   .put("originalSensorHeartRateBpm",136.0)
  val state=state(w)
  assertTrue(SessionReviewSupport.applyMeasuredEnergy(state,"a",310.0,"record-1"))
  assertTrue(SessionReviewSupport.applyMeasuredHeartRate(state,"a",142.0,"record-1"))
  assertEquals(310.0,w.getDouble("appleActiveEnergyKcal"),0.001)
  assertEquals(142.0,w.getDouble("appleAverageHeartRateBpm"),0.001)
  assertEquals(230.0,w.getDouble("originalSensorEnergyKcal"),0.001)
  assertEquals(136.0,w.getDouble("originalSensorHeartRateBpm"),0.001)
  assertFalse(SessionReviewSupport.applyMeasuredHeartRate(state,"a",999.0,"record-1"))
  assertFalse(SessionReviewSupport.applyMeasuredHeartRate(state,"a",90.0,"wrong-record"))
 }

 @Test fun cardioNoLinkedEvidenceDoesNotInventCaloriesOrHeartRate() {
  val w=w("a","2026-11-05T06:45:00Z","2026-11-05T07:45:00Z")
   .put("userEditedDuration",true)
   .put(dev.repera.domain.HealthSessionLink.SNAPSHOT_FIELD,"record-1")
  val state=state(w)
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(state,"a",null,"record-1"))
  assertFalse(SessionReviewSupport.applyMeasuredEnergy(state,"a",250.0,null))
  assertFalse(SessionReviewSupport.applyMeasuredHeartRate(state,"a",null,"record-1"))
  assertFalse(SessionReviewSupport.applyMeasuredHeartRate(state,"a",125.0,null))
  assertFalse(w.has("appleActiveEnergyKcal"))
  assertFalse(w.has("appleAverageHeartRateBpm"))
 }

}
