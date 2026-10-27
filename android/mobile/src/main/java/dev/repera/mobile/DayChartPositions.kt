package dev.repera.mobile
import dev.repera.domain.ProgressDayPoint
import kotlin.math.abs
/** Calendar spacing remains truthful when days have no observation. */
internal object DayChartPositions {
 fun dateFraction(first:java.time.LocalDate,last:java.time.LocalDate,day:java.time.LocalDate):Float {
  val span=last.toEpochDay()-first.toEpochDay()
  if(span<=0) return 0.5f
  return ((day.toEpochDay()-first.toEpochDay()).toDouble()/span).toFloat().coerceIn(0f,1f)
 }
 fun fraction(points:List<ProgressDayPoint>,index:Int):Float =
  dateFraction(points.first().day,points.last().day,points[index].day)
 fun midpoint(points:List<ProgressDayPoint>):java.time.LocalDate =
  points.first().day.plusDays((points.last().day.toEpochDay()-points.first().day.toEpochDay())/2)
 fun nearest(points:List<ProgressDayPoint>,fraction:Float):Int = points.indices.minByOrNull {abs(fraction(points,it)-fraction.coerceIn(0f,1f))} ?: 0
}
