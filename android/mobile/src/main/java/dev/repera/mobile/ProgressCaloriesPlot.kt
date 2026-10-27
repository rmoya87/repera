package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import dev.repera.domain.*
import java.time.LocalDate
import kotlin.math.abs

/** ProgressChartAxis calendar-day equivalent (half-day padding for single/teaser). */
internal object ProgressPlotAxis {
 fun domain(days:List<LocalDate>,range:ProgressTimeRange,monday:Boolean,today:LocalDate,preview:Boolean):Pair<Double,Double> {
  val start=(if(preview) days.minOrNull() else range.startDate(today,monday)) ?: days.minOrNull() ?: today
  val end=if(preview) days.maxOrNull() ?: today else today
  val pad=if(preview || start==end || days.size<=1) 0.5 else 0.0
  return start.toEpochDay()-pad to end.toEpochDay()+pad
 }
 fun fraction(day:LocalDate,domain:Pair<Double,Double>):Float =((day.toEpochDay()-domain.first)/(domain.second-domain.first).coerceAtLeast(1.0)).toFloat()
 fun ticks(days:List<LocalDate>,range:ProgressTimeRange,granularity:ProgressSeriesGranularity):List<LocalDate> {
  val step=if(granularity==ProgressSeriesGranularity.DAY && (range==ProgressTimeRange.TODAY || range==ProgressTimeRange.WEEK)) 1 else maxOf(1,days.size/6)
  return days.filterIndexed {i,_ ->i%step==0 || i==days.lastIndex}.distinct()
 }
 fun kcalMax(values:List<ProgressDayPoint>,preview:Boolean)=maxOf(1.0,(values.maxOfOrNull {it.value} ?: 1.0)*(if(preview) 1.28 else 1.18))
}

