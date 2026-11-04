package dev.repera.mobile

import androidx.compose.ui.res.stringResource
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
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.MonitorHeart
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
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
import kotlin.math.roundToInt
import dev.repera.domain.HeartRatePlotPoint
import dev.repera.domain.ProgressTimeRange
import dev.repera.mobile.monetization.LocalSubscriptions

/** Solo para capturas internas de revisión: nunca sustituir registros ausentes en producción. */
internal const val PROGRESS_DEMO_CHARTS = false


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
    val recent = overview?.history.orEmpty()
    val subscriptions = LocalSubscriptions.current
    var category by rememberSaveable { mutableStateOf(ProgressCategory.TRAINING.name) }
    val selectedCategory = ProgressCategory.entries.firstOrNull { it.name == category }
        ?: ProgressCategory.TRAINING
    LaunchedEffect(selectedCategory) {
        dev.repera.mobile.analytics.ReperaAnalytics.track(
            dev.repera.mobile.analytics.ReperaAnalytics.Event.PROGRESS_SECTION_VIEWED,
            mapOf("feature_area" to "progress", "section_name" to selectedCategory.name.lowercase())
        )
    }
    val pro = subscriptions?.isPro ?: false
    var selectedRange by rememberSaveable { mutableStateOf(ProgressTimeRange.WEEK.wire) }
    LaunchedEffect(pro) {
        selectedRange = if (pro) ProgressTimeRange.MONTH.wire else ProgressTimeRange.WEEK.wire
    }
    LaunchedEffect(selectedRange) {
        onProgressRangeChange(selectedRange)
        dev.repera.mobile.analytics.ReperaAnalytics.track(
            dev.repera.mobile.analytics.ReperaAnalytics.Event.PROGRESS_PERIOD_SELECTED,
            mapOf(
                "feature_area" to "progress",
                "section_name" to selectedRange,
                "result" to "success"
            )
        )
    }
    val hubSubtitle = when (selectedCategory) {
        ProgressCategory.HEART -> "Ahora"
        ProgressCategory.RECOVERY -> "Preparación"
        else -> if (pro) "Este mes" else "Últimos 7 días"
    }
    val rawSnapshot = overview?.progressByRange?.get(selectedRange)
    val today = LocalDate.now()
    val monday = overview?.trainingSettings?.weekStartsOnMonday ?: true
    val snapshot = remember(rawSnapshot, selectedRange, today, PROGRESS_DEMO_CHARTS) {
        if (!PROGRESS_DEMO_CHARTS || rawSnapshot == null) rawSnapshot
        else enrichSnapshotWithDemo(rawSnapshot, today)
    }
    val latestMeasuredWorkout = remember(overview, selectedRange, monday, today) {
        val selected = ProgressTimeRange.entries.firstOrNull { it.wire == selectedRange }
            ?: ProgressTimeRange.WEEK
        val history = overview?.completeHistory.orEmpty().ifEmpty { overview?.history.orEmpty() }
        history.filter { workout ->
            val day = workout.finishedAtIso?.let { iso ->
                runCatching {
                    java.time.Instant.parse(iso).atZone(java.time.ZoneId.systemDefault()).toLocalDate()
                }.getOrNull()
            }
            val hasPulse = workout.appleAverageHeartRateBpm?.let { it.isFinite() && it > 0 } == true
            val hasEnergy = workout.appleActiveEnergyKcal?.let { it.isFinite() && it > 0 } == true
            day != null && selected.contains(day, today, monday) && (hasPulse || hasEnergy)
        }.maxByOrNull { it.finishedAtIso.orEmpty() }
    }
    val demoBanner = PROGRESS_DEMO_CHARTS
    val dragListState = androidx.compose.foundation.lazy.rememberLazyListState()
    var shownCategory by remember { mutableStateOf(category) }
    LaunchedEffect(category) {
        if (category != shownCategory) {
            shownCategory = category
            dragListState.scrollToItem(0)
        }
    }
    val rangeEnum = ProgressTimeRange.entries.firstOrNull { it.wire == selectedRange } ?: ProgressTimeRange.WEEK
    // Series reales de HC (siempre en overview); las teasers gratis van aparte en preparedCharts.
    val realHeartCharts = overview?.chartsByRange?.get(selectedRange)
    val recentHeartPoint = realHeartCharts?.heartRate?.lastOrNull { it.avgBpm > 0 }
    val recentHeartBpm = recentHeartPoint?.avgBpm?.takeIf { it > 0 }?.roundToInt()
        ?: realHeartCharts?.averageHeartRate?.takeIf { it > 0 }?.roundToInt()
        ?: snapshot?.averageHeartRate?.takeIf { it > 0 }?.roundToInt()
    val recentHeartMin = recentHeartPoint?.minBpm?.takeIf { it > 0 }?.roundToInt()
    val recentHeartMax = recentHeartPoint?.maxBpm?.takeIf { it > 0 }?.roundToInt()
    val heartSparkFractions = heartDailyBarFractions(realHeartCharts?.heartRate.orEmpty())
    val preparedCharts = remember(overview, selectedRange, pro, today, monday) {
        val realCharts = if (pro) overview?.chartsByRange?.get(selectedRange) else null
        when {
            !pro || (PROGRESS_DEMO_CHARTS && (realCharts == null || realCharts.heartRate.isEmpty())) ->
                ProgressPreview.charts(today, monday)
            else -> realCharts ?: dev.repera.domain.ProgressChartBuilder.build(
                range = rangeEnum,
                weekStartsOnMonday = monday,
                heartRateDays = emptyList(),
                energyDays = emptyList(),
                workouts = emptyList(),
                external = emptyList(),
                now = today
            )
        }
    }
    ProvideLazyDragAutoScroll(dragListState) {
    LazyColumn(
        state = dragListState,
        modifier = modifier.fillMaxSize().then(Modifier.testTag("progress_list")),
        contentPadding = reperaScrollContentPadding(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { ReperaPageHeader(title = stringResource(R.string.tab_progress), subtitle = hubSubtitle) }
        if (demoBanner) {
            item {
                Text(
                    stringResource(R.string.progress_tab_datos_de_ejemplo_en_graficas_vacias),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        stickyHeader {
            // Fondo transparente: sin franja opaca ni línea gris al anclar.
            Box(Modifier.fillMaxWidth()) {
                ProgressCategoryChipBar(
                    selected = selectedCategory,
                    glanceValue = { cat ->
                        when (cat) {
                            ProgressCategory.TRAINING ->
                                overview?.sessionScoresByRange?.get(selectedRange)
                                    ?.lastOrNull()?.value?.toInt()?.let { "$it" }
                                    ?: snapshot?.summary?.sessionCount?.takeIf { it > 0 }?.toString()
                                    ?: "—"
                            ProgressCategory.STRENGTH ->
                                snapshot?.records?.size?.takeIf { it > 0 }?.let { "$it PR" } ?: "—"
                            ProgressCategory.FITNESS ->
                                snapshot?.summary?.totalMinutes?.toInt()?.takeIf { it > 0 }
                                    ?.let { compactActiveDuration(it) } ?: "—"
                            ProgressCategory.HEART ->
                                recentHeartBpm?.toString() ?: "—"
                            ProgressCategory.RECOVERY ->
                                overview?.recovery?.readiness?.score
                                    ?.takeIf { it > 0 }
                                    ?.let { "${it.toInt()}" } ?: "—"
                            ProgressCategory.SPORTS -> {
                                val zone = java.time.ZoneId.systemDefault()
                                val sports = overview?.liveSportSessions.orEmpty().count { session ->
                                    val millis = session.finishedEpochMillis ?: session.startedEpochMillis
                                        ?: return@count false
                                    val day = java.time.Instant.ofEpochMilli(millis)
                                        .atZone(zone).toLocalDate()
                                    rangeEnum.contains(day, today, monday)
                                }
                                if (sports > 0) "$sports" else "—"
                            }
                        }
                    },
                    onSelected = { category = it.name },
                    modifier = Modifier.padding(bottom = 4.dp)
                )
            }
        }

        when (selectedCategory) {
            ProgressCategory.TRAINING -> {
                if (snapshot != null) {
                    item {
                        AdaptiveCardPair(
                            first = {
                                SessionScoreProgressCard(
                                    points = if (pro) overview?.sessionScoresByRange?.get(selectedRange).orEmpty()
                                    else ProgressPreview.sessionScores(today),
                                    preview = !pro,
                                    range = rangeEnum,
                                    monday = monday,
                                    confidenceLabel = if (pro) overview?.sessionScoreConfidenceByRange?.get(selectedRange) else null
                                )
                            },
                            second = {
                                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    ReperaSectionTitle("Equilibrio muscular")
                                    MuscleBalanceCard(
                                        loadAll = snapshot.muscleLoadAll,
                                        loadHard = snapshot.muscleLoadHard,
                                        fatigueAll = snapshot.muscleFatigueAll,
                                        fatigueHard = snapshot.muscleFatigueHard,
                                        hasHardSets = snapshot.hasHardSets,
                                        includesEstimatedWodMuscles = snapshot.includesEstimatedWodMuscles
                                    )
                                }
                            }
                        )
                    }
                    item {
                        val avg = overview?.sessionScoresByRange?.get(selectedRange)
                            ?.map { it.value }
                            ?.takeIf { it.isNotEmpty() }
                            ?.let { values ->
                                String.format(java.util.Locale("es", "ES"), "%.1f", values.average())
                            } ?: "—"
                        ProgressTrainingGlanceGrid(snapshot, pro, averageText = avg)
                    }
                    item { ProgressWeekConsistencyCard(today = today, overview = overview) }
                    if (snapshot.mobilitySessions > 0) {
                        item { ReperaSectionTitle("Movilidad") }
                        item {
                            ProgressMobilityCard(
                                snapshot.mobilitySessions,
                                snapshot.mobilitySeconds,
                                if (subscriptions?.isPro == true) {
                                    snapshot.chartExercises.filter { it.isMobility }.take(3)
                                } else emptyList(),
                                onOpenExercise
                            )
                        }
                    }
                    if (pro) {
                        item { ReperaSectionTitle("A largo plazo") }
                        item {
                            ProgressLongTermConsistencyCard(
                                sessionCount = snapshot.summary.sessionCount,
                                totalMinutes = snapshot.summary.totalMinutes.toInt(),
                                today = today,
                                overview = overview
                            )
                        }
                    } else {
                        item {
                            dev.repera.mobile.monetization.ProTeaserCard(
                                title = stringResource(R.string.progress_tab_tendencias_a_largo_plazo),
                                bodyText = "Con Pro ves consistencia de semanas y evolución de puntuación sin límites.",
                                cta = "Descubrir Repera Pro",
                                appearance = dev.repera.mobile.monetization.ProTeaserAppearance.PROGRESS,
                                onClick = {
                                    subscriptions?.presentPaywall(
                                        dev.repera.domain.monetization.PaywallContext.PROGRESS,
                                        feature = dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS
                                    )
                                }
                            )
                        }
                    }
                }
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
                                    Text(workout.startedAt, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                }
                item {
                    ReperaCard(
                        onClick = { if (overview != null) onOpenHistory() },
                        modifier = Modifier.fillMaxWidth().testTag("progress_history_link")
                    ) {
                        Row(Modifier.padding(16.dp).fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Outlined.Schedule, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                                Text(stringResource(R.string.progress_tab_historial), style = MaterialTheme.typography.titleMedium)
                            }
                            Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
            ProgressCategory.STRENGTH -> {
                if (snapshot != null) {
                    item { ReperaSectionTitle("Fuerza") }
                    item {
                        ProgressSaludInsightCard(
                            title = stringResource(R.string.progress_tab_carga_y_marcas),
                            icon = Icons.Outlined.FitnessCenter,
                            tint = ProgressCategory.STRENGTH.accent,
                            narrative = strengthInsightCopy(
                                prCount = snapshot.records.size,
                                volumeKg = snapshot.summary.volumeKg.toInt()
                            ),
                            heroValue = if (snapshot.records.isEmpty()) "—" else "${snapshot.records.size}",
                            heroUnit = if (snapshot.records.isEmpty()) null else "PR",
                            heroCaption = when {
                                snapshot.summary.volumeKg > 0 ->
                                    "${snapshot.summary.volumeKg.toInt()} kg de carga"
                                snapshot.records.isEmpty() -> "sin marcas aún"
                                else -> "en el periodo"
                            }
                        )
                    }
                    item {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            ProgressMetricGlanceCard(
                                title = stringResource(R.string.progress_tab_sesiones),
                                value = "${snapshot.summary.sessionCount}",
                                modifier = Modifier.weight(1f),
                                tint = ProgressCategory.STRENGTH.accent
                            )
                            ProgressMetricGlanceCard(
                                title = stringResource(R.string.tab_exercises),
                                value = if (snapshot.chartExercises.isEmpty()) "—" else "${snapshot.chartExercises.size}",
                                modifier = Modifier.weight(1f),
                                tint = ProgressCategory.STRENGTH.accent
                            )
                        }
                    }
                    if (subscriptions?.isPro == true) {
                        item {
                            AdaptiveCardPair(
                                first = { ProgressExercisesCard(snapshot.chartExercises, onOpenExercise) },
                                second = { ProgressRecordsCard(snapshot.records, onOpenExercise) }
                            )
                        }
                    } else {
                        item { ProgressExerciseTrendPreview(today) }
                        item {
                            dev.repera.mobile.monetization.ProTeaserCard(
                                title = stringResource(R.string.progress_tab_evolucion_de_fuerza),
                                bodyText = "Sigue e1RM y progreso por ejercicio con Repera Pro.",
                                cta = "Descubrir Repera Pro",
                                appearance = dev.repera.mobile.monetization.ProTeaserAppearance.PROGRESS,
                                onClick = {
                                    subscriptions?.presentPaywall(
                                        dev.repera.domain.monetization.PaywallContext.PROGRESS,
                                        feature = dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS
                                    )
                                }
                            )
                        }
                    }
                }
            }
            ProgressCategory.FITNESS -> {
                item { ReperaSectionTitle("Forma física") }
                item {
                    val minutes = snapshot?.summary?.totalMinutes?.toInt() ?: 0
                    val hero = activeDurationHero(minutes)
                    val period = if (pro) "este mes" else "últimos 7 días"
                    ProgressSaludInsightCard(
                        title = stringResource(R.string.progress_tab_estimulo_activo),
                        icon = Icons.Outlined.DirectionsWalk,
                        tint = ProgressCategory.FITNESS.accent,
                        narrative = activeDurationNarrative(minutes, period),
                        heroValue = hero.first,
                        heroUnit = hero.second,
                        heroCaption = "$period · Repera + Salud"
                    )
                }
                if (snapshot != null && snapshot.heatmapTime.isNotEmpty()) {
                    item { ReperaSectionTitle("Días activos") }
                    item { ActivityHeatmapCard(snapshot.heatmapTime, snapshot.heatmapVolume, rangeEnum) }
                }
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        ProgressCaloriesCard(preparedCharts, !pro || PROGRESS_DEMO_CHARTS)
                        if (!pro || (PROGRESS_DEMO_CHARTS && (snapshot?.weightPoints?.size ?: 0) < 2)) {
                            WeightPreviewCard(today, loggedPoints = snapshot?.weightPoints.orEmpty(), accountId = accountId, busy = busy, onLogBodyWeight = onLogBodyWeight)
                        } else if (snapshot != null) {
                            ProgressWeightCard(snapshot.weightPoints, snapshot.weightDelta30d, overview?.healthGoals?.weightKg, accountId, busy, onLogBodyWeight)
                        }
                    }
                }
                if (!pro) {
                    item {
                        dev.repera.mobile.monetization.ProTeaserCard(
                            title = stringResource(R.string.progress_tab_forma_fisica_completa),
                            bodyText = "Calorías, peso y tendencias largas con Repera Pro.",
                            cta = "Descubrir Repera Pro",
                            appearance = dev.repera.mobile.monetization.ProTeaserAppearance.ACTIVITY,
                            onClick = {
                                subscriptions?.presentPaywall(
                                    dev.repera.domain.monetization.PaywallContext.PROGRESS,
                                    feature = dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS
                                )
                            }
                        )
                    }
                }
                item {
                    val monthSnap = overview?.progressByRange?.get(ProgressTimeRange.MONTH.wire)
                    val monthMins = monthSnap?.summary?.totalMinutes?.toInt() ?: 0
                    val monthSessions = monthSnap?.summary?.sessionCount ?: 0
                    ProgressMonthSummaryCard(
                        title = "Actividad del mes",
                        icon = Icons.Outlined.DirectionsWalk,
                        tint = ProgressCategory.FITNESS.accent,
                        narrative = if (monthMins > 0) {
                            "En lo que va de mes has acumulado ${compactActiveDuration(monthMins)} · $monthSessions sesiones."
                        } else {
                            "Cuando registres actividad este mes, verás aquí el resumen."
                        },
                        heroValue = if (monthMins > 0) compactActiveDuration(monthMins) else "—",
                        heroCaption = "$monthSessions sesiones"
                    )
                }
            }
            ProgressCategory.HEART -> {
                item { ReperaSectionTitle("Corazón") }
                item {
                    ProgressSaludInsightCard(
                        title = stringResource(R.string.progress_tab_frecuencia_cardiaca),
                        icon = Icons.Outlined.MonitorHeart,
                        tint = ProgressCategory.HEART.accent,
                        narrative = when {
                            recentHeartBpm != null ->
                                "Datos de Health Connect: tu frecuencia cardíaca media reciente es de $recentHeartBpm LPM."
                            else ->
                                "Conecta Health Connect o entrena con pulsómetro para ver tu ritmo cardíaco real aquí. Sin muestras no se inventan barras."
                        },
                        heroValue = recentHeartBpm?.toString() ?: "—",
                        heroUnit = if (recentHeartBpm != null) "LPM" else null,
                        heroCaption = if (recentHeartBpm != null) "media reciente" else null,
                        barFractions = heartSparkFractions
                    )
                }
                if (recentHeartMin != null || recentHeartMax != null) {
                    item {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            ProgressMetricGlanceCard(
                                title = "Mín. reciente",
                                value = recentHeartMin?.toString() ?: "—",
                                modifier = Modifier.weight(1f),
                                tint = ProgressCategory.HEART.accent
                            )
                            ProgressMetricGlanceCard(
                                title = "Máx. reciente",
                                value = recentHeartMax?.toString() ?: "—",
                                modifier = Modifier.weight(1f),
                                tint = ProgressCategory.HEART.accent
                            )
                        }
                    }
                }
                if (latestMeasuredWorkout != null) item { TrainingMeasuredEffortCard(latestMeasuredWorkout) }
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        ProgressCardioCard(preparedCharts, !pro || PROGRESS_DEMO_CHARTS)
                        if (PROGRESS_DEMO_CHARTS) {
                            ReperaSectionTitle("Zonas cardíacas · ejemplo")
                            HeartZonesDemoCard()
                        }
                    }
                }
                val healthPrompt = if (pro) ProgressHealthPrompt.kind(healthAccess, preparedCharts) else ProgressHealthPromptKind.NONE
                if (healthPrompt != ProgressHealthPromptKind.NONE) {
                    item {
                        ReperaCard(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                if (healthPrompt == ProgressHealthPromptKind.NOT_AUTHORIZED) {
                                    Text(stringResource(R.string.progress_tab_salud_sin_permiso_de_lectura), style = MaterialTheme.typography.titleMedium)
                                    Text(stringResource(R.string.progress_tab_autoriza_health_connect_para_ver_fc))
                                    TextButton(onClick = onHealthConnect) { Text(stringResource(R.string.progress_tab_autorizar_salud)) }
                                } else {
                                    Text(stringResource(R.string.progress_tab_health_connect_no_disponible), style = MaterialTheme.typography.titleMedium)
                                    Text(stringResource(R.string.progress_tab_este_dispositivo_no_tiene_health_connect))
                                }
                            }
                        }
                    }
                }
                if (!pro) {
                    item {
                        dev.repera.mobile.monetization.ProTeaserCard(
                            title = stringResource(R.string.progress_tab_corazon_en_detalle),
                            bodyText = "Consulta FC diaria y tendencias con Repera Pro.",
                            cta = "Descubrir Repera Pro",
                            appearance = dev.repera.mobile.monetization.ProTeaserAppearance.ACTIVITY,
                            onClick = {
                                subscriptions?.presentPaywall(
                                    dev.repera.domain.monetization.PaywallContext.PROGRESS,
                                    feature = dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS
                                )
                            }
                        )
                    }
                }
                item {
                    val bpm = overview?.chartsByRange?.get(ProgressTimeRange.MONTH.wire)
                        ?.averageHeartRate?.takeIf { it > 0 }?.roundToInt()
                        ?: overview?.progressByRange?.get(ProgressTimeRange.MONTH.wire)
                            ?.averageHeartRate?.takeIf { it > 0 }?.roundToInt()
                    ProgressMonthSummaryCard(
                        title = "FC media del mes",
                        icon = Icons.Outlined.MonitorHeart,
                        tint = ProgressCategory.HEART.accent,
                        narrative = bpm?.let {
                            "Tu frecuencia cardíaca media este mes ha sido de $it LPM según Health Connect."
                        } ?: "Con más lecturas de pulso este mes verás aquí la media.",
                        heroValue = bpm?.toString() ?: "—",
                        heroCaption = "media del mes",
                        heroUnit = if (bpm != null) "LPM" else null
                    )
                }
            }
            ProgressCategory.RECOVERY -> {
                val baseRecovery = overview?.recovery ?: RecoveryState(null, null, null, null)
                val recovery = if (PROGRESS_DEMO_CHARTS) enrichRecoveryWithDemo(baseRecovery, today) else baseRecovery
                item {
                    RecoveryHistoryCards(recovery, rangeEnum, monday, pro || PROGRESS_DEMO_CHARTS, outerHorizontalPaddingDp = 32f)
                }
                if (!pro) {
                    item {
                        dev.repera.mobile.monetization.ProTeaserCard(
                            title = stringResource(R.string.progress_tab_recuperacion_completa),
                            bodyText = "Consulta cómo evolucionan tu descanso y tu preparación para entrenar.",
                            cta = "Descubrir Repera Pro",
                            appearance = dev.repera.mobile.monetization.ProTeaserAppearance.RECOVERY,
                            onClick = {
                                subscriptions?.presentPaywall(
                                    dev.repera.domain.monetization.PaywallContext.PROGRESS,
                                    feature = dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS
                                )
                            }
                        )
                    }
                }
                item {
                    val monthNights = recovery.nights.filter {
                        ProgressTimeRange.MONTH.contains(it.day, today, monday)
                    }
                    val avgHours = monthNights.takeIf { it.isNotEmpty() }?.map { it.hours }?.average()
                    val nights = monthNights.size
                    ProgressMonthSummaryCard(
                        title = "Descanso del mes",
                        icon = Icons.Outlined.DarkMode,
                        tint = ProgressCategory.RECOVERY.accent,
                        narrative = if (nights > 0 && avgHours != null) {
                            "Has registrado $nights noche${if (nights == 1) "" else "s"} de sueño este mes · media ${String.format(java.util.Locale("es", "ES"), "%.1f", avgHours)} h."
                        } else {
                            "Cuando Salud registre sueño este mes, verás aquí el resumen de descanso."
                        },
                        heroValue = avgHours?.let {
                            String.format(java.util.Locale("es", "ES"), "%.1f", it)
                        } ?: "—",
                        heroCaption = if (nights > 0) "$nights noches" else "sin noches aún",
                        heroUnit = if (avgHours != null) "h" else null
                    )
                }
            }
            ProgressCategory.SPORTS -> {
                val period = if (pro) "este mes" else "últimos 7 días"
                val zone = java.time.ZoneId.systemDefault()
                fun liveSessionDay(session: dev.repera.domain.LiveSportHistory.LiveSession): LocalDate? {
                    val millis = session.finishedEpochMillis ?: session.startedEpochMillis ?: return null
                    return java.time.Instant.ofEpochMilli(millis).atZone(zone).toLocalDate()
                }
                val allSportSessions = overview?.liveSportSessions.orEmpty()
                val sportSessions = allSportSessions.filter { session ->
                    val day = liveSessionDay(session) ?: return@filter false
                    rangeEnum.contains(day, today, monday)
                }
                val monthSportSessions = allSportSessions.filter { session ->
                    val day = liveSessionDay(session) ?: return@filter false
                    ProgressTimeRange.MONTH.contains(day, today, monday)
                }
                val sportCount = sportSessions.size
                val sportMins = sportSessions.sumOf {
                    ((it.activeDurationSeconds ?: 0.0) / 60.0).coerceAtLeast(0.0)
                }.toInt()
                val monthSportCount = monthSportSessions.size
                val monthSportMins = monthSportSessions.sumOf {
                    ((it.activeDurationSeconds ?: 0.0) / 60.0).coerceAtLeast(0.0)
                }.toInt()
                val planned = overview?.history.orEmpty().count { entry ->
                    !entry.routineId.isNullOrBlank() && entry.finishedAtIso?.let { iso ->
                        runCatching {
                            java.time.Instant.parse(iso).atZone(zone).toLocalDate()
                        }.getOrNull()?.let { rangeEnum.contains(it, today, monday) } == true
                    } == true
                }
                val improved = overview?.exerciseProgress?.values?.count { summary ->
                    summary.timesPerformed >= 2 && (summary.estimatedOneRM ?: 0.0) > 0
                } ?: 0
                val sportDayFractions = sportsDailyBarFractions(sportSessions)
                val progressFractions = exerciseProgressBarFractions(overview?.exerciseProgress.orEmpty())
                item { ReperaSectionTitle("Deportes") }
                item {
                    ProgressSaludInsightCard(
                        title = "Actividad deportiva",
                        icon = Icons.Outlined.Flag,
                        tint = ProgressCategory.SPORTS.accent,
                        narrative = sportsHubNarrative(sportCount, improved, planned, period),
                        heroValue = if (sportCount > 0) "$sportCount" else "—",
                        heroUnit = if (sportCount > 0) "salidas" else null,
                        heroCaption = if (sportCount > 0) {
                            "${compactActiveDuration(sportMins)} · $period"
                        } else {
                            "sin salidas En vivo en $period"
                        }
                    )
                }
                item {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        ProgressMetricGlanceCard(
                            title = "Ejercicios activos",
                            value = if (improved > 0) "$improved" else "—",
                            modifier = Modifier.weight(1f),
                            tint = ProgressCategory.SPORTS.accent
                        )
                        ProgressMetricGlanceCard(
                            title = "Del plan",
                            value = if (planned > 0) "$planned" else "—",
                            modifier = Modifier.weight(1f),
                            tint = ProgressCategory.SPORTS.accent
                        )
                    }
                }
                item {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        ProgressMetricGlanceCard(
                            title = "Tiempo En vivo",
                            value = compactActiveDuration(sportMins),
                            modifier = Modifier.weight(1f),
                            tint = ProgressCategory.SPORTS.accent
                        )
                        ProgressMetricGlanceCard(
                            title = "Periodo",
                            value = if (pro) "Mes" else "7 días",
                            modifier = Modifier.weight(1f),
                            tint = ProgressCategory.SPORTS.accent
                        )
                    }
                }
                item {
                    ReperaCard(onClick = onOpenSports, modifier = Modifier.fillMaxWidth().testTag("progress_sports_link")) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Outlined.Flag, null, tint = ProgressCategory.SPORTS.accent)
                                    Text(stringResource(R.string.progress_tab_evolucion_y_records), style = MaterialTheme.typography.titleSmall, color = ProgressCategory.SPORTS.accent)
                                }
                                Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            Text(
                                if (sportCount == 0) {
                                    "Aún no hay salidas En vivo en $period."
                                } else {
                                    "Minutos En vivo por día en $period. Toca para distancias, ritmos y marcas."
                                },
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            if (sportDayFractions.isNotEmpty()) {
                                ProgressMiniBarRow(sportDayFractions, ProgressCategory.SPORTS.accent)
                            }
                        }
                    }
                }
                if (improved > 0) {
                    item {
                        ReperaCard(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Outlined.FitnessCenter, null, tint = ProgressCategory.STRENGTH.accent)
                                    Text(
                                        "Progresión en ejercicios",
                                        style = MaterialTheme.typography.titleSmall,
                                        color = ProgressCategory.STRENGTH.accent
                                    )
                                }
                                Text(
                                    "$improved ejercicios con historial de fuerza. Barras relativas de e1RM.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                if (progressFractions.isNotEmpty()) {
                                    ProgressMiniBarRow(progressFractions, ProgressCategory.STRENGTH.accent)
                                }
                            }
                        }
                    }
                }
                item {
                    ProgressMonthSummaryCard(
                        title = "Salidas del mes",
                        icon = Icons.Outlined.Flag,
                        tint = ProgressCategory.SPORTS.accent,
                        narrative = if (monthSportCount == 0) {
                            "Las salidas En vivo de este mes aparecerán aquí."
                        } else {
                            "$monthSportCount salidas En vivo este mes · ${compactActiveDuration(monthSportMins)}."
                        },
                        heroValue = if (monthSportCount > 0) "$monthSportCount" else "—",
                        heroCaption = compactActiveDuration(monthSportMins),
                        heroUnit = if (monthSportCount > 0) "salidas" else null
                    )
                }
            }
        }
    }
    }
}

