package dev.repera.mobile
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.ui.platform.LocalDensity
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
import androidx.compose.material3.SegmentedButton
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


@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
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
    healthAccess: HealthAccessState = HealthAccessState.UNKNOWN,
    onHealthConnect: () -> Unit = {},
    onOpenExercise:(String)->Unit = {},
    onOpenSports:()->Unit = {},
    onProgressRangeChange:(String)->Unit = {},
    modifier: Modifier = Modifier,
    accountId: String = ""
) {
    // The inline archive is recent; aggregate snapshots use the complete local archive.
    val recent = overview?.history.orEmpty()
    val subscriptions = LocalSubscriptions.current
    var topic by rememberSaveable {mutableStateOf("Entreno")}
    val pro=subscriptions?.isPro ?: true
    var selectedRange by rememberSaveable { mutableStateOf(ProgressTimeRange.WEEK.wire) }
    LaunchedEffect(pro) {if(!pro) selectedRange=ProgressTimeRange.WEEK.wire}
    // Apple 479d8407: la cobertura de Salud sigue al rango elegido (tambien al
    // aparecer la pestana); MainActivity solo amplia la ventana si hace falta.
    LaunchedEffect(selectedRange) { onProgressRangeChange(selectedRange) }
    val snapshot = overview?.progressByRange?.get(selectedRange)
    val today = LocalDate.now()
    val weekStart = dev.repera.domain.StatsEngine.startOfWeek(today,overview?.trainingSettings?.weekStartsOnMonday ?: true)
    val dayFmt = java.time.format.DateTimeFormatter
        .ofLocalizedDate(java.time.format.FormatStyle.MEDIUM)
        .withLocale(java.util.Locale("es", "ES"))
    val dragListState = androidx.compose.foundation.lazy.rememberLazyListState()
    // Apple StatsView: las tres pestañas comparten scroll; al cambiar se vuelve al encabezado sin animación
    // (un offset heredado de Entreno dejaba la vista vacía). No se dispara en la composición inicial/restaurada.
    var shownTopic by remember {mutableStateOf(topic)}
    LaunchedEffect(topic) {if(topic!=shownTopic) {shownTopic=topic;dragListState.scrollToItem(0)}}
    ProvideLazyDragAutoScroll(dragListState) {
    LazyColumn(
        state = dragListState,
        modifier = modifier.fillMaxSize().then(Modifier.testTag("progress_list")),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Progreso", style = MaterialTheme.typography.headlineMedium) }
        item {
            androidx.compose.material3.SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                listOf("Entreno","Actividad","Recuperación").forEachIndexed {index,label ->
                    SegmentedButton(selected=topic==label,onClick={topic=label},modifier=Modifier.testTag("progress_topic_$index"),
                        shape=androidx.compose.material3.SegmentedButtonDefaults.itemShape(index,3),
                        contentPadding=PaddingValues(horizontal=6.dp,vertical=8.dp),
                        icon={}, label={Text(label,maxLines=2,
                            style=MaterialTheme.typography.labelMedium)})
                }
            }
        }
        if(topic=="Entreno") {
        item { CountCard("Entrenamientos registrados", overview?.workouts, overview != null) }
        // Apple StatsView: acceso a evolución y récords de deportes si hay actividades En vivo finalizadas.
        if(overview?.liveSportSessions.orEmpty().isNotEmpty()) item {
            Card(Modifier.fillMaxWidth().clickable(onClick=onOpenSports).testTag("progress_sports_link")) {
                Row(Modifier.padding(18.dp).fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
                    Text("Deportes · evolución y récords");Text("›")
                }
            }
        }
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
        }
        if(topic=="Actividad") item { TextButton(onClick=onOpenBodyWeights,enabled=overview!=null) {Text("Peso corporal · registrar e historial")} }
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
            if(topic=="Entreno") {
            item {
                val tiles=ProgressTilesModel.tiles(snapshot.summary.sessionCount,snapshot.summary.totalMinutes,snapshot.previousSummary?.sessionCount,
                    snapshot.previousSummary?.totalMinutes,snapshot.streak,snapshot.previousStreak,pro)
                // Apple OGAdaptiveMetricLayout(minimumItemWidth: 96): columns follow the available width, and the
                // minimum scales with the font so large text wraps to fewer columns instead of clipping.
                BoxWithConstraints(Modifier.fillMaxWidth()) {
                    val minItem=(96*LocalDensity.current.fontScale).dp
                    val cols=((maxWidth+8.dp)/(minItem+8.dp)).toInt().coerceIn(1,tiles.size)
                    Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {tiles.chunked(cols).forEach {rowTiles ->
                        Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(8.dp)) {rowTiles.forEach {t ->
                            Card(Modifier.weight(1f)) {Column(Modifier.fillMaxWidth().padding(vertical=12.dp,horizontal=6.dp),horizontalAlignment=Alignment.CenterHorizontally) {
                                Text(t.label,style=MaterialTheme.typography.labelMedium)
                                Text(t.value,style=MaterialTheme.typography.headlineMedium,maxLines=1)
                                Text(ProgressTilesModel.deltaLabel(t.delta, t.deltaUnit) ?: "+0",style=MaterialTheme.typography.labelSmall,
                                    color=if(ProgressTilesModel.deltaLabel(t.delta, t.deltaUnit)==null) androidx.compose.ui.graphics.Color.Transparent else MaterialTheme.colorScheme.onSurfaceVariant)
                            }}}
                            repeat(cols-rowTiles.size) {Spacer(Modifier.weight(1f))}
                        }}}
                }
            }
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Resumen · " + snapshot.range.subtitleLabel,
                            style = MaterialTheme.typography.titleLarge)
                        val s = snapshot.summary
                        Text("${formatVolume(s.volumeKg)} movidos")
                        if (s.totalKcal > 0)
                            Text("Energía activa: ${s.totalKcal.toInt()} kcal")
                        s.averageCardioMinutes?.let {
                            Text("Cardio medio: ${it.toInt()} min")
                        }
                    }
                }
            }
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Constancia", style = MaterialTheme.typography.titleMedium)
                        Text("${snapshot.monthSessions} sesiones este mes",
                            style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
            }
            if(topic=="Recuperación") {
                val recovery=overview?.recovery ?: RecoveryState(null,null,null,null)
                item {RecoveryHistoryCards(recovery,ProgressTimeRange.entries.first {it.wire==selectedRange},overview?.trainingSettings?.weekStartsOnMonday ?: true,pro,outerHorizontalPaddingDp=32f)}
                if(!pro) item {dev.repera.mobile.monetization.ProTeaserCard(title="Recuperación completa",bodyText="Consulta cómo evolucionan tu descanso y tu preparación para entrenar.",cta="Descubrir Repera Pro",appearance=dev.repera.mobile.monetization.ProTeaserAppearance.RECOVERY,onClick={
                    subscriptions?.presentPaywall(dev.repera.domain.monetization.PaywallContext.PROGRESS,feature=dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS)
                })}
            }
            if(topic=="Actividad") {
            val charts=if(pro) overview?.chartsByRange?.get(selectedRange) else ProgressPreview.charts(today,overview?.trainingSettings?.weekStartsOnMonday ?: true)
            item {
                Column(verticalArrangement=Arrangement.spacedBy(12.dp)) {
                if(!pro) Text("Ejemplo · FC y calorías ficticias, no son tus datos de Salud")
                val prepared=charts ?: dev.repera.domain.ProgressPreparedCharts(
                    dev.repera.domain.ProgressTimeRange.entries.first {it.wire==selectedRange},overview?.trainingSettings?.weekStartsOnMonday ?: true,
                    emptyList(),emptyList(),0.0,null,dev.repera.domain.ProgressSeriesGranularity.DAY)
                ProgressHealthGrid(
                    score={if(pro) SessionScoreProgressCard(overview?.sessionScoresByRange?.get(selectedRange).orEmpty())
                        else SessionScoreProgressCard((0..6).map {i ->dev.repera.domain.ProgressDayPoint(today.minusDays(6L-i),listOf(6.0,7.0,7.0,8.0,6.0,8.0,9.0)[i])},preview=true)},
                    cardio={ProgressCardioCard(prepared,!pro)},calories={ProgressCaloriesCard(prepared,!pro)},
                    weight={if(!pro) WeightPreviewCard(today) else ProgressWeightCard(snapshot.weightPoints,snapshot.weightDelta30d,overview?.healthGoals?.weightKg,accountId,busy,onLogBodyWeight)})
                }
            }
            val healthPrompt=if(pro) ProgressHealthPrompt.kind(healthAccess,charts) else ProgressHealthPromptKind.NONE
            if(healthPrompt!=ProgressHealthPromptKind.NONE) item {
                Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
                    if(healthPrompt==ProgressHealthPromptKind.NOT_AUTHORIZED) {
                        Text("Salud sin permiso de lectura",style=MaterialTheme.typography.titleMedium)
                        Text("Autoriza Health Connect para ver FC y kcal.")
                        TextButton(onClick=onHealthConnect) {Text("Autorizar Salud")}
                    } else {
                        Text("Health Connect no disponible",style=MaterialTheme.typography.titleMedium)
                        Text("Este dispositivo no tiene Health Connect disponible, así que no hay FC ni kcal que mostrar.")
                    }
                }}
            }
            if(!pro) item {dev.repera.mobile.monetization.ProTeaserCard(title="Métricas de actividad avanzadas",bodyText="Consulta frecuencia cardíaca, calorías y evolución de peso con Repera Pro.",cta="Descubrir Repera Pro",appearance=dev.repera.mobile.monetization.ProTeaserAppearance.ACTIVITY,onClick={subscriptions?.presentPaywall(dev.repera.domain.monetization.PaywallContext.PROGRESS,feature=dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS)})}
            }
            if(topic=="Entreno") {
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

            // Apple order (StatsView training): tiles, activity, muscle balance, mobility, then
            // exercises/records or the Free preview + teaser. The card has its own empty text,
            // so it is not hidden when there are no muscle statuses (Apple does not hide it).
            item {
                // Current Apple StatsView explicitly exposes map and bars to Free.
                MuscleBalanceCard(
                    loadAll = snapshot.muscleLoadAll,
                    loadHard = snapshot.muscleLoadHard,
                    fatigueAll = snapshot.muscleFatigueAll,
                    fatigueHard = snapshot.muscleFatigueHard,
                    hasHardSets = snapshot.hasHardSets,
                    includesEstimatedWodMuscles = snapshot.includesEstimatedWodMuscles)
            }
            if(snapshot.mobilitySessions>0) item {ProgressMobilityCard(snapshot.mobilitySessions,snapshot.mobilitySeconds,
                if(subscriptions==null || subscriptions.isPro) snapshot.chartExercises.filter {it.isMobility}.take(3) else emptyList(),onOpenExercise)}
            if(subscriptions==null || subscriptions.isPro) {
                item {AdaptiveCardPair(
                    first={ProgressExercisesCard(snapshot.chartExercises,onOpenExercise)},
                    second={ProgressRecordsCard(snapshot.records,onOpenExercise)})}
            }
            else item {ProgressExerciseTrendPreview(today)}
            if(!(subscriptions==null || subscriptions.isPro)) item {dev.repera.mobile.monetization.ProTeaserCard(title="Descubre todo tu progreso",bodyText="Analiza tu evolución por ejercicio y tus marcas personales.",cta="Descubrir Repera Pro",appearance=dev.repera.mobile.monetization.ProTeaserAppearance.PROGRESS,onClick={
                subscriptions.presentPaywall(dev.repera.domain.monetization.PaywallContext.PROGRESS,feature=dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS)
            })}
            }
        }
        if(topic=="Entreno") {
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
        // Apple 2ac224f5: el historial solo aparece bajo el progreso de entreno,
        // no en Recuperación ni Actividad.
        if (topic=="Entreno") item {TextButton(onClick=onOpenHistory,enabled=overview!=null) {Text("Ver historial completo")} }
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
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
    }
}


