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

/** StatsView.ProgressSessionScoreChartCard geometry; prepared verified daily values unchanged. */
@Composable
internal fun SessionScoreProgressCard(points:List<ProgressDayPoint>,preview:Boolean=false,range:ProgressTimeRange=ProgressTimeRange.WEEK,monday:Boolean=true,today:LocalDate=LocalDate.now()) {
 val values=points.sortedBy {it.day}
 val domain=ProgressPlotAxis.domain(values.map {it.day},range,monday,today,preview)
 var selected by remember(values,domain) {mutableStateOf<Int?>(null)}
 val accent=MaterialTheme.colorScheme.primary
 val rule=MaterialTheme.colorScheme.onSurfaceVariant
 val grid=rule.copy(alpha=0.15f)
 fun nearest(f:Float)=values.indices.minBy {abs(ProgressPlotAxis.fraction(values[it].day,domain)-f)}
 Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(horizontal=10.dp,vertical=20.dp),verticalArrangement=Arrangement.spacedBy(10.dp)) {
  Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
   Text("Puntuación de entrenos",style=MaterialTheme.typography.titleMedium)
   if(values.isNotEmpty()) Text((if(preview) "Ejemplo · " else "")+Math.round(values.map {it.value}.average())+"/10",style=MaterialTheme.typography.labelMedium)
  }
  if(preview) Text("Datos ficticios, no son tus puntuaciones",style=MaterialTheme.typography.bodySmall)
  if(values.isEmpty()) {
   EmptyHealthChartAxes(0.0,10.0,205.dp)
   Text("Todavía no hay puntuaciones basadas en tu historial.",style=MaterialTheme.typography.bodySmall)
  } else {
   selected?.let {Text(values[it].day.format(reperaDayFormatter)+": "+Math.round(values[it].value)+"/10",style=MaterialTheme.typography.labelSmall)}
   Row(Modifier.fillMaxWidth().semantics {
    contentDescription=if(preview) "Puntuaciones de ejemplo, datos ficticios" else "Puntuaciones verificadas por día"
    if(!preview) customActions=listOf(
     CustomAccessibilityAction("Punto anterior") {selected=ChartSelectionStep.step(selected,-1,values.size);true},
     CustomAccessibilityAction("Punto siguiente") {selected=ChartSelectionStep.step(selected,1,values.size);true})
   }) {
    Column(Modifier.width(44.dp).height(205.dp),verticalArrangement=Arrangement.SpaceBetween) {
     listOf("10","5","0").forEach {Text(it,style=MaterialTheme.typography.labelSmall)}
    }
    Canvas(Modifier.weight(1f).height(205.dp).testTag("session_score_plot")
     .pointerInput(values,domain,preview) {if(preview) return@pointerInput;detectTapGestures {selected=nearest(it.x/size.width)}}
     .pointerInput(values,domain,preview) {if(preview) return@pointerInput;detectHorizontalDragGestures {change,_ ->change.consume();selected=nearest(change.position.x/size.width)}}) {
     fun x(i:Int)=ProgressPlotAxis.fraction(values[i].day,domain)*size.width
     fun y(value:Double)=size.height-(value/10*size.height).toFloat()
     clipRect {
      listOf(0f,0.5f,1f).forEach {f ->
       drawLine(grid,Offset(0f,f*size.height),Offset(size.width,f*size.height),0.5.dp.toPx())
       drawLine(grid,Offset(f*size.width,0f),Offset(f*size.width,size.height),0.5.dp.toPx())
      }
      val positions=values.indices.map {ReadinessCurve.Point(x(it),y(values[it].value))}
      val path=Path();path.moveTo(positions.first().x,positions.first().y)
      ReadinessCurve.segments(positions).forEach {c ->path.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)}
      drawPath(path,accent,style=Stroke(2.5.dp.toPx(),cap=StrokeCap.Round))
      selected?.let {i ->drawLine(rule,Offset(x(i),0f),Offset(x(i),size.height),1.dp.toPx(),pathEffect=PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(),4.dp.toPx())))}
     }
    }
   }
   Row(Modifier.fillMaxWidth().padding(start=44.dp),horizontalArrangement=Arrangement.SpaceBetween) {
    val fmt=java.time.format.DateTimeFormatter.ofPattern("d MMM",java.util.Locale("es","ES"))
    Text(values.first().day.format(fmt),style=MaterialTheme.typography.labelSmall)
    if(values.size>1) Text(values.last().day.format(fmt),style=MaterialTheme.typography.labelSmall)
   }
   if(!preview) Text("Media diaria de notas basadas en tu historial comparable.",style=MaterialTheme.typography.bodySmall)
  }
 }}
}
