package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.*
import java.time.LocalDate
import kotlin.math.abs

/** ProgressChartAxis calendar-day equivalent (half-day padding for single/teaser). */
internal object ProgressPlotAxis {
 fun domain(days:List<LocalDate>,range:ProgressTimeRange,monday:Boolean,today:LocalDate,preview:Boolean):Pair<Double,Double> {
  val pad=0.5
  if (preview) {
   val start=days.minOrNull() ?: today
   val end=days.maxOrNull() ?: today
   return start.toEpochDay()-pad to end.toEpochDay()+pad
  }
  val expectedDays=when(range) {
   ProgressTimeRange.TODAY -> 1
   ProgressTimeRange.WEEK -> 7
   ProgressTimeRange.MONTH -> 28
   ProgressTimeRange.DAYS_90 -> 90
   ProgressTimeRange.DAYS_180 -> 180
   ProgressTimeRange.DAYS_360 -> 360
  }
  if (days.size < expectedDays) {
   val start=days.minOrNull() ?: today
   val end=days.maxOrNull() ?: today
   if (start==end) return start.toEpochDay()-pad to end.toEpochDay()+pad
   return start.toEpochDay()-pad to end.toEpochDay()+pad
  }
  val start=range.startDate(today,monday)
  val end=today
  val edgePad=if(start==end || days.size<=1) pad else 0.0
  return start.toEpochDay()-edgePad to end.toEpochDay()+edgePad
 }
 fun fraction(day:LocalDate,domain:Pair<Double,Double>):Float =((day.toEpochDay()-domain.first)/(domain.second-domain.first).coerceAtLeast(1.0)).toFloat()
 /** Eje de semana/hoy = todos los días de la ventana (huecos honestos), no solo días con kcal. */
 fun ticks(days:List<LocalDate>,range:ProgressTimeRange,granularity:ProgressSeriesGranularity,monday:Boolean=true,today:LocalDate=LocalDate.now(),preview:Boolean=false):List<LocalDate> {
  if (!preview && granularity == ProgressSeriesGranularity.DAY &&
   (range == ProgressTimeRange.WEEK || range == ProgressTimeRange.TODAY)
  ) {
   val start = range.startDate(today, monday)
   return generateSequence(start) { it.plusDays(1) }.takeWhile { !it.isAfter(today) }.toList()
  }
  val step=if(granularity==ProgressSeriesGranularity.DAY && (range==ProgressTimeRange.WEEK || range==ProgressTimeRange.TODAY)) 1 else maxOf(1,days.size/6)
  return days.filterIndexed {i,_ ->i%step==0 || i==days.lastIndex}.distinct()
 }
 fun kcalMax(values:List<ProgressDayPoint>,preview:Boolean)=maxOf(1.0,(values.maxOfOrNull {it.value} ?: 1.0)*(if(preview) 1.28 else 1.18))
}

