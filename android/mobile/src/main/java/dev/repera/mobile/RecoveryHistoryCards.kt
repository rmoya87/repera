package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.repera.domain.*
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.platform.testTag

/** Only observed device-local samples. RMSSD is not labeled as Apple's SDNN. */
@Composable
internal fun RecoveryHistoryCards(recovery:RecoveryState,range:ProgressTimeRange,monday:Boolean,pro:Boolean=true,outerHorizontalPaddingDp:Float=0f) {
 val today=java.time.LocalDate.now()
 val trend=recovery.trend.filter {range.contains(it.day,today,monday)}
 val sleep=SleepPeriodSummary.forRange(recovery.nights,range,today,monday)
 val nights=sleep.nights
 val vitals=recovery.vitals.filter {range.contains(it.day,today,monday)}
 BoxWithConstraints(Modifier.fillMaxWidth()) {
 val columns=adaptiveCardColumns(maxWidth.value,outerHorizontalPaddingDp)
 val readinessHeight=readinessChartHeightDp((maxWidth.value-16f*(columns-1))/columns,columns>1).dp
 val sleepHeight=sleepChartHeightDp((maxWidth.value-16f*(columns-1))/columns,columns>1).dp
 val latestForHeight=recovery.vitals.maxByOrNull {it.day}
 val additionalVitals=latestForHeight?.let {it.oxygenSaturationPercent!=null || it.wristTemperatureCelsius!=null || it.heartRateRecoveryBpm!=null} ?: false
 val physiologyHeight=physiologyChartHeightDp((maxWidth.value-16f*(columns-1))/columns,columns>1,additionalVitals).dp
 val cards=mutableListOf<@Composable ()->Unit>()
 cards.add {TrainingReadinessCard(recovery)}
 cards.add {
 Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
  Text(if(pro) "Evolución de recuperación" else "Evolución de recuperación · Ejemplo ficticio",style=MaterialTheme.typography.titleMedium)
  if(pro) {
   if(trend.size<2) {
    EmptyHealthChart("Aún no hay suficientes registros para ver la recuperación.",0.0,10.0,readinessHeight)
   } else DayPointLineChart(trend,valueFormat={"${kotlin.math.round(it).toInt()}/10"},bounds=0.0..10.0,readinessStyle=true,chartHeight=readinessHeight)
  } else {
   DayPointLineChart(listOf(5.0,6.0,7.0,6.0,8.0,7.0,9.0).mapIndexed {i,v ->ProgressDayPoint(today.minusDays((6-i).toLong()),v)},valueFormat={"${it.toInt()}/10"},bounds=0.0..10.0,interactive=false,readinessStyle=true,readinessGradient=false,readinessPreview=true,chartHeight=readinessHeight)
   Text("No son tus datos de recuperación",style=MaterialTheme.typography.bodySmall)
  }
  Text("Mañanas con sueño observado a las 07:00. No proyecta una nota futura con sueño supuesto.",style=MaterialTheme.typography.bodySmall)
 }}
 }
 cards.add {
 Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
  Text("Sueño · ${range.title}",style=MaterialTheme.typography.titleMedium)
  if(nights.isEmpty()) {
   EmptyHealthChart("Sin noches registradas en el periodo. Activa el análisis de descanso en Ajustes para leer sueño.",0.0,10.0,sleepHeight)
  }
  else {
   Text(if(sleep.outsideRange) "Fuera del periodo seleccionado: últimas noches disponibles" else if(nights.size==1) "Una noche registrada" else "Media del periodo",style=MaterialTheme.typography.bodySmall)
   Text("${formatWeight(sleep.hours ?: 0.0)} h",style=MaterialTheme.typography.headlineSmall)
   val total=sleep.deep+sleep.rem+sleep.light
   if(total>0.2) Row(Modifier.fillMaxWidth().height(20.dp)) {
    listOf(sleep.deep to MaterialTheme.colorScheme.primary,sleep.rem to MaterialTheme.colorScheme.tertiary,sleep.light to MaterialTheme.colorScheme.secondaryContainer).forEach {(hours,color) ->
     if(hours>0) Surface(Modifier.weight(hours.toFloat()).fillMaxHeight(),color=color) {}
    }
   }
   Text("Profundo ${formatWeight(sleep.deep)} h · REM ${formatWeight(sleep.rem)} h · Ligero/otros ${formatWeight(sleep.light)} h",style=MaterialTheme.typography.bodySmall)
   RecoverySleepChart(nights,sleepHeight)
   nights.sortedByDescending {it.day}.forEach {night ->
    Text("${night.day.format(reperaDayFormatter)} · ${formatWeight(night.hours)} h",style=MaterialTheme.typography.bodyMedium)
    Text("Profundo: ${formatWeight(night.deepHours)} h · REM: ${formatWeight(night.remHours)} h",style=MaterialTheme.typography.bodySmall)
   }
  }
 }}
 }
 cards.add {
 if(pro) {
 Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
  Text("Constantes · ${range.title}",style=MaterialTheme.typography.titleMedium)
  val hrv=vitals.mapNotNull {it.hrvMilliseconds?.let {v ->ProgressDayPoint(it.day,v)}}
  val rest=vitals.mapNotNull {it.restingHeartRateBpm?.let {v ->ProgressDayPoint(it.day,v)}}
  RecoveryVitalTrend(hrv,physiologyHeight)
  Text("RMSSD de Health Connect no equivale a SDNN de Apple Salud.",style=MaterialTheme.typography.bodySmall)
  val breathing=vitals.mapNotNull {it.respiratoryRateBpm?.let {v ->ProgressDayPoint(it.day,v)}}
  RecoveryVitalBars(rest,breathing)
  // Apple 188624cc (physiologyContent): tiles del ÚLTIMO día registrado,
  // independientes del rango de las gráficas; ausente = no se pinta.
  val latest=recovery.vitals.maxByOrNull {it.day}
  if(latest!=null&&(latest.oxygenSaturationPercent!=null||latest.wristTemperatureCelsius!=null))
   Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(10.dp)) {
    latest.oxygenSaturationPercent?.let {v ->Column(Modifier.weight(1f).testTag("recovery_tile_spo2")) {
     Text("Oxígeno en sangre",style=MaterialTheme.typography.labelMedium,color=MaterialTheme.colorScheme.onSurfaceVariant)
     Text(dev.repera.domain.ReperaNumberFormat.decimal(v,maximumFractionDigits=0)+" %",style=MaterialTheme.typography.titleLarge)}}
    latest.wristTemperatureCelsius?.let {v ->Column(Modifier.weight(1f).testTag("recovery_tile_temp")) {
     Text("T nocturna",style=MaterialTheme.typography.labelMedium,color=MaterialTheme.colorScheme.onSurfaceVariant)
     Text(dev.repera.domain.ReperaNumberFormat.decimal(v,maximumFractionDigits=1)+" °C",style=MaterialTheme.typography.titleLarge)}}
   }
  latest?.heartRateRecoveryBpm?.let {v ->Column(Modifier.fillMaxWidth().testTag("recovery_tile_hr_recovery")) {
   Text("Recuperación cardíaca 1 min",style=MaterialTheme.typography.labelMedium,color=MaterialTheme.colorScheme.onSurfaceVariant)
   Text(Math.round(v).toString()+" lpm",style=MaterialTheme.typography.titleLarge)}}
  if(latest?.wristTemperatureCelsius!=null) Text("Solo muñeca con referencia absoluta y coincidencia con sueño observado. No es temperatura corporal central ni equivale al sensor de Apple Watch.",style=MaterialTheme.typography.bodySmall)
  Text("Solo datos registrados. Un dato ausente no significa normalidad. No es un diagnóstico.",style=MaterialTheme.typography.bodySmall)
 }}
 } else RecoveryPhysiologyPreviewCard(today,physiologyHeight)
 }
 if(recovery.menstrualDays.isNotEmpty()) cards.add {CycleHistoryCard(recovery,monday)}
  Column(Modifier.fillMaxWidth().testTag("recovery_columns_$columns"),verticalArrangement=Arrangement.spacedBy(16.dp)) {
   cards.chunked(columns).forEach {row ->
    Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(16.dp),verticalAlignment=androidx.compose.ui.Alignment.Top) {
     row.forEach {card ->Box(Modifier.weight(1f)) {card()}}
     repeat(columns-row.size) {Spacer(Modifier.weight(1f))}
    }
   }
  }
 }
}

