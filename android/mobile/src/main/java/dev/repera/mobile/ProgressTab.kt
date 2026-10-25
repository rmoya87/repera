package dev.repera.mobile
import androidx.compose.ui.platform.testTag

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Checkbox
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import dev.repera.domain.ExerciseAliasSearch
import dev.repera.domain.WodFormat
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import dev.repera.domain.MuscleTaxonomy
import dev.repera.domain.ProgressTimeRange
import dev.repera.mobile.monetization.LocalSubscriptions
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.delay


@Composable
internal fun ProgressTab(
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    onReviseFinishedSet: (String, String, String, Int, Double?, Int?) -> Unit,
    onDeleteFinishedSet: (String, String, String) -> Unit,
    onLogBodyWeight: (Double) -> Unit = {},
    onOpenBodyWeights:()->Unit = {},
    onOpenHistory:()->Unit = {},
    modifier: Modifier = Modifier
) {
    // Deliberately limited to the recent archive loaded by StateOverview.
    // It must never be presented as complete lifetime or billing-gated analytics.
    val recent = overview?.history.orEmpty()
    val subscriptions = LocalSubscriptions.current
    var selectedRange by rememberSaveable { mutableStateOf(ProgressTimeRange.WEEK.wire) }
    val snapshot = overview?.progressByRange?.get(selectedRange)
    val today = LocalDate.now()
    val weekStart = dev.repera.domain.StatsEngine.startOfWeek(today,overview?.trainingSettings?.weekStartsOnMonday ?: true)
    val dayFmt = java.time.format.DateTimeFormatter
        .ofLocalizedDate(java.time.format.FormatStyle.MEDIUM)
        .withLocale(java.util.Locale.getDefault())
    val dragListState = androidx.compose.foundation.lazy.rememberLazyListState()
    ProvideLazyDragAutoScroll(dragListState) {
    LazyColumn(
        state = dragListState,
        modifier = modifier.fillMaxSize().then(Modifier.testTag("progress_list")),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Progreso", style = MaterialTheme.typography.headlineMedium) }
        item { CountCard("Entrenamientos registrados", overview?.workouts, overview != null) }
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text("Esta semana", style = MaterialTheme.typography.titleLarge)
                    Text("${overview?.workoutsThisWeek ?: 0} sesiones esta semana",
                        style = MaterialTheme.typography.headlineSmall)
                    Text("Del ${weekStart.format(dayFmt)} al ${today.format(dayFmt)}")
                    WeekTrainingBars(overview?.weeklyDayTotals.orEmpty(),overview?.trainingSettings?.weekStartsOnMonday ?: true)
                    Text("El total semanal usa todo el historial local. " +
                        "Los detalles de abajo muestran las últimas 20 sesiones.",
                        style = MaterialTheme.typography.bodySmall)
                }
            }
        }
        item { TextButton(onClick=onOpenBodyWeights,enabled=overview!=null) {Text("Peso corporal · registrar e historial")} }
        item {
            androidx.compose.foundation.layout.FlowRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                ProgressTimeRange.entries.forEach { range ->
                    val allowed = subscriptions?.canSelectProgressRange(range)?.allowed ?: true
                    FilterChip(
                        selected = selectedRange == range.wire,
                        onClick = {
                            // Gate Gratis = solo semana (paridad iOS
                            // ReperaFeature.requiresPro / canSelectProgressRange).
                            if (allowed) {
                                selectedRange = range.wire
                            } else {
                                subscriptions?.presentPaywall(
                                    dev.repera.domain.monetization.PaywallContext.PROGRESS,
                                    feature = dev.repera.domain.monetization.ReperaFeature.PROGRESS_PERIOD_BEYOND_WEEK
                                )
                            }
                        },
                        label = { Text(range.title) }
                    )
                }
            }
        }
        if (snapshot != null) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Resumen · " + snapshot.range.subtitleLabel,
                            style = MaterialTheme.typography.titleLarge)
                        val s = snapshot.summary
                        Text("${s.sessionCount} sesiones · " +
                            "${formatVolume(s.volumeKg)} movidos")
                        s.averageMinutes?.let {
                            Text("Duración media: ${it.toInt()} min")
                        }
                        if (s.totalKcal > 0)
                            Text("Energía activa: ${s.totalKcal.toInt()} kcal")
                        s.averageCardioMinutes?.let {
                            Text("Cardio medio: ${it.toInt()} min")
                        }
                        snapshot.previousSummary?.let { prev ->
                            val delta = s.sessionCount - prev.sessionCount
                            val sign = if (delta >= 0) "+" else ""
                            Text("Periodo anterior: ${prev.sessionCount} sesiones " +
                                "($sign$delta)", style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            }
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Constancia", style = MaterialTheme.typography.titleMedium)
                        Text("${snapshot.streak} semanas seguidas entrenando")
                        Text("${snapshot.monthSessions} sesiones este mes",
                            style = MaterialTheme.typography.bodyMedium)
                        if (snapshot.mobilitySessions > 0) {
                            Text("Movilidad: ${snapshot.mobilitySessions} sesiones · " +
                                "${snapshot.mobilitySeconds / 60} min",
                                style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }
            overview?.recovery?.let { recovery ->
                if (recovery.readiness != null || recovery.sleepIndex != null) {
                    item {
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(
                                modifier = Modifier.padding(18.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Text("Recuperación",
                                    style = MaterialTheme.typography.titleLarge)
                                recovery.lastNightHours?.let { hours ->
                                    val index = recovery.sleepIndex
                                    Text("%.1f h de sueño".format(hours) +
                                        (index?.let { " · índice ${it / 10}/10" } ?: ""),
                                        style = MaterialTheme.typography.titleMedium)
                                }
                                recovery.readiness?.let { ready ->
                                    Text("Disposición para entrenar: " +
                                        "${ready.score.toInt()}/10",
                                        style = MaterialTheme.typography.titleMedium)
                                    Text(ready.advice.label,
                                        style = MaterialTheme.typography.bodyMedium)
                                    ready.vitalNotes.forEach { note ->
                                        Text("· $note",
                                            style = MaterialTheme.typography.bodySmall)
                                    }
                                }
                                Text("Estimación orientativa con tus datos de Salud; " +
                                    "no es un diagnóstico.",
                                    style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }
            overview?.chartsByRange?.get(selectedRange)?.let { charts ->
                item { ProgressChartsCard(charts) }
            }
            if (snapshot.heatmapTime.isNotEmpty()) {
                // ActivityHeatmapView iOS: UNA tarjeta con picker segmentado.
                item { ActivityHeatmapCard(snapshot.heatmapTime,
                    snapshot.heatmapVolume,
                    dev.repera.domain.ProgressTimeRange.entries.first { it.wire == selectedRange }) }
            }
            if (snapshot.cardioSeries.isNotEmpty()) {
                item {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(18.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("Cardio", style = MaterialTheme.typography.titleMedium)
                            Text("${snapshot.cardioSeries.sumOf { it.value }.toInt()} min en el rango",
                                style = MaterialTheme.typography.bodyMedium)
                            DayPointLineChart(snapshot.cardioSeries)
                        }
                    }
                }
            }

            if (snapshot.records.isNotEmpty()) {
                item {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(18.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("Récords del periodo",
                                style = MaterialTheme.typography.titleMedium)
                            snapshot.records.take(5).forEach { record ->
                                val date = java.time.Instant.ofEpochMilli(record.epochMillis)
                                    .atZone(java.time.ZoneId.systemDefault()).toLocalDate()
                                    .format(reperaDayFormatter)
                                Text("${record.exerciseName}: " +
                                    "${formatWeight(record.weightKg)} kg × ${record.reps} " +
                                    "(1RM est. ${formatWeight(record.estimatedOneRM)} kg) · $date",
                                    style = MaterialTheme.typography.bodyMedium)
                            }
                        }
                    }
                }
            }
            if (snapshot.muscleStatuses.isNotEmpty()) {
                item {
                    // Current Apple StatsView explicitly exposes map and bars to Free.
                    // Range selection remains gated separately; do not gate this whole card.
                    MuscleBalanceCard(
                        loadAll = snapshot.muscleLoadAll,
                        loadHard = snapshot.muscleLoadHard,
                        fatigueAll = snapshot.muscleFatigueAll,
                        fatigueHard = snapshot.muscleFatigueHard,
                        hasHardSets = snapshot.hasHardSets)
                }
            }
            if (snapshot.weightPoints.isNotEmpty()) {
                item {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(18.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("Peso corporal", style = MaterialTheme.typography.titleMedium)
                            val last = snapshot.weightPoints.last()
                            Text("Último: ${formatWeight(last.value)} kg " +
                                "(${last.day.format(reperaDayFormatter)})")
                            snapshot.weightDelta30d?.let { delta ->
                                val sign = if (delta >= 0) "+" else ""
                                Text("Cambio 30 días: $sign${formatWeight(delta)} kg",
                                    style = MaterialTheme.typography.bodyMedium)
                            }
                            overview?.healthGoals?.weightKg?.let {goal ->
                                val delta=last.value-goal
                                Text(if(kotlin.math.abs(delta)<0.3) "En objetivo (${formatWeight(goal)} kg)"
                                    else "${if(delta>0) "+" else ""}${formatWeight(delta)} kg vs ${formatWeight(goal)} kg")
                            }
                            DayPointLineChart(snapshot.weightPoints,goal=overview?.healthGoals?.weightKg)
                            var weightInput by rememberSaveable { mutableStateOf("") }
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically) {
                                OutlinedTextField(
                                    value = weightInput,
                                    onValueChange = { weightInput = it },
                                    label = { Text("Peso de hoy (kg)") },
                                    singleLine = true,
                                    keyboardOptions = KeyboardOptions(
                                        keyboardType = KeyboardType.Decimal),
                                    modifier = Modifier.weight(1f)
                                )
                                TextButton(onClick = {
                                    weightInput.replace(',', '.').toDoubleOrNull()?.let {
                                        onLogBodyWeight(it)
                                        weightInput = ""
                                    }
                                }, enabled = !busy) { Text("Registrar") }
                            }
                        }
                    }
                }
            }
        }
        if (overview?.weeklyMuscleGroups?.isNotEmpty() == true) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Series por grupo · esta semana",
                            style = MaterialTheme.typography.titleMedium)
                        val groups = overview.weeklyMuscleGroups.take(8)
                        val ceiling = groups.maxOf { it.sets }.coerceAtLeast(1).toFloat()
                        groups.forEach { group ->
                            Text("${group.group} · ${group.sets} series",
                                style = MaterialTheme.typography.bodySmall)
                            LinearProgressIndicator(
                                progress = { group.sets.toFloat() / ceiling },
                                modifier = Modifier.fillMaxWidth(),
                                color = brandGreen
                            )
                        }
                        Text("Distribución por grupo del catálogo; no mide fatiga ni recuperación.",
                            style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }
        item {TextButton(onClick=onOpenHistory,enabled=overview!=null) {Text("Ver historial completo")} }
        if (recent.isNotEmpty()) {
            item {
                Text("Resultados recientes", style = MaterialTheme.typography.titleMedium)
            }
            items(recent, key = { "progress:" + it.id }) { workout ->
                WorkoutHistoryCard(workout, busy,
                        onReviseFinishedSet, onDeleteFinishedSet)
            }
        } else {
            item { Text("Todavía no hay entrenamientos para analizar") }
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
    }
}


private fun formatVolume(volumeKg: Double): String = when {
    volumeKg >= 1000 -> "%.1f t".format(volumeKg / 1000)
    else -> "${volumeKg.toInt()} kg"
}

internal fun formatWeight(value: Double): String =
    if (value % 1.0 == 0.0) value.toInt().toString() else "%.1f".format(value)