private fun formatVolume(volumeKg: Double): String = when {
    volumeKg >= 1000 -> "${dev.repera.domain.ReperaNumberFormat.decimal(volumeKg / 1000)} t"
    else -> "${volumeKg.toInt()} kg"
}

@Composable
internal fun WeightStatTiles(latestKg: Double?, goalKg: Double?) {
    val l = dev.repera.domain.WeightStatsTiles.labels(latestKg, goalKg)
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        listOf("Actual" to l.actual, "Objetivo" to l.goal, "Δ" to l.delta).forEach { (title, value) ->
            Column(Modifier.weight(1f).background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(10.dp)).padding(horizontal = 8.dp, vertical = 10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(title, style = MaterialTheme.typography.labelSmall)
                Text(value, style = MaterialTheme.typography.titleSmall, maxLines = 1)
            }
        }
    }
}

internal fun formatWeight(value: Double): String =
    dev.repera.domain.ReperaNumberFormat.decimal(value)

/** Same weight summary surface for Free, with explicitly fictitious points. */
@Composable
internal fun WeightPreviewCard(today:LocalDate) {
    val points=ProgressPreview.weight(today)
    Card(Modifier.fillMaxWidth(),colors=androidx.compose.material3.CardDefaults.cardColors(containerColor=MaterialTheme.colorScheme.surface)) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
        Text("Peso corporal · ejemplo",style=MaterialTheme.typography.titleMedium)
        Text("Datos ficticios. Objetivo de ejemplo: 74 kg")
        DayPointLineChart(points,goal=74.0,interactive=false,weightStyle=true,weightPreview=true)
        WeightStatTiles(points.lastOrNull()?.value,74.0)
    }}
}

