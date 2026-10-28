package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
import java.time.*
import dev.repera.domain.ProgressTimeRange
class SessionScoreProgressTest {
 @Test fun onlyPersonalHistoryAndFinishedDateCountWithDailyRoundedAverage() {
  fun w(score:Int,basis:String="personalHistory",end:String="2026-10-25T09:00:00Z")=JSONObject().put("finishedAt",end)
   .put("sessionReview",JSONObject().put("scoreBasis",basis).put("overallScore",score))
  val state=JSONObject().put("workouts",JSONArray().put(w(6)).put(w(9)).put(w(10,"general"))
   .put(w(10,end="2026-10-01T09:00:00Z")).put(w(9,end="bad")))
  val points=SessionScoreProgress.points(state,ProgressTimeRange.WEEK,true,LocalDate.of(2026,10,25),ZoneId.of("Europe/Madrid"))
  assertEquals(1,points.size);assertEquals(8.0,points.single().value,0.0)
 }
}
