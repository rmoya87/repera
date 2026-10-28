package dev.repera.mobile
import dev.repera.domain.ProgressDayPoint
import dev.repera.domain.ProgressTimeRange
import org.json.JSONObject
import java.time.*
import kotlin.math.roundToInt
/** Apple StatsView: only personal-history reviews, grouped on finishedAt, daily rounded mean. */
internal object SessionScoreProgress {
 fun points(state:JSONObject,range:ProgressTimeRange,monday:Boolean,now:LocalDate=LocalDate.now(),zone:ZoneId=ZoneId.systemDefault()):List<ProgressDayPoint> {
  val archive=state.optJSONArray("workouts") ?: return emptyList()
  val rated=(0 until archive.length()).mapNotNull {i ->
   val w=archive.getJSONObject(i);val review=w.optJSONObject("sessionReview") ?: return@mapNotNull null
   if(review.optString("scoreBasis")!="personalHistory") return@mapNotNull null
   val date=runCatching {Instant.parse(w.getString("finishedAt")).atZone(zone).toLocalDate()}.getOrNull() ?: return@mapNotNull null
   val score=review.optDouble("overallScore")
   if(!score.isFinite() || score !in 0.0..10.0 || !range.contains(date,now,monday)) return@mapNotNull null
   date to score
  }
  return rated.groupBy {it.first}.toSortedMap().map {(day,values) ->ProgressDayPoint(day,values.map {it.second}.average().roundToInt().toDouble())}
 }
}
