package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import dev.repera.domain.ProgressDayPoint

/** HealthRecovery.vitalChart: linear observed trend, no static markers; <2 keeps axes. */
@Composable internal fun RecoveryVitalTrend(samples:List<ProgressDayPoint>,height:Dp=128.dp) {
 val values=samples.sortedBy {it.day}
 Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(12.dp)) {
  Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
   Text("VFC (RMSSD)",style=MaterialTheme.typography.titleSmall)
   values.lastOrNull()?.let {Text(dev.repera.domain.ReperaNumberFormat.decimal(it.value,maximumFractionDigits=0)+" ms",style=MaterialTheme.typography.labelMedium)}
  }
  if(values.size>=2) DayPointLineChart(values,valueFormat={"${formatWeight(it)} ms"},chartHeight=height,physiologyStyle=true)
  else {
   EmptyHealthChart(if(values.isEmpty()) "Repera necesita 2 días de VFC para evaluarte." else "Repera necesita 2 días medidos para evaluarte · lleva 1.",0.0,100.0,height)
  }
 }
}