private fun strengthInsightCopy(prCount: Int, volumeKg: Int): String {
    if (prCount == 0 && volumeKg == 0) {
        return "Cuando registres series de fuerza, verás aquí la carga (volumen) y tus marcas (PR / e1RM)."
    }
    val parts = buildList {
        if (volumeKg > 0) add("Has movido $volumeKg kg en el periodo")
        if (prCount > 0) add("$prCount marca${if (prCount == 1) "" else "s"} personal${if (prCount == 1) "" else "es"}")
    }
    return parts.joinToString(" · ") + "."
}

private fun compactActiveDuration(minutes: Int): String {
    if (minutes <= 0) return "—"
    if (minutes < 60) return "${minutes}′"
    val h = minutes / 60
    val m = minutes % 60
    return if (m == 0) "$h h" else "$h h $m"
}

private fun activeDurationHero(minutes: Int): Pair<String, String?> {
    if (minutes <= 0) return "—" to null
    if (minutes < 60) return "$minutes" to "min"
    val h = minutes / 60
    val m = minutes % 60
    return if (m == 0) "$h" to "h" else "$h h $m" to "min"
}

private fun activeDurationNarrative(minutes: Int, period: String): String {
    if (minutes <= 0) {
        return "Cuando camines o entrenes, verás aquí tu estímulo y el mapa de días activos."
    }
    val label = compactActiveDuration(minutes)
    return "$label en $period: entrenos Repera + actividades de Health Connect (paseos incluidos)."
}

