package dev.repera.mobile
import dev.repera.domain.*
import java.time.LocalDate
import kotlin.math.*
/** Fixed Apple teaser shapes only. Never derives preview values from private measurements. */
internal object ProgressPreview {
 fun charts(today:LocalDate,monday:Boolean):ProgressPreparedCharts {
  val profile=listOf(108.0,124.0,118.0,132.0,115.0,128.0,112.0)
  val hr=(0..6).map {i ->
   val avg=profile[i]+3*sin(i*1.8)
   HeartRatePlotPoint(today.minusDays(6L-i),(avg-14-8*abs(sin(i*1.2+0.5))).roundToInt().toDouble(),
    avg.roundToInt().toDouble(),(avg+26+14*abs(cos(i*1.4+0.2))).roundToInt().toDouble())
  }
  val kcal=(0..6).map {i ->ProgressDayPoint(today.minusDays(6L-i),max(200.0,(listOf(320,610,480,720,390,680,350)[i]+40*sin(i*2.1)).roundToInt().toDouble()))}
  return ProgressPreparedCharts(ProgressTimeRange.WEEK,monday,hr,kcal,kcal.sumOf {it.value},hr.map {it.avgBpm}.average(),ProgressSeriesGranularity.DAY)
 }
 fun weight(today:LocalDate)=(0..6).map {i ->ProgressDayPoint(today.minusDays(6L-i),((listOf(75.1,74.6,74.9,74.2,74.7,74.0,74.4)[i]+0.15*sin(i*2.3))*10).roundToInt()/10.0)}
}
