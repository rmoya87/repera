package dev.repera.mobile
import dev.repera.domain.*
internal data class SleepPeriodSummary(val nights:List<RecoverySleepNight>,val outsideRange:Boolean) {
 val hours:Double? get()=nights.map {it.hours}.takeIf {it.isNotEmpty()}?.average()
 val deep:Double get()=nights.map {it.deepHours}.takeIf {it.isNotEmpty()}?.average() ?: 0.0
 val rem:Double get()=nights.map {it.remHours}.takeIf {it.isNotEmpty()}?.average() ?: 0.0
 val light:Double get()=nights.map {(it.hours-it.deepHours-it.remHours).coerceAtLeast(0.0)}.takeIf {it.isNotEmpty()}?.average() ?: 0.0
 companion object {
  fun forRange(nights:List<RecoverySleepNight>,range:ProgressTimeRange,today:java.time.LocalDate,monday:Boolean):SleepPeriodSummary {
   val ordered=nights.sortedBy {it.day}
   val inRange=ordered.filter {range.contains(it.day,today,monday)}
   return SleepPeriodSummary(if(inRange.isNotEmpty()) inRange else ordered.takeLast(14),inRange.isEmpty() && ordered.isNotEmpty())
  }
 }
}