private fun sportsHubNarrative(sportCount: Int, improved: Int, planned: Int, period: String): String {
    if (sportCount == 0 && improved == 0 && planned == 0) {
        return "Aquí verás salidas En vivo, entrenos del plan y ejercicios que mejoran en $period."
    }
    val parts = buildList {
        if (sportCount > 0) add("$sportCount salida${if (sportCount == 1) "" else "s"} En vivo")
        if (planned > 0) add("$planned del plan")
        if (improved > 0) add("$improved ejercicio${if (improved == 1) "" else "s"} con historial")
    }
    return parts.joinToString(" · ") + " · $period."
}

/** Barras relativas de FC media diaria (Health Connect). Vacío si no hay muestras. */
private fun heartDailyBarFractions(points: List<HeartRatePlotPoint>): List<Float> {
    val sample = points.takeLast(14).filter { it.avgBpm > 0 && it.maxBpm > 0 }
    if (sample.isEmpty()) return emptyList()
    val maxB = sample.maxOf { it.maxBpm }
    val minB = sample.minOf { it.minBpm }
    val span = (maxB - minB).coerceAtLeast(1.0)
    return sample.map { point ->
        val lo = ((point.minBpm - minB) / span).toFloat()
        val hi = ((point.maxBpm - minB) / span).toFloat()
        // Altura ≈ rango diario normalizado (mín–máx), sin inventar valores.
        (hi - lo).coerceIn(0.12f, 1f)
    }
}

