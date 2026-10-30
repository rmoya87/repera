package dev.repera.mobile
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.ui.platform.testTag
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import dev.repera.domain.ProgressTimeRange
import dev.repera.mobile.monetization.LocalSubscriptions

/** Rellena gráficas vacías con datos ficticios para revisión visual. Desactivar cuando no haga falta. */
internal const val PROGRESS_DEMO_CHARTS = true


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
    onOpenWorkoutDetail: (String) -> Unit = {},
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
    // R5 P1-8: restaurar segmentado Entreno/Actividad/Recuperación (regresión #170).
    var topic by rememberSaveable { mutableStateOf("Entreno") }
    val pro=subscriptions?.isPro ?: true
    var selectedRange by rememberSaveable { mutableStateOf(ProgressTimeRange.WEEK.wire) }
    var showRangePicker by rememberSaveable { mutableStateOf(false) }
    val selectedRangeTitle = remember(selectedRange) {
        ProgressTimeRange.entries.firstOrNull { it.wire == selectedRange }?.title ?: "Esta semana"
    }
    LaunchedEffect(pro) {if(!pro) selectedRange=ProgressTimeRange.WEEK.wire}
    // Apple 479d8407: la cobertura de Salud sigue al rango elegido (tambien al
    // aparecer la pestana); MainActivity solo amplia la ventana si hace falta.
    LaunchedEffect(selectedRange) { onProgressRangeChange(selectedRange) }
    val rawSnapshot = overview?.progressByRange?.get(selectedRange)
    val today = LocalDate.now()
    val monday = overview?.trainingSettings?.weekStartsOnMonday ?: true
    val snapshot = remember(rawSnapshot, selectedRange, today, PROGRESS_DEMO_CHARTS) {
        if (!PROGRESS_DEMO_CHARTS || rawSnapshot == null) rawSnapshot
        else enrichSnapshotWithDemo(rawSnapshot, today)
    }
    val demoBanner = PROGRESS_DEMO_CHARTS
    val dragListState = androidx.compose.foundation.lazy.rememberLazyListState()
    var shownTopic by remember { mutableStateOf(topic) }
    LaunchedEffect(topic) {
        if (topic != shownTopic) {
            shownTopic = topic
            dragListState.scrollToItem(0)
        }
    }
    ProvideLazyDragAutoScroll(dragListState) {
    if (showRangePicker) {
        ProgressRangePickerSheet(
            selectedWire = selectedRange,
            isPro = pro,
            subscriptions = subscriptions,
            onDismiss = { showRangePicker = false },
            onSelect = { wire ->
                showRangePicker = false
                selectedRange = wire
            }
        )
    }
    LazyColumn(
        state = dragListState,
        modifier = modifier.fillMaxSize().then(Modifier.testTag("progress_list")),
        contentPadding = reperaScrollContentPadding(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            ReperaPageHeader(
                title = "Progreso",
                subtitle = selectedRangeTitle,
                trailing = {
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.CalendarMonth,
                        contentDescription = "Filtrar periodo",
                        onClick = { showRangePicker = true },
                        modifier = Modifier.testTag("progress_range_picker")
                    )
                }
            )
        }
        if (demoBanner) {
            item {
                Text(
                    "Datos de ejemplo en gráficas vacías (revisión visual)",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        stickyHeader {
            Surface(
                color = MaterialTheme.colorScheme.background,
                modifier = Modifier.fillMaxWidth()
            ) {
                ReperaTopicSegmentedPicker(
                    options = listOf("Entreno", "Actividad", "Recuperación"),
                    selected = topic,
                    onSelected = { topic = it },
                    modifier = Modifier.padding(bottom = 4.dp)
                )
            }
        }
        if (topic == "Entreno" && snapshot != null) {
            item { ProgressMetricsTilesGrid(snapshot, pro) }
        }
        if (topic == "Entreno") {
        // Apple StatsView: acceso a evolución y récords de deportes si hay actividades En vivo finalizadas.
        if(overview?.liveSportSessions.orEmpty().isNotEmpty()) item {
            ReperaCard(onClick = onOpenSports, modifier = Modifier.fillMaxWidth().testTag("progress_sports_link")) {
                Row(Modifier.padding(16.dp).fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
                    Text("Deportes · evolución y récords");Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, contentDescription=null, tint=MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        }
        // iOS StatsView: tiles + heatmap Actividad + Equilibrio; sin Resumen/Constancia/Cardio en Entreno.
        if (snapshot != null) {
            if(topic=="Recuperación") {
                val baseRecovery=overview?.recovery ?: RecoveryState(null,null,null,null)
                val recovery=if(PROGRESS_DEMO_CHARTS) enrichRecoveryWithDemo(baseRecovery,today) else baseRecovery
                item {RecoveryHistoryCards(recovery,ProgressTimeRange.entries.first {it.wire==selectedRange},monday,pro || PROGRESS_DEMO_CHARTS,outerHorizontalPaddingDp=32f)}
                if(!pro) item {dev.repera.mobile.monetization.ProTeaserCard(title="Recuperación completa",bodyText="Consulta cómo evolucionan tu descanso y tu preparación para entrenar.",cta="Descubrir Repera Pro",appearance=dev.repera.mobile.monetization.ProTeaserAppearance.RECOVERY,onClick={
                    subscriptions?.presentPaywall(dev.repera.domain.monetization.PaywallContext.PROGRESS,feature=dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS)
                })}
            }
            if(topic=="Actividad") {
            val realCharts=if(pro) overview?.chartsByRange?.get(selectedRange) else null
            val charts=when {
                !pro || PROGRESS_DEMO_CHARTS && (realCharts==null || realCharts.heartRate.isEmpty()) ->
                    ProgressPreview.charts(today,monday)
                else -> realCharts
            }
            item {
                Column(verticalArrangement=Arrangement.spacedBy(12.dp)) {
                if(!pro || PROGRESS_DEMO_CHARTS) Text("Ejemplo · FC y calorías ficticias, no son tus datos de Salud")
                val prepared=charts ?: ProgressPreview.charts(today,monday)
                val scorePoints=overview?.sessionScoresByRange?.get(selectedRange).orEmpty()
                val scoreDemo=scorePoints.size<2
                ProgressHealthGrid(
                    score={
                        SessionScoreProgressCard(
                            if (pro && !scoreDemo) scorePoints else ProgressPreview.sessionScores(today),
                            preview = !pro || scoreDemo,
                            range = ProgressTimeRange.entries.first { it.wire == selectedRange },
                            monday = prepared.weekStartsOnMonday
                        )
                    },
                    cardio={ProgressCardioCard(prepared,!pro || PROGRESS_DEMO_CHARTS)},calories={ProgressCaloriesCard(prepared,!pro || PROGRESS_DEMO_CHARTS)},
                    weight={
                        if (!pro || (PROGRESS_DEMO_CHARTS && snapshot.weightPoints.isEmpty()))
                            WeightPreviewCard(today)
                        else ProgressWeightCard(snapshot.weightPoints,snapshot.weightDelta30d,overview?.healthGoals?.weightKg,accountId,busy,onLogBodyWeight)
                    })
                // I-124 placeholder: sin motor de zonas HR en domain todavía.
                ReperaCard(
                    modifier = Modifier.fillMaxWidth().testTag("heart_zones_card")
                ) {
                    Column(
                        Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text("Zonas cardiacas", style = MaterialTheme.typography.titleMedium)
                        Text(
                            "Sin datos de zonas todavía. Cuando Health Connect aporte FC por zona, aparecerán aquí (Z1–Z5).",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                }
            }
            val healthPrompt=if(pro) ProgressHealthPrompt.kind(healthAccess,charts) else ProgressHealthPromptKind.NONE
            if(healthPrompt!=ProgressHealthPromptKind.NONE) item {
                ReperaCard(modifier = Modifier.fillMaxWidth()) {Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
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
                item { ReperaSectionTitle("ACTIVIDAD") }
                item { ActivityHeatmapCard(snapshot.heatmapTime,
                    snapshot.heatmapVolume,
                    dev.repera.domain.ProgressTimeRange.entries.first { it.wire == selectedRange }) }
            }
            // Apple order (StatsView training): tiles, activity, muscle balance, mobility, then
            // exercises/records or the Free preview + teaser. The card has its own empty text,
            // so it is not hidden when there are no muscle statuses (Apple does not hide it).
            item { ReperaSectionTitle("EQUILIBRIO MUSCULAR") }
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
            if(snapshot.mobilitySessions>0) {
                item { ReperaSectionTitle("Movilidad") }
                item {ProgressMobilityCard(snapshot.mobilitySessions,snapshot.mobilitySeconds,
                if(subscriptions==null || subscriptions.isPro) snapshot.chartExercises.filter {it.isMobility}.take(3) else emptyList(),onOpenExercise)}
            }
            if(subscriptions==null || subscriptions.isPro) {
                item { ReperaSectionTitle("Progreso por ejercicio") }
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
        if (topic == "Entreno") {
        // Resultados recientes; Historial al final (última opción de Entreno).
        if (recent.isNotEmpty()) {
            item { ReperaSectionTitle("Resultados recientes") }
            items(recent, key = { "progress:" + it.id }) { workout ->
                ReperaCard(
                    onClick = { onOpenWorkoutDetail(workout.id) },
                    modifier = Modifier.fillMaxWidth().testTag("progress_recent_${workout.id}")
                ) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(workout.title, style = MaterialTheme.typography.titleMedium)
                        if (workout.startedAt.isNotBlank()) {
                            Text(
                                workout.startedAt,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        } else {
            item {
                ReperaEmptyState(
                    title = "Todavía no hay entrenamientos para analizar",
                    subtitle = "Completa sesiones para ver resumen y tendencias"
                )
            }
        }
        item {
            ReperaCard(
                onClick = { if (overview != null) onOpenHistory() },
                modifier = Modifier.fillMaxWidth().testTag("progress_history_link")
            ) {
                Row(
                    Modifier.padding(16.dp).fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Outlined.Schedule,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text("Historial", style = MaterialTheme.typography.titleMedium)
                    }
                    Icon(
                        Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        }
    }
    }
}


@Composable
private fun ProgressMetricsTilesGrid(snapshot: ProgressSnapshotData, pro: Boolean) {
    val tiles = ProgressTilesModel.tiles(
        snapshot.summary.sessionCount,
        snapshot.summary.totalMinutes,
        snapshot.previousSummary?.sessionCount,
        snapshot.previousSummary?.totalMinutes,
        snapshot.streak,
        snapshot.previousStreak,
        pro
    )
    val icons = listOf(
        Icons.Outlined.FitnessCenter,
        Icons.Outlined.Schedule,
        Icons.Outlined.LocalFireDepartment
    )
    val iconColors = listOf(
        brandGreen,
        Color(0xFF0A84FF),
        Color(0xFFFF9F0A)
    )
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val minItem = (96 * LocalDensity.current.fontScale).dp
        val cols = ((maxWidth + 8.dp) / (minItem + 8.dp)).toInt().coerceIn(1, tiles.size)
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            tiles.chunked(cols).forEachIndexed { rowIndex, rowTiles ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    rowTiles.forEachIndexed { colIndex, tile ->
                        val index = rowIndex * cols + colIndex
                        ReperaCard(modifier = Modifier.weight(1f)) {
                            Column(
                                Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 12.dp, horizontal = 8.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        icons.getOrElse(index) { Icons.Outlined.FitnessCenter },
                                        contentDescription = null,
                                        modifier = Modifier.size(14.dp),
                                        tint = iconColors.getOrElse(index) { brandGreen }
                                    )
                                    Text(
                                        tile.label,
                                        style = MaterialTheme.typography.labelMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        maxLines = 1
                                    )
                                }
                                Text(
                                    tile.value,
                                    style = MaterialTheme.typography.headlineMedium,
                                    maxLines = 1
                                )
                                val deltaText = progressTileDeltaText(tile.delta, tile.deltaUnit)
                                Text(
                                    deltaText,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = progressTileDeltaColor(tile.delta)
                                )
                            }
                        }
                    }
                    repeat(cols - rowTiles.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
    }
}

private fun progressTileDeltaText(delta: Int?, unit: String): String = when (delta) {
    null -> "—"
    else -> "${if (delta > 0) "+" else ""}${dev.repera.domain.ReperaNumberFormat.integer(delta)}$unit"
}

@Composable
private fun progressTileDeltaColor(delta: Int?): Color = when (delta) {
    null -> MaterialTheme.colorScheme.onSurfaceVariant
    0 -> MaterialTheme.colorScheme.onSurfaceVariant
    else -> if (delta > 0) brandGreen else Color(0xFFFFD60A)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProgressRangePickerSheet(
    selectedWire: String,
    isPro: Boolean,
    subscriptions: dev.repera.mobile.monetization.SubscriptionManager?,
    onDismiss: () -> Unit,
    onSelect: (String) -> Unit,
) {
    ReperaModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            ReperaPageHeader(
                title = "Periodo",
                trailing = {
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.Close,
                        contentDescription = "Cerrar",
                        onClick = onDismiss
                    )
                }
            )
            // Sin card envolvente (iOS StatsView): filas planas; verde solo en icono/check.
            Column(Modifier.fillMaxWidth()) {
                ProgressTimeRange.entries.forEachIndexed { index, range ->
                    if (index > 0) {
                        HorizontalDivider(
                            modifier = Modifier.padding(start = 50.dp),
                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
                        )
                    }
                    val allowed = subscriptions?.canSelectProgressRange(range)?.allowed ?: true
                    val selected = selectedWire == range.wire
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .clickable {
                                if (!allowed) {
                                    onDismiss()
                                    subscriptions?.presentPaywall(
                                        dev.repera.domain.monetization.PaywallContext.PROGRESS,
                                        feature = dev.repera.domain.monetization.ReperaFeature.PROGRESS_PERIOD_BEYOND_WEEK
                                    )
                                } else if (!selected) {
                                    onSelect(range.wire)
                                } else {
                                    onDismiss()
                                }
                            }
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Outlined.CalendarMonth,
                            contentDescription = null,
                            tint = if (selected) brandGreenReadable
                            else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(24.dp)
                        )
                        Text(
                            range.title,
                            modifier = Modifier
                                .weight(1f)
                                .padding(horizontal = 12.dp),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        if (dev.repera.domain.monetization.ReperaFeature.requiresPro(range) && !isPro) {
                            Text(
                                "Pro",
                                style = MaterialTheme.typography.labelMedium,
                                color = brandGreenReadable
                            )
                        } else if (selected) {
                            Icon(
                                Icons.Outlined.Check,
                                contentDescription = null,
                                tint = brandGreenReadable
                            )
                        }
                    }
                }
            }
        }
    }
}

/** Completa heatmap / músculos / ejercicios si faltan (solo revisión visual). */
private fun enrichSnapshotWithDemo(
    snap: ProgressSnapshotData,
    today: LocalDate
): ProgressSnapshotData {
    val heat = ProgressPreview.heatmap(today)
    val loads = ProgressPreview.muscleLoads()
    val fatigue = ProgressPreview.muscleFatigue()
    return snap.copy(
        heatmapTime = snap.heatmapTime.ifEmpty { heat },
        heatmapVolume = snap.heatmapVolume.ifEmpty { heat.map { it.first to ((it.second + 1) % 5) } },
        muscleLoadAll = if (snap.muscleLoadAll.isEmpty()) loads else snap.muscleLoadAll,
        muscleLoadHard = if (snap.muscleLoadHard.isEmpty()) loads.mapValues { it.value * 0.6 } else snap.muscleLoadHard,
        muscleFatigueAll = if (snap.muscleFatigueAll.isEmpty()) fatigue else snap.muscleFatigueAll,
        muscleFatigueHard = if (snap.muscleFatigueHard.isEmpty()) fatigue.mapValues { it.value * 0.7 } else snap.muscleFatigueHard,
        hasHardSets = snap.hasHardSets || true,
        chartExercises = snap.chartExercises.ifEmpty { ProgressPreview.chartExercises() },
        weightPoints = snap.weightPoints.ifEmpty { ProgressPreview.weight(today) },
        mobilitySessions = if (snap.mobilitySessions > 0) snap.mobilitySessions else 3,
        mobilitySeconds = if (snap.mobilitySeconds > 0) snap.mobilitySeconds else 45 * 60
    )
}

private fun enrichRecoveryWithDemo(base: RecoveryState, today: LocalDate): RecoveryState {
    val nights = base.nights.ifEmpty { ProgressPreview.recoveryNights(today) }
    val vitals = base.vitals.ifEmpty { ProgressPreview.recoveryVitals(today) }
    val trend = base.trend.ifEmpty { ProgressPreview.recoveryTrend(today) }
    return base.copy(
        readiness = base.readiness ?: ProgressPreview.recoveryReadiness(),
        sleepIndex = base.sleepIndex ?: 72,
        lastNightHours = base.lastNightHours ?: nights.lastOrNull()?.hours,
        recentAverageSleepHours = base.recentAverageSleepHours
            ?: nights.map { it.hours }.average().takeIf { nights.isNotEmpty() },
        nights = nights,
        vitals = vitals,
        trend = trend
    )
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
    ReperaCard(modifier = Modifier.fillMaxWidth()) {Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
        Text("Peso corporal · ejemplo",style=MaterialTheme.typography.titleMedium)
        Text("Datos ficticios. Objetivo de ejemplo: 74 kg")
        DayPointLineChart(points,goal=74.0,interactive=false,weightStyle=true,weightPreview=true)
        WeightStatTiles(points.lastOrNull()?.value,74.0)
    }}
}

@Composable internal fun ProgressWeightCard(points:List<dev.repera.domain.ProgressDayPoint>,delta30d:Double?,goalKg:Double?,accountId:String,busy:Boolean,onLogBodyWeight:(Double)->Unit) {
 if(points.isEmpty()) ReperaCard(modifier = Modifier.fillMaxWidth()) {Column(Modifier.padding(16.dp)) {
  Text("Peso corporal",style=MaterialTheme.typography.titleMedium)
  WeightStatTiles(null,goalKg)
  EmptyHealthChart("Sin mediciones en el periodo.",goalKg?.minus(2) ?: 60.0,goalKg?.plus(2) ?: 90.0,210.dp)
 }} else {
                    ReperaCard(modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp),
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
