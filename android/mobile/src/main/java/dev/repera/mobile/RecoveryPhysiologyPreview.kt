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
import dev.repera.domain.ProgressDayPoint
import java.time.LocalDate

/** Fixed Apple preview, independent of all owner samples and not interactive. */
internal object RecoveryPhysiologyPreview {
    val hrv=listOf(46.0,51.0,48.0,55.0,53.0,62.0,58.0)
    val resting=listOf(66.0,63.0,65.0,61.0,60.0,62.0,58.0)
    val breathing=listOf(16.0,15.0,15.0,14.0,16.0,14.0,13.0)
}

@Composable
internal fun RecoveryPhysiologyPreviewCard(today:LocalDate) {
    Card(Modifier.fillMaxWidth().semantics {contentDescription="Ejemplo de constantes fisiológicas, datos ficticios."}) {
        Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
            Text("Constantes · Ejemplo ficticio",style=MaterialTheme.typography.titleMedium)
            Text("No son tus datos de Salud",style=MaterialTheme.typography.bodySmall)
            Text("Variabilidad cardíaca (VFC) · 58 ms",style=MaterialTheme.typography.titleSmall)
            DayPointLineChart(RecoveryPhysiologyPreview.hrv.mapIndexed {i,v ->ProgressDayPoint(today.minusDays((6-i).toLong()),v)},valueFormat={"${it.toInt()} ms"},interactive=false)
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
            Canvas(Modifier.fillMaxWidth().height(98.dp)) {
                val width=size.width/(values.size+2)
                val maximum=(values.maxOrNull() ?: 1.0).coerceAtLeast(1.0)
                values.forEachIndexed {i,v ->
                    val height=(v/maximum*size.height).toFloat()
                    drawRoundRect(color,Offset((i+1)*width+width*0.15f,size.height-height),Size(width*0.7f,height),androidx.compose.ui.geometry.CornerRadius(3.dp.toPx()))
                }
            }
        }
    }
}