private fun sportsDailyBarFractions(
    sessions: List<dev.repera.domain.LiveSportHistory.LiveSession>
): List<Float> {
    val byDay = linkedMapOf<Long, Double>()
    for (session in sessions) {
        val day = ((session.startedEpochMillis ?: session.finishedEpochMillis ?: continue) / 86_400_000L)
        val mins = ((session.activeDurationSeconds ?: 0.0) / 60.0).coerceAtLeast(0.0)
        if (mins <= 0) continue
        byDay[day] = (byDay[day] ?: 0.0) + mins
    }
    val ordered = byDay.entries.sortedBy { it.key }.takeLast(14)
    val peak = ordered.maxOfOrNull { it.value }?.takeIf { it > 0 } ?: return emptyList()
    return ordered.map { (it.value / peak).toFloat().coerceIn(0.12f, 1f) }
}

private fun exerciseProgressBarFractions(
    progress: Map<String, ExerciseProgressSummary>
): List<Float> {
    val values = progress.values.mapNotNull { it.estimatedOneRM?.takeIf { v -> v > 0 } }
        .sortedDescending()
        .take(8)
    val peak = values.maxOrNull() ?: return emptyList()
    return values.map { (it / peak).toFloat().coerceIn(0.12f, 1f) }
}

@Composable
private fun ProgressMiniBarRow(
    fractions: List<Float>,
    tint: Color,
    modifier: Modifier = Modifier
        .fillMaxWidth()
        .height(56.dp)
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(3.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        fractions.forEach { fraction ->
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight(fraction.coerceIn(0.08f, 1f))
                    .clip(RoundedCornerShape(50))
                    .background(tint.copy(alpha = 0.85f))
            )
        }
    }
}


