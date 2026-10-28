package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import dev.repera.domain.RecoveryEngine
import kotlin.math.roundToInt

/** Current preparation is Free and Pro, distinct from gated historical physiology charts. */
@Composable
internal fun TrainingReadinessCard(recovery:RecoveryState) {
 ReperaCard(Modifier.fillMaxWidth()) {Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
  Text("Preparación para entrenar",style=MaterialTheme.typography.titleMedium)
  val ready=recovery.readiness
  if(ready==null) Text("Necesitamos datos de sueño y entrenamientos recientes")
  else {
   val score=ready.score.coerceIn(0.0,10.0)
   val tint=when {score>=8 ->MaterialTheme.colorScheme.primary;score>=6 ->MaterialTheme.colorScheme.tertiary;else ->MaterialTheme.colorScheme.error}
   Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(12.dp)) {
    Text(when(ready.advice) {RecoveryEngine.TrainingReadinessAdvice.USUAL->"Puedes entrenar con normalidad";RecoveryEngine.TrainingReadinessAdvice.MODERATE->"Reduce la intensidad";RecoveryEngine.TrainingReadinessAdvice.REST->"Prioriza el descanso"},Modifier.weight(1f),color=tint,style=MaterialTheme.typography.titleMedium)
    val track=MaterialTheme.colorScheme.surfaceVariant
    Box(Modifier.size(95.dp).semantics(mergeDescendants=true) {contentDescription="Preparación ${score.roundToInt()} de 10"},contentAlignment=Alignment.Center) {
     Canvas(Modifier.fillMaxSize().padding(6.dp)) {
      val stroke=9.dp.toPx()
      drawCircle(track,style=Stroke(stroke))
      drawArc(tint,-90f,(score*36).toFloat(),false,Offset.Zero,Size(size.width,size.height),style=Stroke(stroke,cap=androidx.compose.ui.graphics.StrokeCap.Round))
     }
     Column(horizontalAlignment=Alignment.CenterHorizontally) {Text(score.roundToInt().toString(),style=MaterialTheme.typography.headlineMedium);Text("de 10",style=MaterialTheme.typography.labelSmall)}
    }
   }
   HorizontalDivider()
   val cardiac=recovery.vitals.lastOrNull {it.day==java.time.LocalDate.now()}
   val cardiacText=listOfNotNull(cardiac?.hrvMilliseconds?.let {"${it.roundToInt()} ms RMSSD"},cardiac?.restingHeartRateBpm?.let {"${it.roundToInt()} lpm"}).joinToString(" · ").ifBlank {"Sin datos"}
   Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(16.dp)) {
    ReadinessFactor("Sueño",recovery.lastNightHours?.let {"${formatWeight(it)} h"} ?: "Sin datos",Modifier.weight(1f))
    ReadinessFactor("Carga reciente",when {ready.fatiguePenalty>=2.3->"Alta";ready.fatiguePenalty>=1.1->"Moderada";else->"Baja"},Modifier.weight(1f))
   }
   Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(16.dp)) {
    ReadinessFactor("VFC · pulso",cardiacText,Modifier.weight(1f))
    ReadinessFactor("Cardio en Salud",ready.cardioMinutes48h?.let {"${it.roundToInt()} min"} ?: "Sin datos",Modifier.weight(1f))
   }
   ready.vitalNotes.forEach {Text(it,style=MaterialTheme.typography.bodySmall)}
  }
  Text("Estimación orientativa con tus datos de Salud; no es un diagnóstico.",style=MaterialTheme.typography.bodySmall)
 }}
}
@Composable
private fun ReadinessFactor(title:String,value:String,modifier:Modifier) {
 Column(modifier,verticalArrangement=Arrangement.spacedBy(3.dp)) {Text(title,style=MaterialTheme.typography.labelMedium);Text(value,style=MaterialTheme.typography.bodyMedium)}
}
