package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class ConfirmedWorkSetsTest {
 private fun entry(logged:JSONArray)=JSONObject().put("id","e").put("blockKind","strength")
  .put("exercise",JSONObject().put("id","sq").put("name","Sentadilla").put("muscleGroup","Pierna"))
  .put("plannedSets",JSONArray().put(JSONObject().put("id","p1").put("targetReps",5).put("targetWeightKg",100.0)).put(JSONObject().put("id","p2").put("targetReps",5).put("targetWeightKg",100.0)))
  .put("loggedSets",logged)
 private fun workout(finished:Boolean,e:JSONObject)=JSONObject().put("id","w").put("startedAt","2026-10-25T10:00:00Z")
  .apply {if(finished) put("phase","finished").put("finishedAt","2026-10-25T11:00:00Z") else put("phase","counting")}
  .put("exercises",JSONArray().put(e))
 @Test fun finishedWithoutRecordsAcceptsPrescribedAndStatsVolumeAgrees() {
  val w=workout(true,entry(JSONArray()))
  assertEquals(2,WorkoutHistorySets.confirmedWorkSets(w,w.getJSONArray("exercises").getJSONObject(0)).size)
  val stats=ProgressSnapshotBuilder.statsWorkouts(JSONObject().put("workouts",JSONArray().put(w)))
  assertEquals(1000.0,stats.single().totalVolumeKg,0.0)
 }
 @Test fun unfinishedNeverConfirmsAndWarmupOnlyDoesNotConfirmPrescribed() {
  val u=workout(false,entry(JSONArray()))
  assertTrue(WorkoutHistorySets.confirmedWorkSets(u,u.getJSONArray("exercises").getJSONObject(0)).isEmpty())
  val warm=workout(true,entry(JSONArray().put(JSONObject().put("id","s").put("reps",8).put("phase","warmup"))))
  assertTrue(WorkoutHistorySets.confirmedWorkSets(warm,warm.getJSONArray("exercises").getJSONObject(0)).isEmpty())
  val real=workout(true,entry(JSONArray().put(JSONObject().put("id","s").put("reps",3).put("weightKg",50.0))))
  assertEquals(1,WorkoutHistorySets.confirmedWorkSets(real,real.getJSONArray("exercises").getJSONObject(0)).size)
  assertEquals(150.0,ProgressSnapshotBuilder.statsWorkouts(JSONObject().put("workouts",JSONArray().put(real))).single().totalVolumeKg,0.0)
 }
}
class ConfirmedWorkSetsConsumersTest {
 private fun ex(logged:org.json.JSONArray)=JSONObject().put("id","e").put("blockKind","strength")
  .put("exercise",JSONObject().put("id","sq").put("name","Sentadilla").put("muscleGroup","Pierna"))
  .put("plannedSets",JSONArray().put(JSONObject().put("id","p1").put("targetReps",5).put("targetWeightKg",100.0)))
  .put("loggedSets",logged)
 private fun w(e:JSONObject)=JSONObject().put("id","w").put("startedAt","2026-10-25T10:00:00Z").put("phase","finished")
  .put("finishedAt","2026-10-25T11:00:00Z").put("exercises",JSONArray().put(e))
 @Test fun exerciseSummaryIgnoresPrescribedWhenOnlyWarmupsWereLogged() {
  val warm=JSONArray().put(JSONObject().put("id","s").put("reps",8).put("phase","warmup"))
  assertTrue(ExerciseProgressMetrics.fromWorkouts(JSONArray().put(w(ex(warm)))).isEmpty())
  val none=ExerciseProgressMetrics.fromWorkouts(JSONArray().put(w(ex(JSONArray()))))
  assertEquals(1,none["sq"]!!.timesPerformed)
 }
 @Test fun exerciseSeriesIgnoresPrescribedWhenOnlyWarmupsWereLogged() {
  val warm=JSONArray().put(JSONObject().put("id","s").put("reps",8).put("phase","warmup"))
  val range=ExerciseProgressRange.entries.first()
  val now=java.time.LocalDate.of(2026,10,26)
  assertTrue(ExerciseProgressSeries.compute(JSONArray().put(w(ex(warm))),"sq",ExerciseProgressMetric.TOP_SET,range,now).isEmpty())
  assertFalse(ExerciseProgressSeries.compute(JSONArray().put(w(ex(JSONArray()))),"sq",ExerciseProgressMetric.TOP_SET,range,now).isEmpty())
 }
}

class ConfirmedWorkSetsMuscleEngineTest {
 private fun ex(logged:JSONArray)=JSONObject().put("id","e").put("blockKind","strength")
  .put("exercise",JSONObject().put("id","sq").put("name","Sentadilla").put("muscleGroup","Pierna").put("targetMuscle","Cuádriceps"))
  .put("plannedSets",JSONArray().put(JSONObject().put("id","p1").put("targetReps",5).put("targetWeightKg",100.0)))
  .put("loggedSets",logged)
 private fun w(finished:Boolean,e:JSONObject)=JSONObject().put("id","w").put("startedAt","2026-10-25T10:00:00Z")
  .apply {if(finished) put("phase","finished").put("finishedAt","2026-10-25T11:00:00Z") else put("phase","counting")}
  .put("exercises",JSONArray().put(e))
 private fun fatigue(w:JSONObject):Map<String,Double> {
  val now=java.time.LocalDate.of(2026,10,26); val zone=java.time.ZoneId.of("Europe/Madrid")
  return ProgressSnapshotBuilder.build(JSONObject().put("workouts",JSONArray().put(w)),dev.repera.domain.ProgressTimeRange.DAYS_90,now,zone,
   now.atTime(12,0).atZone(zone).toInstant().toEpochMilli()).muscleFatigueAll
 }
 @Test fun warmupOnlyAndUnfinishedContributeNoFatigue() {
  val warm=w(true,ex(JSONArray().put(JSONObject().put("id","s").put("reps",8).put("phase","warmup"))))
  assertTrue(fatigue(warm).isEmpty())
  val unfinished=w(false,ex(JSONArray().put(JSONObject().put("id","s").put("reps",8).put("weightKg",60.0))))
  assertTrue(fatigue(unfinished).isEmpty())
  val real=w(true,ex(JSONArray().put(JSONObject().put("id","s").put("reps",8).put("weightKg",60.0))))
  assertTrue(fatigue(real).isNotEmpty())
 }
}

