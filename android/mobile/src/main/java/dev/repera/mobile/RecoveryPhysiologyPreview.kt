package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.platform.testTag
import dev.repera.domain.ProgressDayPoint
import java.time.LocalDate

/** Fixed Apple preview, independent of all owner samples and not interactive. */
internal object RecoveryPhysiologyPreview {
    val hrv=listOf(46.0,51.0,48.0,55.0,53.0,62.0,58.0)
    val resting=listOf(66.0,63.0,65.0,61.0,60.0,62.0,58.0)
    val breathing=listOf(16.0,15.0,15.0,14.0,16.0,14.0,13.0)
}

@Composable
internal fun RecoveryPhysiologyPreviewCard(today:LocalDate,chartHeight:Dp=128.dp) {
    Card(Modifier.fillMaxWidth().semantics {contentDescription="Ejemplo de constantes fisiológicas, datos ficticios."}) {
        Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
            Text("Constantes · Ejemplo ficticio",style=MaterialTheme.typography.titleMedium)
            Text("No son tus datos de Salud",style=MaterialTheme.typography.bodySmall)
            Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(8.dp),
                verticalAlignment=androidx.compose.ui.Alignment.CenterVertically) {
                Text("Variabilidad cardíaca (VFC)",Modifier.weight(1f),style=MaterialTheme.typography.titleSmall)
                Text("${RecoveryPhysiologyPreview.hrv.last().toInt()} ms",style=MaterialTheme.typography.labelMedium)
            }
            PhysiologyPreviewCurve(chartHeight)
            HorizontalDivider(Modifier.testTag("physiology_preview_divider"),
                color=MaterialTheme.colorScheme.outlineVariant.copy(alpha=0.25f))
            Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(10.dp)) {
                PhysiologyPreviewBars("Pulso en reposo","lpm",RecoveryPhysiologyPreview.resting,Modifier.weight(1f))
                PhysiologyPreviewBars("Respiración","rpm",RecoveryPhysiologyPreview.breathing,Modifier.weight(1f))
            }
            Text("Consulta constantes reales con Repera Pro",style=MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
private fun PhysiologyPreviewBars(title:String,unit:String,values:List<Double>,modifier:Modifier) {
    Surface(modifier,shape=MaterialTheme.shapes.medium,color=MaterialTheme.colorScheme.surfaceVariant) {
        Column(Modifier.padding(10.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
            Text(title,style=MaterialTheme.typography.labelMedium)
            Text("${values.last().toInt()} $unit",style=MaterialTheme.typography.titleMedium)
            val color=MaterialTheme.colorScheme.primary.copy(alpha=0.8f)
            Canvas(Modifier.fillMaxWidth().height(98.dp).testTag("physiology_preview_bars_$unit")) {
                val width=size.width/(values.size+2)
                val maximum=(values.maxOrNull() ?: 1.0).coerceAtLeast(1.0)
                values.forEachIndexed {i,v ->
                    val height=(v/maximum*size.height).toFloat()
                    drawRoundRect(color,Offset((i+1)/8f*size.width-width*0.35f,size.height-height),Size(width*0.7f,height),androidx.compose.ui.geometry.CornerRadius(3.dp.toPx()))
                }
            }
        }
    }
}

/** Preview day ordinal1..7/domain0..8, never calendar dates or owner samples. */
@Composable internal fun PhysiologyPreviewCurve(height:Dp) {
 val accent=MaterialTheme.colorScheme.primary
 val values=RecoveryPhysiologyPreview.hrv
 Column(Modifier.fillMaxWidth().semantics {contentDescription="VFC de ejemplo: días 1 a 7, datos ficticios"}) {
  Canvas(Modifier.fillMaxWidth().height(height).testTag("physiology_preview_curve")) {
   val low=values.min()-2.0;val span=values.max()+2.0-low
   val points=values.mapIndexed {i,v ->ReadinessCurve.Point((i+1)/8f*size.width,size.height-((v-low)/span*size.height).toFloat())}
   val path=Path();path.moveTo(points.first().x,points.first().y)
   ReadinessCurve.segments(points).forEach {c ->path.cubicTo(c.control1.x,c.control1.y,c.control2.x,c.control2.y,c.end.x,c.end.y)}
   clipRect {drawPath(path,accent,style=Stroke(2.dp.toPx()))}
  }
  Row(Modifier.fillMaxWidth()) {listOf("1","3","5","7").forEach {Text(it,Modifier.weight(1f),textAlign=androidx.compose.ui.text.style.TextAlign.Center,style=MaterialTheme.typography.labelSmall)}}
 }
}