/** Observed/prepared calories, not invented bars. No sample changes or Health reads. */
@Composable internal fun ProgressCaloriesPlot(charts:ProgressPreparedCharts,preview:Boolean=false,today:LocalDate=LocalDate.now()) {
 val points=charts.calories.sortedBy {it.day}
 val ticks=ProgressPlotAxis.ticks(
  points.map {it.day}, charts.range, charts.granularity,
  monday = charts.weekStartsOnMonday, today = today, preview = preview
 )
 val maximum=ProgressPlotAxis.kcalMax(points,preview)
 val domain=ProgressPlotAxis.domain(points.map {it.day},charts.range,charts.weekStartsOnMonday,today,preview)
 var selected by remember(points,domain) {mutableStateOf<Int?>(null)}
 val orange=Color(0xFFFF9F0A)
 val rule=MaterialTheme.colorScheme.onSurfaceVariant
 val axisInk=MaterialTheme.colorScheme.onSurfaceVariant
 val grid=MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha=0.22f)
 fun nearest(f:Float)=points.indices.minBy {abs(ProgressPlotAxis.fraction(points[it].day,domain)-f)}
 Column(Modifier.fillMaxWidth().semantics {
  contentDescription=if(preview) "Calorías de ejemplo, datos ficticios" else "Calorías activas registradas"
  if(!preview && points.isNotEmpty()) customActions=listOf(
   CustomAccessibilityAction("Punto anterior") {selected=ChartSelectionStep.step(selected,-1,points.size);true},
   CustomAccessibilityAction("Punto siguiente") {selected=ChartSelectionStep.step(selected,1,points.size);true})
 }) {
  if(points.none {it.value>0}) {
   EmptyHealthChart("Sin kcal de Salud en ${charts.range.title.lowercase()}.",0.0,600.0,210.dp)
  } else {
   BoxWithConstraints(Modifier.fillMaxWidth().height(210.dp)) {
    val topPadPx = with(LocalDensity.current) { ProgressChartYTopPadDp.toPx() }
    Canvas(Modifier.fillMaxWidth().height(210.dp)
     .progressChartReveal(ProgressChartRevealStyle.LINE)
     .testTag("calories_observed_plot")
     .pointerInput(points,domain,preview) {if(preview) return@pointerInput;detectTapGestures {selected=nearest(it.x/size.width)}}
     .pointerInput(points,domain,preview) {if(preview) return@pointerInput;detectHorizontalDragGestures {change,_ ->change.consume();selected=nearest(change.position.x/size.width)}}) {
     fun x(i:Int)=ProgressPlotAxis.fraction(points[i].day,domain)*size.width
     fun y(value:Double)=progressChartPlotY(value, 0.0, maximum, size.height, topPadPx)
     val yLabelPaint=progressChartYLabelPaint(axisInk,10.sp.toPx())
     clipRect {
      ticks.forEach {day ->val x=ProgressPlotAxis.fraction(day,domain)*size.width;drawLine(grid,Offset(x,0f),Offset(x,size.height),0.5.dp.toPx())}
      val positions=points.indices.map {ReadinessCurve.Point(x(it),y(points[it].value))}
      val path=Path();path.moveTo(positions.first().x,positions.first().y)
      ReadinessCurve.segments(positions).forEach {c ->path.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)}
      val area=Path().apply {addPath(path);lineTo(positions.last().x,size.height);lineTo(positions.first().x,size.height);close()}
      drawPath(area,Brush.verticalGradient(listOf(orange.copy(alpha=0.32f),orange.copy(alpha=0.02f))))
      drawPath(path,orange,style=Stroke(2.25.dp.toPx(),cap=StrokeCap.Round,join=StrokeJoin.Round))
     }
     // Guías Y + selección fuera del clip para no recortar el tick máximo ni el badge.
     listOf(maximum,maximum/2).forEach {value ->
      val gy=y(value)
      drawLine(grid,Offset(0f,gy),Offset(size.width,gy),0.5.dp.toPx())
      drawContext.canvas.nativeCanvas.drawText(
       Math.round(value).toString(),4.dp.toPx(),
       (gy + 11.dp.toPx()).coerceAtMost(size.height - 2.dp.toPx()),
       yLabelPaint
      )
     }
     selected?.let {i ->
      drawLine(rule,Offset(x(i),0f),Offset(x(i),size.height),1.dp.toPx(),pathEffect=PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(),4.dp.toPx())))
      drawCircle(orange, radius = 5.dp.toPx(), center = Offset(x(i), y(points[i].value)))
     }
    }
    selected?.let { i ->
     val px = maxWidth * ProgressPlotAxis.fraction(points[i].day, domain)
     val py = with(LocalDensity.current) {
      progressChartPlotY(points[i].value, 0.0, maximum, 210.dp.toPx(), topPadPx).toDp()
     }
     Text(
      "${Math.round(points[i].value)} kcal · ${points[i].day.format(reperaDayFormatter)}",
      style = MaterialTheme.typography.labelSmall,
      color = MaterialTheme.colorScheme.onSurface,
      modifier = Modifier
       .align(Alignment.TopStart)
       .offset(
        x = (px - 48.dp).coerceIn(0.dp, (maxWidth - 96.dp).coerceAtLeast(0.dp)),
        y = (py - 22.dp).coerceAtLeast(2.dp)
       )
       .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.94f), RoundedCornerShape(50))
       .padding(horizontal = 8.dp, vertical = 5.dp)
     )
    }
   }
   ProgressPlotDateLabels(ticks,domain,charts)
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
    Text(title,style=MaterialTheme.typography.labelSmall,maxLines=1,
     color=MaterialTheme.colorScheme.onSurfaceVariant)
    Text(value,style=MaterialTheme.typography.labelMedium,maxLines=1,
     color=MaterialTheme.colorScheme.onSurface)
   }
  }}
 }
}

internal data class PlotDateLabel(val text:String,val left:Float,val width:Float)
internal fun greedyPlotDateLabels(candidates:List<Triple<String,Float,Float>>,available:Float,gap:Float=3f):List<PlotDateLabel> {
 val result=mutableListOf<PlotDateLabel>()
 candidates.forEach {(text,center,width) ->
  if(width<=available && width>0f) {
   val left=(center-width/2).coerceIn(0f,(available-width).coerceAtLeast(0f))
   if(result.isEmpty() || left>=result.last().left+result.last().width+gap) result.add(PlotDateLabel(text,left,width))
  }
 }
 return result
}

internal fun progressPlotDatePattern(charts:ProgressPreparedCharts):String = if(charts.granularity==ProgressSeriesGranularity.MONTH) "MMM yy" else if(charts.granularity==ProgressSeriesGranularity.DAY && (charts.range==ProgressTimeRange.WEEK || charts.range==ProgressTimeRange.TODAY)) "EEE" else "d MMM"

@Composable internal fun ProgressPlotDateLabels(ticks:List<LocalDate>,domain:Pair<Double,Double>,charts:ProgressPreparedCharts) {
   val measurer=androidx.compose.ui.text.rememberTextMeasurer()
   val density=androidx.compose.ui.platform.LocalDensity.current
   val style=MaterialTheme.typography.labelSmall.copy(fontSize=androidx.compose.ui.unit.TextUnit(10f,androidx.compose.ui.unit.TextUnitType.Sp))
   val dateColor=MaterialTheme.colorScheme.onSurfaceVariant
   androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxWidth().height(22.dp)) {
    val fmt=java.time.format.DateTimeFormatter.ofPattern(progressPlotDatePattern(charts),java.util.Locale.forLanguageTag("es-ES"))
    val candidates=ticks.map {day ->
     val text=day.format(fmt)
     val width=with(density) {measurer.measure(androidx.compose.ui.text.AnnotatedString(text),style=style,maxLines=1,softWrap=false).size.width.toDp().value}+1f
     Triple(text,ProgressPlotAxis.fraction(day,domain)*maxWidth.value,width)
    }
    greedyPlotDateLabels(candidates,maxWidth.value).forEach {label ->
     Text(label.text,Modifier.offset(x=label.left.dp).width(label.width.dp),style=style,color=dateColor,maxLines=1,softWrap=false)
    }
   }
}
