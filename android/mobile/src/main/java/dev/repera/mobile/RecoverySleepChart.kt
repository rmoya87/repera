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
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import dev.repera.domain.RecoverySleepNight

internal fun sleepChartHeightDp(columnWidthDp:Float,expanded:Boolean)=if(expanded) maxOf(220f,columnWidthDp-150f) else 220f
internal fun sleepChartBounds(nights:List<RecoverySleepNight>):Pair<Double,Double> {
 val low=maxOf(3.0, kotlin.math.floor((nights.minOfOrNull {it.hours} ?: 5.0)-0.5))
 val high=minOf(12.0, kotlin.math.ceil((nights.maxOfOrNull {it.hours} ?: 8.0)+0.5))
 return if(high>low) low to high
 else ((nights.minOfOrNull {it.hours} ?: 0.0)-0.6) to ((nights.maxOfOrNull {it.hours} ?: 0.0)+0.7)
}
/** Barras de horas por noche + ejes legibles (paridad iOS Sueño). */
@Composable internal fun RecoverySleepChart(nights:List<RecoverySleepNight>,height:Dp) {
 if(nights.isEmpty()) return
 val ordered=nights.sortedBy {it.day}
 val (low,high)=sleepChartBounds(ordered)
 var selected by remember(ordered) {mutableStateOf<Int?>(null)}
 val ink=Color(0.07f,0.10f,0.22f)
 val mid=Color(0.32f,0.42f,0.78f)
 val glow=Color(0.55f,0.68f,0.95f)
 fun nearest(fraction:Float):Int {
  if(ordered.size==1) return 0
  return (fraction.coerceIn(0f,1f)*(ordered.lastIndex)).toInt().coerceIn(0,ordered.lastIndex)
 }
 Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
  Text("Horas por noche", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
  selected?.let {Text("${ordered[it].day.format(reperaDayFormatter)} · ${formatWeight(ordered[it].hours)} h",style=MaterialTheme.typography.labelMedium)}
  Canvas(Modifier.fillMaxWidth().height(height).testTag("recovery_sleep_chart").clip(RoundedCornerShape(12.dp)).background(ink)
   .semantics {
    contentDescription="Sueño, ${ordered.size} noches registradas; última ${formatWeight(ordered.last().hours)} h"
    customActions=listOf(CustomAccessibilityAction("Noche anterior") {selected=ChartSelectionStep.step(selected,-1,ordered.size);true},CustomAccessibilityAction("Noche siguiente") {selected=ChartSelectionStep.step(selected,1,ordered.size);true})
   }
   .pointerInput(ordered) {detectTapGestures {selected=nearest(it.x/size.width.coerceAtLeast(1))}}
   .pointerInput(ordered) {detectHorizontalDragGestures {change,_ ->change.consume();selected=nearest(change.position.x/size.width.coerceAtLeast(1))}}) {
   val padL=36.dp.toPx(); val padR=12.dp.toPx(); val padT=10.dp.toPx(); val padB=22.dp.toPx()
   val plotW=(size.width-padL-padR).coerceAtLeast(1f)
   val plotH=(size.height-padT-padB).coerceAtLeast(1f)
   fun xCenter(i:Int):Float {
    val slot=plotW/ordered.size.coerceAtLeast(1)
    return padL+slot*i+slot/2f
   }
   fun y(value:Double)=padT+plotH-((value-low)/(high-low)*plotH).toFloat()
   // Guías horizontales + etiquetas de horas
   val guideCount=4
   for(g in 0..guideCount) {
    val value=low+(high-low)*g/guideCount
    val yy=y(value)
    drawLine(Color.White.copy(alpha=0.18f), Offset(padL,yy), Offset(size.width-padR,yy), 1.dp.toPx(), pathEffect=PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(),4.dp.toPx())))
   }
   val barW=(plotW/ordered.size.coerceAtLeast(1)*0.55f).coerceIn(8.dp.toPx(),28.dp.toPx())
   clipRect(padL, padT, size.width-padR, size.height-padB) {
    ordered.indices.forEach { i ->
     val top=y(ordered[i].hours)
     val bottom=padT+plotH
     drawRoundRect(
      color=mid.copy(alpha=0.85f),
      topLeft=Offset(xCenter(i)-barW/2f, top),
      size=Size(barW, (bottom-top).coerceAtLeast(4.dp.toPx())),
      cornerRadius=CornerRadius(4.dp.toPx(),4.dp.toPx())
     )
     drawCircle(glow, 3.5.dp.toPx(), Offset(xCenter(i), top))
    }
    selected?.let {i ->
     drawLine(glow,Offset(xCenter(i),padT),Offset(xCenter(i),padT+plotH),1.dp.toPx(),pathEffect=PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(),4.dp.toPx())))
    }
   }
  }
  if(ordered.size>1) Row(Modifier.fillMaxWidth()) {
   val axisDate=java.time.format.DateTimeFormatter.ofPattern("EEE d",java.util.Locale("es","ES"))
   Text(ordered.first().day.format(axisDate),style=MaterialTheme.typography.labelSmall)
   Spacer(Modifier.weight(1f))
   Text(ordered.last().day.format(axisDate),style=MaterialTheme.typography.labelSmall)
  }
 }
}
