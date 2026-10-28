package dev.repera.mobile
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Record intervals may cross midnight; the sample timestamp owns its day. */
internal object DailyHeartRates {
 fun points(samples:List<Pair<Long,Double>>,zone:ZoneId):List<DailyHeartRatePoint> = samples
  .filter {it.second.isFinite() && it.second>0}
  .groupBy {Instant.ofEpochMilli(it.first).atZone(zone).toLocalDate()}
  .toSortedMap().map {(day,values) ->
   val bpm=values.map {it.second}
   DailyHeartRatePoint(day,bpm.average(),bpm.min(),bpm.max())
  }
}
