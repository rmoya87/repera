package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import dev.repera.domain.RecoverySleepNight

internal fun sleepChartHeightDp(columnWidthDp:Float,expanded:Boolean)=if(expanded) maxOf(220f,columnWidthDp-150f) else 220f
internal fun sleepChartBounds(nights:List<RecoverySleepNight>):Pair<Double,Double> {
 val low=maxOf(3.5,(nights.minOfOrNull {it.hours} ?: 5.0)-0.6)
 val high=minOf(11.0,(nights.maxOfOrNull {it.hours} ?: 8.0)+0.7)
 // Do not crash on valid out-of-typical-range observations; keep them observable.
 return if(high>low && nights.all {it.hours in low..high}) low to high
 else ((nights.minOfOrNull {it.hours} ?: 0.0)-0.6) to ((nights.maxOfOrNull {it.hours} ?: 0.0)+0.7)
}
/** HealthRecovery.sleepNightCard: observed nights, night-sky area and curve. */
@Composable internal fun RecoverySleepChart(nights:List<RecoverySleepNight>,height:Dp) {
 if(nights.isEmpty()) return
 val ordered=nights.sortedBy {it.day}
 val (low,high)=sleepChartBounds(ordered)
 var selected by remember(ordered) {mutableStateOf<Int?>(null)}
 val ink=Color(0.07f,0.10f,0.22f)
 val mid=Color(0.32f,0.42f,0.78f)
 val glow=Color(0.55f,0.68f,0.95f)
 fun nearest(fraction:Float):Int {
  val start=ordered.first().day.toEpochDay();val span=(ordered.last().day.toEpochDay()-start).coerceAtLeast(1)
  return ordered.indices.minBy {kotlin.math.abs((ordered[it].day.toEpochDay()-start).toFloat()/span-fraction)}
 }
 Column(Modifier.fillMaxWidth()) {
  selected?.let {Text("${ordered[it].day.format(reperaDayFormatter)} · ${formatWeight(ordered[it].hours)} h",style=MaterialTheme.typography.labelMedium)}
  Canvas(Modifier.fillMaxWidth().height(height).testTag("recovery_sleep_chart").clip(RoundedCornerShape(12.dp)).background(ink)
   .semantics {
    contentDescription="Sueño, ${ordered.size} noches registradas; última ${formatWeight(ordered.last().hours)} h"
    customActions=listOf(CustomAccessibilityAction("Noche anterior") {selected=ChartSelectionStep.step(selected,-1,ordered.size);true},CustomAccessibilityAction("Noche siguiente") {selected=ChartSelectionStep.step(selected,1,ordered.size);true})
   }
   .pointerInput(ordered) {detectTapGestures {selected=nearest(it.x/size.width.coerceAtLeast(1))}}
   .pointerInput(ordered) {detectHorizontalDragGestures {change,_ ->change.consume();selected=nearest(change.position.x/size.width.coerceAtLeast(1))}}) {
   val start=ordered.first().day.toEpochDay();val span=ordered.last().day.toEpochDay()-start
   fun x(i:Int)=if(span==0L) size.width/2f else (ordered[i].day.toEpochDay()-start).toFloat()/span*size.width
   fun y(value:Double)=size.height-((value-low)/(high-low)*size.height).toFloat()
   val points=ordered.indices.map {ReadinessCurve.Point(x(it),y(ordered[it].hours))}
   val curve=Path();curve.moveTo(points.first().x,points.first().y)
   ReadinessCurve.segments(points).forEach {c ->curve.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)}
   val area=Path().apply {addPath(curve);lineTo(points.last().x,size.height);lineTo(points.first().x,size.height);close()}
   clipRect {
    drawPath(area,Brush.verticalGradient(listOf(mid.copy(alpha=0.5f),ink.copy(alpha=0.15f))))
    drawPath(curve,glow,style=Stroke(2.4.dp.toPx(),cap=StrokeCap.Round,join=StrokeJoin.Round))
    if(points.size==1) drawCircle(glow,3.dp.toPx(),Offset(points.first().x,points.first().y))
    selected?.let {i ->drawLine(glow,Offset(x(i),0f),Offset(x(i),size.height),1.dp.toPx(),pathEffect=PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(),4.dp.toPx())))}
   }
  }
  if(ordered.size>1) Row(Modifier.fillMaxWidth()) {
   val axisDate=java.time.format.DateTimeFormatter.ofPattern("d MMM",java.util.Locale("es","ES"))
   Text(ordered.first().day.format(axisDate),style=MaterialTheme.typography.labelSmall)
   Spacer(Modifier.weight(1f))
   Text(ordered.last().day.format(axisDate),style=MaterialTheme.typography.labelSmall)
  }
 }
}