@Composable
private fun ProgressTrainingGlanceGrid(
    snapshot: ProgressSnapshotData,
    pro: Boolean,
    averageText: String
) {
    val minutes = snapshot.summary.totalMinutes.toInt()
    val timeText = if (minutes >= 60) {
        val h = minutes / 60
        val m = minutes % 60
        if (m == 0) "${h} h" else "${h} h $m"
    } else {
        "${minutes}′"
    }
    val streak = if (snapshot.streak > 0) "${snapshot.streak} sem" else "—"
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ProgressMetricGlanceCard(
                title = if (pro) "Media mes" else "Media 7 días",
                value = averageText,
                modifier = Modifier.weight(1f)
            )
            ProgressMetricGlanceCard(title = stringResource(R.string.progress_tab_racha), value = streak, modifier = Modifier.weight(1f))
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ProgressMetricGlanceCard(
                title = stringResource(R.string.progress_tab_entrenos),
                value = "${snapshot.summary.sessionCount}",
                modifier = Modifier.weight(1f)
            )
            ProgressMetricGlanceCard(title = stringResource(R.string.home_day_cards_tiempo), value = timeText, modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun ProgressMetricGlanceCard(
    title: String,
    value: String,
    modifier: Modifier = Modifier,
    tint: Color = brandGreen
) {
    ReperaCard(modifier = modifier.fillMaxWidth()) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, style = MaterialTheme.typography.labelLarge, color = tint, maxLines = 1)
            Text(
                value,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                maxLines = 1
            )
        }
    }
}

