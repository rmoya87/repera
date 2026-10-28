package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
import java.time.*
import dev.repera.domain.ProgressTimeRange
class ProgressExerciseRowsTest {
 @Test fun recentlyUsedExercisePrecedesAlphabeticalNameAndOutOfPeriodIsExcluded() {
  fun w(id:String,name:String,date:String)=JSONObject().put("phase","finished").put("startedAt",date).put("finishedAt",date)
   .put("exercises",JSONArray().put(JSONObject().put("exercise",JSONObject().put("id",id).put("name",name))
    .put("loggedSets",JSONArray().put(JSONObject().put("id","set").put("reps",5).put("weightKg",60).put("phase","work")))))
  val state=JSONObject().put("exercises",JSONArray()).put("workouts",JSONArray()
   .put(w("a","Alfabético","2026-10-20T09:00:00Z")).put(w("z","Último","2026-10-25T09:00:00Z"))
   .put(w("old","Fuera","2026-10-01T09:00:00Z")))
  val rows=ProgressSnapshotBuilder.build(state,ProgressTimeRange.WEEK,LocalDate.of(2026,10,25),ZoneId.of("Europe/Madrid")).chartExercises
  assertEquals(listOf("z","a"),rows.map {it.id});assertEquals(60.0,rows.first().topWeight!!,0.0)
 }
 @Test fun plannedOnlyOrWarmupOnlyExercisesAreNotChartExercisesAndDateIsLastPracticed() {
  fun ex(id:String,sets:JSONArray,planned:Boolean=false)=JSONObject().put("exercise",JSONObject().put("id",id).put("name",id))
   .put("loggedSets",sets).apply {if(planned) put("plannedSets",JSONArray().put(JSONObject().put("id","p").put("targetReps",5)))}
  fun set(phase:String)=JSONObject().put("id","s$phase").put("reps",5).put("weightKg",50).put("phase",phase)
  fun w(date:String,vararg e:JSONObject)=JSONObject().put("phase","finished").put("startedAt",date).put("finishedAt",date)
   .put("exercises",JSONArray().apply {e.forEach {put(it)}})
  val state=JSONObject().put("exercises",JSONArray()).put("workouts",JSONArray()
   .put(w("2026-10-20T09:00:00Z",ex("press",JSONArray().put(set("work")))))
   .put(w("2026-10-24T09:00:00Z",ex("press",JSONArray().put(set("warmup"))),ex("warm",JSONArray().put(set("warmup")))))
   .put(w("2026-10-25T09:00:00Z",ex("press",JSONArray().put(set("warmup")))))
  )
  val rows=ProgressSnapshotBuilder.build(state,ProgressTimeRange.WEEK,LocalDate.of(2026,10,25),ZoneId.of("Europe/Madrid")).chartExercises
  assertEquals(listOf("press"),rows.map {it.id})
  assertEquals(Instant.parse("2026-10-20T09:00:00Z").toEpochMilli(),rows.single().lastEpochMillis)
 }
}