/** Observed/prepared calories, not invented bars. No sample changes or Health reads. */
@Composable internal fun ProgressCaloriesPlot(charts:ProgressPreparedCharts,preview:Boolean=false,today:LocalDate=LocalDate.now()) {
 val points=charts.calories.sortedBy {it.day}
 val ticks=ProgressPlotAxis.ticks(points.map {it.day},charts.range,charts.granularity)
 val maximum=ProgressPlotAxis.kcalMax(points,preview)
 val domain=ProgressPlotAxis.domain(points.map {it.day},charts.range,charts.weekStartsOnMonday,today,preview)
 var selected by remember(points,domain) {mutableStateOf<Int?>(null)}
 val orange=Color(0xFFFF9F0A)
 val rule=MaterialTheme.colorScheme.onSurfaceVariant
 val grid=MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha=0.15f)
 fun nearest(f:Float)=points.indices.minBy {abs(ProgressPlotAxis.fraction(points[it].day,domain)-f)}
 Column(Modifier.fillMaxWidth().semantics {
  contentDescription=if(preview) "Calorías de ejemplo, datos ficticios" else "Calorías activas registradas"
  if(points.isNotEmpty()) customActions=listOf(
   CustomAccessibilityAction("Punto anterior") {selected=ChartSelectionStep.step(selected,-1,points.size);true},
   CustomAccessibilityAction("Punto siguiente") {selected=ChartSelectionStep.step(selected,1,points.size);true})
 }) {
  if(points.none {it.value>0}) {
   EmptyHealthChartAxes(0.0,600.0,210.dp)
   Text("Sin kcal de Salud en ${charts.range.title.lowercase()}.",style=MaterialTheme.typography.bodySmall)
  } else {
   selected?.let {Text(points[it].day.format(reperaDayFormatter)+": "+Math.round(points[it].value)+" kcal",style=MaterialTheme.typography.labelSmall)}
   Row(Modifier.fillMaxWidth()) {
    Column(Modifier.width(44.dp).height(210.dp),verticalArrangement=Arrangement.SpaceBetween) {
     Text(Math.round(maximum).toString(),style=MaterialTheme.typography.labelSmall)
     Text(Math.round(maximum/2).toString(),style=MaterialTheme.typography.labelSmall)
     Text("0",style=MaterialTheme.typography.labelSmall)
    }
    Canvas(Modifier.weight(1f).height(210.dp).testTag("calories_observed_plot")
     .pointerInput(points,domain) {detectTapGestures {selected=nearest(it.x/size.width)}}
     .pointerInput(points,domain) {detectHorizontalDragGestures {change,_ ->change.consume();selected=nearest(change.position.x/size.width)}}) {
     fun x(i:Int)=ProgressPlotAxis.fraction(points[i].day,domain)*size.width
     fun y(value:Double)=size.height-(value/maximum*size.height).toFloat()
     clipRect {
      listOf(0f,0.5f,1f).forEach {f ->drawLine(grid,Offset(0f,f*size.height),Offset(size.width,f*size.height),0.5.dp.toPx())}
      ticks.forEach {day ->val x=ProgressPlotAxis.fraction(day,domain)*size.width;drawLine(grid,Offset(x,0f),Offset(x,size.height),0.5.dp.toPx())}
      val positions=points.indices.map {ReadinessCurve.Point(x(it),y(points[it].value))}
      val path=Path();path.moveTo(positions.first().x,positions.first().y)
      ReadinessCurve.segments(positions).forEach {c ->path.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)}
      val area=Path().apply {addPath(path);lineTo(positions.last().x,size.height);lineTo(positions.first().x,size.height);close()}
      drawPath(area,Brush.verticalGradient(listOf(orange.copy(alpha=0.32f),orange.copy(alpha=0.02f))))
      drawPath(path,orange,style=Stroke(2.25.dp.toPx(),cap=StrokeCap.Round,join=StrokeJoin.Round))
      selected?.let {i ->drawLine(rule,Offset(x(i),0f),Offset(x(i),size.height),1.dp.toPx(),pathEffect=PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(),4.dp.toPx())))}
     }
    }
   }
   androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxWidth().padding(start=44.dp).height(22.dp)) {
    val fmt=java.time.format.DateTimeFormatter.ofPattern(if(charts.granularity==ProgressSeriesGranularity.MONTH) "MMM yy" else if(charts.range==ProgressTimeRange.WEEK || charts.range==ProgressTimeRange.TODAY) "EEE" else "d MMM",java.util.Locale("es","ES"))
    // Fixed-width greedy label collision rule, separate from exact tick positions.
    var lastEnd=-100f
    ticks.forEach {day ->
     val center=ProgressPlotAxis.fraction(day,domain)*maxWidth.value
     val width=if(charts.granularity==ProgressSeriesGranularity.MONTH) 45f else 38f
     val left=(center-width/2).coerceIn(0f,(maxWidth.value-width).coerceAtLeast(0f))
     if(left>=lastEnd+3f) {
      Text(day.format(fmt),Modifier.offset(x=left.dp).width(width.dp),style=MaterialTheme.typography.labelSmall,maxLines=1,softWrap=false)
      lastEnd=left+width
     }
    }
   }
  }
 }
}

@Composable internal fun ProgressCalorieStats(charts:ProgressPreparedCharts) {
 Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(8.dp)) {
  val labels=listOf("Media/día" to CalorieAverageStats.kcalLabel(charts.caloriesDailyAverage),
   "Periodo ant." to CalorieAverageStats.kcalLabel(charts.previousCaloriesDailyAverage),
   "Variación" to CalorieAverageStats.changeLabel(CalorieAverageStats.change(charts.caloriesDailyAverage,charts.previousCaloriesDailyAverage)))
  labels.forEach {(title,value) ->Surface(Modifier.weight(1f),shape=androidx.compose.foundation.shape.RoundedCornerShape(10.dp),color=MaterialTheme.colorScheme.surfaceVariant) {
   Column(Modifier.fillMaxWidth().padding(horizontal=6.dp,vertical=10.dp),horizontalAlignment=androidx.compose.ui.Alignment.CenterHorizontally) {
    Text(title,style=MaterialTheme.typography.labelSmall,maxLines=1)
    Text(value,style=MaterialTheme.typography.labelMedium,maxLines=1)
   }
  }}
 }
}
