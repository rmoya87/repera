package dev.repera.mobile
import dev.repera.domain.*
import java.time.*
internal object RecoveryTrend {
 fun points(nights:List<RecoverySleepNight>,vitals:List<RecoveryEngine.DailyVitals>,workouts:List<StatsWorkout>,
            external:List<RecoveryEngine.ObservedActivity>,now:Instant,zone:ZoneId):List<ProgressDayPoint> {
  val average=nights.takeLast(14).map {it.hours}.takeIf {it.isNotEmpty()}?.average()
  return nights.sortedBy {it.day}.mapNotNull {night ->
   val morning=night.day.atTime(7,0).atZone(zone).toInstant()
   if(morning>now) null else RecoveryEngine.trainingReadiness(morning.toEpochMilli(),night.hours,average,workouts,vitals,external,zone)
    ?.let {ProgressDayPoint(night.day,it.score)}
  }
 }
}
