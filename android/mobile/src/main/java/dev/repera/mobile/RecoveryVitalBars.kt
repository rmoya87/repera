package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import dev.repera.domain.ProgressDayPoint
import java.time.LocalDate
import kotlin.math.abs

internal object RecoveryVitalBarGeometry {
 fun nearest(values:List<ProgressDayPoint>,day:LocalDate?):ProgressDayPoint? =
  if(day==null) null else values.minByOrNull {abs(it.day.toEpochDay()-day.toEpochDay())}
 // Day-unit bars have half-day padding; single sample stays centered.
 fun fraction(values:List<ProgressDayPoint>,day:LocalDate):Float {
  val first=values.minOf {it.day.toEpochDay()};val last=values.maxOf {it.day.toEpochDay()}
  return ((day.toEpochDay()-first+0.5)/(last-first+1.0)).toFloat()
 }
 fun nearestAt(values:List<ProgressDayPoint>,fraction:Float):ProgressDayPoint =
  values.minBy {abs(fraction(values,it.day)-fraction.coerceIn(0f,1f))}
 fun dayWidth(values:List<ProgressDayPoint>):Float =1f/(values.maxOf {it.day.toEpochDay()}-values.minOf {it.day.toEpochDay()}+1)
}

/** HealthRecovery.vitalBarTile: independent scales, shared selected calendar day. */
@Composable internal fun RecoveryVitalBars(rest:List<ProgressDayPoint>,breathing:List<ProgressDayPoint>) {
 var selectedDay by remember(rest,breathing) {mutableStateOf<LocalDate?>(null)}
 Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(10.dp)) {
  RecoveryVitalBarTile("Pulso en reposo","lpm",rest,selectedDay,{selectedDay=it},Modifier.weight(1f),"rest")
  RecoveryVitalBarTile("Respiración","resp/min",breathing,selectedDay,{selectedDay=it},Modifier.weight(1f),"breathing")
 }
}

@Composable private fun RecoveryVitalBarTile(title:String,unit:String,samples:List<ProgressDayPoint>,selectedDay:LocalDate?,onSelect:(LocalDate)->Unit,modifier:Modifier,tag:String) {
 val values=samples.sortedBy {it.day}
 val selected=RecoveryVitalBarGeometry.nearest(values,selectedDay)
 val accent=MaterialTheme.colorScheme.primary
 val rule=MaterialTheme.colorScheme.onSurfaceVariant
 fun formatted(v:Double)=dev.repera.domain.ReperaNumberFormat.decimal(v,maximumFractionDigits=0)+" "+unit
 Surface(modifier,shape=RoundedCornerShape(12.dp),color=MaterialTheme.colorScheme.surfaceVariant) {
  Column(Modifier.padding(10.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
   Text(title,style=MaterialTheme.typography.labelMedium)
   Text(values.lastOrNull()?.let {formatted(it.value)} ?: "-",style=MaterialTheme.typography.titleMedium)
   if(values.isEmpty()) {
    EmptyHealthChartAxes(0.0,100.0,98.dp)
    Text("Sin datos",style=MaterialTheme.typography.bodySmall)
   } else {
    selected?.let {Text(it.day.format(reperaDayFormatter)+": "+formatted(it.value),style=MaterialTheme.typography.labelSmall)}
    Canvas(Modifier.fillMaxWidth().height(98.dp).testTag("physiology_bar_$tag").semantics {
     contentDescription="$title, ${values.size} mediciones, última ${formatted(values.last().value)}"
     customActions=listOf(
      CustomAccessibilityAction("Medición anterior") {val i=selected?.let {values.indexOf(it)} ?: values.size;onSelect(values[(i-1).coerceAtLeast(0)].day);true},
      CustomAccessibilityAction("Medición siguiente") {val i=selected?.let {values.indexOf(it)} ?: -1;onSelect(values[(i+1).coerceAtMost(values.lastIndex)].day);true})
    }.pointerInput(values) {
     detectTapGestures {onSelect(RecoveryVitalBarGeometry.nearestAt(values,it.x/size.width).day)}
    }.pointerInput(values) {
     detectHorizontalDragGestures {change,_ ->change.consume();onSelect(RecoveryVitalBarGeometry.nearestAt(values,change.position.x/size.width).day)}
    }) {
     val maximum=(values.maxOf {it.value}).coerceAtLeast(1.0)
     val width=size.width*RecoveryVitalBarGeometry.dayWidth(values)*0.7f
     clipRect {
      values.forEach {v ->
       val h=(v.value/maximum*size.height).toFloat().coerceIn(0f,size.height)
       val x=RecoveryVitalBarGeometry.fraction(values,v.day)*size.width
       drawRoundRect(accent.copy(alpha=0.8f),Offset(x-width/2,size.height-h),Size(width,h),CornerRadius(3.dp.toPx()))
      }
      selected?.let {v ->val x=RecoveryVitalBarGeometry.fraction(values,v.day)*size.width
       drawLine(rule,Offset(x,0f),Offset(x,size.height),1.dp.toPx(),pathEffect=PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(),4.dp.toPx())))
      }
     }
    }
   }
  }
 }
}
