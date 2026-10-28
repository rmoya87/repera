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
import androidx.compose.ui.unit.sp
import dev.repera.domain.*
import java.time.LocalDate
import kotlin.math.abs

internal fun cardioPlotBounds(points:List<HeartRatePlotPoint>,preview:Boolean):Pair<Double,Double> {
 if(points.isEmpty()) return 60.0 to 160.0
 val low=maxOf(40.0,points.minOf {it.minBpm}-if(preview) 18.0 else 12.0)
 return low to maxOf(low+24.0,points.maxOf {it.maxBpm}+if(preview) 22.0 else 14.0)
}

/** ProgressCardioChartCard: three curves, not an invented min-max area. No zones changes. */
@Composable internal fun ProgressCardioPlot(charts:ProgressPreparedCharts,preview:Boolean=false,today:LocalDate=LocalDate.now()) {
 val points=charts.heartRate.sortedBy {it.day}
 val (low,high)=cardioPlotBounds(points,preview)
 val domain=ProgressPlotAxis.domain(points.map {it.day},charts.range,charts.weekStartsOnMonday,today,preview)
 val ticks=ProgressPlotAxis.ticks(points.map {it.day},charts.range,charts.granularity)
 var selected by remember(points,domain) {mutableStateOf<Int?>(null)}
 val colors=listOf(Color(0xFF0A84FF),Color(0xFFFF453A),Color(0xFFFF9F0A))
 val grid=MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha=0.15f)
 val rule=MaterialTheme.colorScheme.onSurfaceVariant
 fun nearest(f:Float)=points.indices.minBy {abs(ProgressPlotAxis.fraction(points[it].day,domain)-f)}
 Column(Modifier.fillMaxWidth().semantics {
  contentDescription=if(preview) "Cardio de ejemplo, datos ficticios" else "Cardio registrado: mínimo, media y máximo"
  if(!preview && points.isNotEmpty()) customActions=listOf(
   CustomAccessibilityAction("Punto anterior") {selected=ChartSelectionStep.step(selected,-1,points.size);true},
   CustomAccessibilityAction("Punto siguiente") {selected=ChartSelectionStep.step(selected,1,points.size);true})
 }) {
  if(points.isEmpty()) {
   EmptyHealthChart("Sin ritmo cardíaco de Salud en ${charts.range.title.lowercase()}.",60.0,160.0,190.dp)
  } else {
   selected?.let {Text(points[it].day.format(reperaDayFormatter)+": "+Math.round(points[it].avgBpm)+" lpm",style=MaterialTheme.typography.labelSmall)}
   Row(Modifier.fillMaxWidth()) {
    Column(Modifier.width(44.dp).height(190.dp),verticalArrangement=Arrangement.SpaceBetween) {
     listOf(high,(low+high)/2,low).forEach {Text(Math.round(it).toString(),style=MaterialTheme.typography.labelSmall.copy(fontSize=10.sp))}
    }
    Canvas(Modifier.weight(1f).height(190.dp).testTag("cardio_observed_plot")
     .pointerInput(points,domain,preview) {if(preview) return@pointerInput;detectTapGestures {selected=nearest(it.x/size.width)}}
     .pointerInput(points,domain,preview) {if(preview) return@pointerInput;detectHorizontalDragGestures {change,_ ->change.consume();selected=nearest(change.position.x/size.width)}}) {
     fun x(i:Int)=ProgressPlotAxis.fraction(points[i].day,domain)*size.width
     fun y(value:Double)=size.height-((value-low)/(high-low)*size.height).toFloat()
     clipRect {
      listOf(0f,0.5f,1f).forEach {f ->drawLine(grid,Offset(0f,f*size.height),Offset(size.width,f*size.height),0.5.dp.toPx())}
      ticks.forEach {day ->val x=ProgressPlotAxis.fraction(day,domain)*size.width;drawLine(grid,Offset(x,0f),Offset(x,size.height),0.5.dp.toPx())}
      listOf<(HeartRatePlotPoint)->Double>({it.minBpm},{it.avgBpm},{it.maxBpm}).forEachIndexed {series,value ->
       val positions=points.indices.map {ReadinessCurve.Point(x(it),y(value(points[it])))}
       val path=Path();path.moveTo(positions.first().x,positions.first().y)
       ReadinessCurve.segments(positions).forEach {c ->path.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)}
       drawPath(path,colors[series],style=Stroke((if(series==1) 2.25f else 1.75f).dp.toPx(),cap=StrokeCap.Round,join=StrokeJoin.Round))
      }
      selected?.let {i ->drawLine(rule,Offset(x(i),0f),Offset(x(i),size.height),1.dp.toPx(),pathEffect=PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(),4.dp.toPx())))}
     }
    }
   }
   ProgressPlotDateLabels(ticks,domain,charts)
   Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(8.dp)) {
    listOf("Mín" to points.minOf {it.minBpm},"Media" to points.map {it.avgBpm}.average(),"Máx" to points.maxOf {it.maxBpm}).forEachIndexed {i,(title,value) ->
     Surface(Modifier.weight(1f),shape=androidx.compose.foundation.shape.RoundedCornerShape(10.dp),color=MaterialTheme.colorScheme.surfaceVariant) {
      Column(Modifier.fillMaxWidth().padding(vertical=10.dp),horizontalAlignment=androidx.compose.ui.Alignment.CenterHorizontally) {
       Text(title,style=MaterialTheme.typography.labelSmall)
       Text(Math.round(value).toString(),color=colors[i],style=MaterialTheme.typography.titleMedium)
       Text("lpm",style=MaterialTheme.typography.labelSmall)
      }
     }
    }
   }
  }
 }
}