class ConfirmedWorkSetsPrAndWorkloadTest {
 private fun ex(logged:JSONArray)=JSONObject().put("id","e").put("blockKind","strength")
  .put("exercise",JSONObject().put("id","sq").put("name","Sentadilla").put("muscleGroup","Pierna").put("targetMuscle","Cuádriceps"))
  .put("plannedSets",JSONArray().put(JSONObject().put("id","p1").put("targetReps",5).put("targetWeightKg",100.0)).put(JSONObject().put("id","p2").put("targetReps",5).put("targetWeightKg",100.0)))
  .put("loggedSets",logged)
 private fun w(finished:Boolean,e:JSONObject)=JSONObject().put("id","w").put("startedAt","2026-10-25T10:00:00Z")
  .apply {if(finished) put("phase","finished").put("finishedAt","2026-10-25T11:00:00Z") else put("phase","counting")}
  .put("exercises",JSONArray().put(e))
 private fun prs(w:JSONObject)=dev.repera.domain.StatsEngine.personalRecords(ProgressSnapshotBuilder.statsWorkouts(JSONObject().put("workouts",JSONArray().put(w))))
 @Test fun personalRecordFromPrescribedOnlyFinishedSessionOnlyWhenFinishedAndNotWarmupOnly() {
  assertEquals(1,prs(w(true,ex(JSONArray()))).size)
  assertEquals(100.0,prs(w(true,ex(JSONArray()))).single().weightKg,0.0)
  assertTrue(prs(w(false,ex(JSONArray()))).isEmpty())
  assertTrue(prs(w(true,ex(JSONArray().put(JSONObject().put("id","s").put("reps",8).put("phase","warmup"))))).isEmpty())
 }
 @Test fun weeklyWorkloadCountsPrescribedSetsForFinishedOnlyAndNotWarmupOnly() {
  val today=java.time.LocalDate.of(2026,10,25);val zone=java.time.ZoneId.of("Europe/Madrid") // Sunday: the Mon 19 - Sun 25 week holds the 25th
  fun sets(w:JSONObject)=MuscleWorkloadMetrics.weekly(JSONArray().put(w),today,zone).sumOf {it.sets}
  assertEquals(2,sets(w(true,ex(JSONArray()))))
  assertEquals(0,sets(w(false,ex(JSONArray()))))
  assertEquals(0,sets(w(true,ex(JSONArray().put(JSONObject().put("id","s").put("reps",8).put("phase","warmup"))))))
 }
}

/** Apple CompletedWODMuscleStimulusTests.testFinishedInputValuesCountAcrossEveryOccurrenceOfSameExercise (live main). */
class RepeatedOccurrenceProgressTest {
 private fun occ(block:String,vararg sets:Pair<Int,Double>)=JSONObject().put("id","e$block").put("blockKind","wod")
  .put("exercise",JSONObject().put("id","snatch").put("name","Power Snatch").put("muscleGroup","Pierna"))
  .put("plannedSets",JSONArray().apply{sets.forEachIndexed{i,(r,k)->put(JSONObject().put("id","p$block$i").put("targetReps",r).put("targetWeightKg",k))}})
  .put("loggedSets",JSONArray())
 private val workout=JSONObject().put("id","w").put("startedAt","2026-10-25T10:00:00Z").put("phase","finished")
  .put("finishedAt","2026-10-25T11:00:00Z").put("exercises",JSONArray().put(occ("a",1 to 30.0,1 to 60.0)).put(occ("b",5 to 50.0,5 to 50.0)))
 private val archive=JSONArray().put(workout)
 private val now=java.time.LocalDate.of(2026,10,26)
 private val range=ExerciseProgressRange.entries.last()
 @Test fun summaryCountsEveryOccurrenceOnce() {
  val s=ExerciseProgressMetrics.fromWorkouts(archive)["snatch"]!!
  assertEquals(1,s.timesPerformed); assertEquals(60.0,s.maxWeightKg!!,0.0); assertEquals(5,s.bestReps)
 }
 @Test fun seriesIsOnePointPerSessionAcrossOccurrences() {
  val total=ExerciseProgressSeries.compute(archive,"snatch",ExerciseProgressMetric.TOTAL_QUANTITY,range,now)
  assertEquals(1,total.size); assertEquals(12.0,total.single().value,0.0)
  val top=ExerciseProgressSeries.compute(archive,"snatch",ExerciseProgressMetric.TOP_SET,range,now)
  assertEquals(1,top.size); assertEquals(60.0,top.single().value,0.0)
 }
 @Test fun displayLinesStillOmitWodPrescribed() {
  assertTrue(WorkoutHistorySets.displayLines(workout,workout.getJSONArray("exercises").getJSONObject(0)).isEmpty())
 }
}