@Composable
private fun ProgressMonthSummaryCard(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    tint: Color,
    narrative: String,
    heroValue: String,
    heroCaption: String?,
    heroUnit: String? = null
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Este mes")
        ProgressSaludInsightCard(
            title = title,
            icon = icon,
            tint = tint,
            narrative = narrative,
            heroValue = heroValue,
            heroUnit = heroUnit,
            heroCaption = heroCaption
        )
    }
}

@Composable
private fun ProgressSaludInsightCard(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    tint: Color,
    narrative: String,
    heroValue: String,
    heroUnit: String?,
    heroCaption: String?,
    barFractions: List<Float> = emptyList()
) {
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, contentDescription = null, tint = tint)
                Text(title, style = MaterialTheme.typography.titleMedium, color = tint, fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold)
            }
            Text(narrative, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text(
                            heroValue,
                            style = MaterialTheme.typography.displaySmall,
                            fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                        )
                        if (heroUnit != null) {
                            Text(
                                " $heroUnit",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(bottom = 6.dp)
                            )
                        }
                    }
                    if (heroCaption != null) {
                        Text(heroCaption, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                if (barFractions.isNotEmpty()) {
                    ProgressMiniBarRow(
                        fractions = barFractions,
                        tint = tint,
                        modifier = Modifier
                            .width(120.dp)
                            .height(64.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun ProgressWeekConsistencyCard(
    today: LocalDate,
    overview: StateOverview?
) {
    val trained = trainedDays(overview, today.minusDays(6), today)
    val days = (0..6).map { offset ->
        val day = today.minusDays((6 - offset).toLong())
        day to trained.contains(day)
    }
    val count = days.count { it.second }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Últimos 7 días")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(stringResource(R.string.progress_tab_consistencia), style = MaterialTheme.typography.titleSmall, color = brandGreen)
                Text(
                    if (count == 0) "Aún no hay entrenos registrados en los últimos 7 días."
                    else "Has entrenado $count de 7 días. Mantén el ritmo.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    days.forEach { (day, did) ->
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Box(
                                Modifier
                                    .size(28.dp)
                                    .clip(RoundedCornerShape(14.dp))
                                    .background(if (did) brandGreen else MaterialTheme.colorScheme.surfaceVariant)
                            )
                            Text(
                                day.dayOfWeek.getDisplayName(java.time.format.TextStyle.NARROW, java.util.Locale("es", "ES")),
                                style = MaterialTheme.typography.labelSmall,
                                color = if (day == today) brandGreen else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ProgressLongTermConsistencyCard(
    sessionCount: Int,
    totalMinutes: Int,
    today: LocalDate,
    overview: StateOverview?
) {
    val start = today.minusDays(27)
    val trained = trainedDays(overview, start, today)
    val cells = (0..27).map { offset ->
        val day = start.plusDays(offset.toLong())
        trained.contains(day)
    }
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.progress_tab_consistencia), style = MaterialTheme.typography.titleSmall, color = brandGreen)
            Text(
                "En las últimas 4 semanas has entrenado ${trained.size} días distintos · $sessionCount sesiones · $totalMinutes min.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                cells.chunked(7).forEach { row ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        row.forEach { on ->
                            Box(
                                Modifier
                                    .weight(1f)
                                    .height(14.dp)
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(if (on) brandGreen else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f))
                            )
                        }
                    }
                }
            }
        }
    }
}