@Composable
private fun CycleHistoryCard(recovery:RecoveryState,monday:Boolean) {
 val today=java.time.LocalDate.now()
 val phase=RecoveryEngine.cyclePhase(recovery.menstrualDays,today)
 val label=when(phase) {
  RecoveryEngine.CyclePhase.MENSTRUAL->"Menstruación registrada"
  RecoveryEngine.CyclePhase.FOLLICULAR->"Fase folicular estimada"
  RecoveryEngine.CyclePhase.OVULATORY->"Ovulación aproximada"
  RecoveryEngine.CyclePhase.LUTEAL->"Fase lútea estimada"
  RecoveryEngine.CyclePhase.UNKNOWN->"Fase no disponible"
 }
 Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
  Text("Ciclo menstrual",style=MaterialTheme.typography.titleMedium)
  Text(label,style=MaterialTheme.typography.titleSmall)
  if(recovery.menstrualDays.isEmpty()) Text("Sin registros de menstruación. Activa el seguimiento del ciclo en Ajustes para leer los datos autorizados.")
  else {
   val recent=recovery.menstrualDays.filter {!it.isBefore(today.minusDays(89)) && !it.isAfter(today)}
   if(recent.isEmpty()) Text("Sin registros en los últimos 90 días")
   else DayPointLineChart(recent.map {ProgressDayPoint(it,1.0)},valueFormat={"Menstruación registrada"})
   Text("Registros de menstruación de los últimos 90 días",style=MaterialTheme.typography.bodySmall)
  }
  Text("Calendario de las últimas seis semanas",style=MaterialTheme.typography.titleSmall)
  val firstWeekday=if(monday) java.time.DayOfWeek.MONDAY else java.time.DayOfWeek.SUNDAY
  val currentWeek=today.with(java.time.temporal.TemporalAdjusters.previousOrSame(firstWeekday))
  val start=currentWeek.minusWeeks(5)
  Row(Modifier.fillMaxWidth()) {(0..6).forEach {offset ->
   Text(start.plusDays(offset.toLong()).dayOfWeek.getDisplayName(java.time.format.TextStyle.NARROW,java.util.Locale("es")),Modifier.weight(1f))
  }}
  (0..5).forEach {week ->Row(Modifier.fillMaxWidth()) {(0..6).forEach {offset ->
   val day=start.plusDays((week*7+offset).toLong())
   val observed=day in recovery.menstrualDays
   val background=if(observed) MaterialTheme.colorScheme.tertiaryContainer else if(day==today) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
   Surface(Modifier.weight(1f).padding(1.dp),color=background,shape=MaterialTheme.shapes.small) {
    Text(day.dayOfMonth.toString(),Modifier.padding(vertical=6.dp).then(Modifier.semantics {contentDescription="${day.format(reperaDayFormatter)}${if(observed) ", menstruación registrada" else ""}"}),textAlign=androidx.compose.ui.text.style.TextAlign.Center,style=MaterialTheme.typography.bodySmall)
   }
  }}}
  Text("Días registrados de menstruación",style=MaterialTheme.typography.bodySmall)
  if(recovery.positiveOvulationTests.isNotEmpty()) Text("Pruebas de ovulación positivas registradas: ${recovery.positiveOvulationTests.size}")
  Text("Fase aproximada solo si hay suficientes ciclos compatibles. Nunca equivale a una ovulación confirmada ni debe utilizarse para anticoncepción.",style=MaterialTheme.typography.bodySmall)
  Text("Solo en este dispositivo. No se incluye en Drive, copias ni datos compartidos con centros.",style=MaterialTheme.typography.bodySmall)
 }}
}