@Composable internal fun ProgressWeightCard(points:List<dev.repera.domain.ProgressDayPoint>,delta30d:Double?,goalKg:Double?,accountId:String,busy:Boolean,onLogBodyWeight:(Double)->Unit) {
 if(points.isEmpty()) Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp)) {
  Text("Peso corporal",style=MaterialTheme.typography.titleMedium)
  Text("Sin mediciones en el periodo.")
  WeightStatTiles(null,goalKg)
  EmptyHealthChartAxes(goalKg?.minus(2) ?: 60.0,goalKg?.plus(2) ?: 90.0,210.dp)
 }} else {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(18.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("Peso corporal", style = MaterialTheme.typography.titleMedium)
                            val last = points.last()
                            Text("Último: ${formatWeight(last.value)} kg " +
                                "(${last.day.format(reperaDayFormatter)})")
                            delta30d?.let { delta ->
                                val sign = if (delta >= 0) "+" else ""
                                Text("Cambio 30 días: $sign${formatWeight(delta)} kg",
                                    style = MaterialTheme.typography.bodyMedium)
                            }
                            WeightStatTiles(last.value, goalKg)
                            DayPointLineChart(points,goal=goalKg,weightStyle=true)
                            val weightScope=remember(accountId) {org.json.JSONArray(listOf(accountId,"progress-weight-input")).toString()}
                            val weightSaver=remember(weightScope) {androidx.compose.runtime.saveable.Saver<String,String>(save={saveScopedEditorValue(weightScope,it)},restore={restoreScopedEditorValue(weightScope,it)})}
                            var weightInput by rememberSaveable(accountId,stateSaver=weightSaver) { mutableStateOf("") }
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
                                    dev.repera.domain.ReperaNumberFormat.parse(weightInput)?.let {
                                        onLogBodyWeight(it)
                                        weightInput = ""
                                    }
                                }, enabled = !busy) { Text("Registrar") }
                            }
                        }
                    }
 }
}