private fun trainedDays(overview: StateOverview?, from: LocalDate, to: LocalDate): Set<LocalDate> {
    val history = overview?.completeHistory.orEmpty().ifEmpty { overview?.history.orEmpty() }
    return history.mapNotNull { workout ->
        workout.finishedAtIso?.let { iso ->
            runCatching {
                java.time.Instant.parse(iso).atZone(java.time.ZoneId.systemDefault()).toLocalDate()
            }.getOrNull()
        }
    }.filter { it in from..to }.toSet()
}

@Composable
private fun TrainingMeasuredEffortCard(workout: WorkoutHistoryEntry) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Cardio del entrenamiento")
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(Modifier.fillMaxWidth().padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(9.dp)) {
                Text(workout.title, style = MaterialTheme.typography.titleSmall)
                workout.appleAverageHeartRateBpm?.takeIf { it.isFinite() && it > 0 }?.let { pulse ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(stringResource(R.string.progress_tab_frecuencia_cardiaca_media), color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text("${kotlin.math.round(pulse).toInt()} lpm", fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold)
                    }
                }
                workout.appleActiveEnergyKcal?.takeIf { it.isFinite() && it > 0 }?.let { kcal ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(stringResource(R.string.progress_tab_energia_medida), color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text("${kotlin.math.round(kcal).toInt()} kcal", fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold)
                    }
                }
                Text(
                    stringResource(R.string.progress_tab_las_zonas_cardiacas_no_se_calculan),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
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
        ReperaAccents.minutes,
        ReperaAccents.energy
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
    else -> if (delta > 0) brandGreen else MaterialTheme.colorScheme.error
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
                title = stringResource(R.string.progress_tab_periodo),
                trailing = {
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.Close,
                        contentDescription = stringResource(R.string.action_close),
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
                    val allowed = subscriptions?.canSelectProgressRange(range)?.allowed ?: false
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
                                stringResource(R.string.progress_tab_pro),
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
        weightPoints = when {
            snap.weightPoints.size >= 2 -> snap.weightPoints
            snap.weightPoints.isEmpty() -> ProgressPreview.weight(today)
            else -> {
                // Un solo pesaje real: conserva la curva de ejemplo y ancla el último punto.
                val preview = ProgressPreview.weight(today)
                preview.dropLast(1) + snap.weightPoints.last()
            }
        },
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
internal fun WeightPreviewCard(
    today: LocalDate,
    loggedPoints: List<dev.repera.domain.ProgressDayPoint> = emptyList(),
    accountId: String = "",
    busy: Boolean = false,
    onLogBodyWeight: (Double) -> Unit = {}
) {
    val points = when {
        loggedPoints.size >= 2 -> loggedPoints
        loggedPoints.isEmpty() -> ProgressPreview.weight(today)
        else -> ProgressPreview.weight(today).dropLast(1) + loggedPoints.last()
    }
    Column(
        Modifier
            .fillMaxWidth()
            .widthIn(max = 420.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        ReperaSectionTitle(
            if (loggedPoints.isEmpty()) "Peso corporal · ejemplo" else "Peso corporal"
        )
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                DayPointLineChart(points, goal = 74.0, interactive = false, weightStyle = true, weightPreview = true)
                WeightStatTiles(points.lastOrNull()?.value, 74.0)
                if (accountId.isNotEmpty()) {
                    WeightLogRow(accountId, busy, onLogBodyWeight)
                }
            }
        }
    }
}

@Composable
internal fun HeartZonesDemoCard() {
    data class Zone(val label: String, val pct: Float, val color: Color)
    val zones = listOf(
        Zone("Z1", 0.18f, ReperaAccents.heartZones[0]),
        Zone("Z2", 0.28f, ReperaAccents.heartZones[1]),
        Zone("Z3", 0.24f, ReperaAccents.heartZones[2]),
        Zone("Z4", 0.18f, ReperaAccents.heartZones[3]),
        Zone("Z5", 0.12f, ReperaAccents.heartZones[4])
    )
    ReperaCard(Modifier.fillMaxWidth().testTag("heart_zones_card")) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .height(28.dp)
                    .clip(RoundedCornerShape(10.dp))
            ) {
                zones.forEach { zone ->
                    Box(
                        Modifier
                            .weight(zone.pct)
                            .fillMaxHeight()
                            .background(zone.color),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "${(zone.pct * 100).toInt()}%",
                            style = MaterialTheme.typography.labelSmall,
                            color = Color.White
                        )
                    }
                }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                zones.forEach { zone ->
                    Text(zone.label, style = MaterialTheme.typography.labelSmall, color = zone.color)
                }
            }
        }
    }
}

