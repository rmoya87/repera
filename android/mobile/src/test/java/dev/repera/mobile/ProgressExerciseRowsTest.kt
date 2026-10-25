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
}