@Composable internal fun ProgressWeightCard(points:List<dev.repera.domain.ProgressDayPoint>,delta30d:Double?,goalKg:Double?,accountId:String,busy:Boolean,onLogBodyWeight:(Double)->Unit) {
 Column(
  Modifier.fillMaxWidth().widthIn(max = 420.dp),
  verticalArrangement = Arrangement.spacedBy(8.dp)
 ) {
  ReperaSectionTitle("Peso corporal")
 if(points.isEmpty()) ReperaCard(modifier = Modifier.fillMaxWidth()) {Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
  WeightStatTiles(null,goalKg)
  EmptyHealthChart("Sin mediciones en el periodo.",goalKg?.minus(2) ?: 60.0,goalKg?.plus(2) ?: 90.0,210.dp)
  WeightLogRow(accountId, busy, onLogBodyWeight)
 }} else {
                    ReperaCard(modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            val last = points.last()
                            Text(
                                "Último: ${formatWeight(last.value)} kg (${last.day.format(reperaDayFormatter)})",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            delta30d?.let { delta ->
                                val sign = if (delta >= 0) "+" else ""
                                Text("Cambio 30 días: $sign${formatWeight(delta)} kg",
                                    style = MaterialTheme.typography.bodySmall)
                            }
                            WeightStatTiles(last.value, goalKg)
                            DayPointLineChart(points,goal=goalKg,weightStyle=true)
                            WeightLogRow(accountId, busy, onLogBodyWeight)
                        }
                    }
 }
 }
}

@Composable
private fun WeightLogRow(accountId: String, busy: Boolean, onLogBodyWeight: (Double) -> Unit) {
    val weightScope = remember(accountId) {
        org.json.JSONArray(listOf(accountId, "progress-weight-input")).toString()
    }
    val weightSaver = remember(weightScope) {
        androidx.compose.runtime.saveable.Saver<String, String>(
            save = { saveScopedEditorValue(weightScope, it) },
            restore = { restoreScopedEditorValue(weightScope, it) }
        )
    }
    var weightInput by rememberSaveable(accountId, stateSaver = weightSaver) { mutableStateOf("") }
    val fieldHeight = 56.dp
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.End),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ReperaNumericField(
            value = weightInput,
            onValueChange = { weightInput = it },
            label = stringResource(R.string.progress_tab_peso_kg),
            modifier = Modifier.fillMaxWidth(0.25f)
        )
        Button(
            onClick = {
                dev.repera.domain.ReperaNumberFormat.parse(weightInput)?.let {
                    onLogBodyWeight(it)
                    weightInput = ""
                }
            },
            enabled = !busy && weightInput.isNotBlank(),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Black,
                contentColor = Color.White,
                disabledContainerColor = Color.Black.copy(alpha = 0.35f),
                disabledContentColor = Color.White.copy(alpha = 0.7f)
            ),
            shape = RoundedCornerShape(10.dp),
            modifier = Modifier.height(fieldHeight),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 0.dp)
        ) { Text(stringResource(R.string.progress_tab_registrar)) }
    }
}
