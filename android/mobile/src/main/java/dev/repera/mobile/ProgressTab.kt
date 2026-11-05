package dev.repera.mobile

import androidx.compose.ui.res.stringResource
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.IntrinsicSize
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
import dev.repera.domain.LiveSport
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
    // El último entreno se elige de todo el archivo, también Health Connect.
    val latestActivityTitle = remember(overview) {
        val local = overview?.completeHistory.orEmpty()
            .filter { it.timerDetails == null && it.finishedAtIso != null }
            .maxByOrNull { it.finishedAtIso.orEmpty() }
        val external = overview?.externalHealthHistory.orEmpty().maxByOrNull { it.endMillis }
        val localEnd = local?.finishedAtIso?.let {
            runCatching { java.time.Instant.parse(it).toEpochMilli() }.getOrNull()
        } ?: Long.MIN_VALUE
        if (external != null && external.endMillis > localEnd) {
            external.title + " · " + external.minutes.toInt() + " min"
        } else local?.let { workout ->
            val sensorFacts = listOfNotNull(
                workout.appleActiveEnergyKcal?.takeIf { it > 0 }
                    ?.let { it.toInt().toString() + " kcal" },
                workout.appleAverageHeartRateBpm?.takeIf { it > 0 }
                    ?.let { it.toInt().toString() + " lpm" }
            )
            workout.title + " · " + workout.displayDurationMinutes().toInt() + " min" +
                (if (sensorFacts.isEmpty()) "" else " · " + sensorFacts.joinToString(" · "))
        }
    }
    // 7 sesiones, no 7 fechas. El historial completo incluye planes,
    // Comenzar, Watch y actividades que proceden de Health Connect.
    val recentWorkoutBars = remember(overview) {
        val local = overview?.completeHistory.orEmpty().mapNotNull { workout ->
            if (workout.timerDetails != null) return@mapNotNull null
            val end = workout.finishedAtIso?.let {
                runCatching { java.time.Instant.parse(it).toEpochMilli() }.getOrNull()
            } ?: return@mapNotNull null
            RecentWorkoutPlot(
                id = "repera-" + workout.id, title = workout.title, finishedMillis = end,
                minutes = workout.displayDurationMinutes().takeIf { it > 0 },
                verifiedScore = workout.review?.takeIf {
                    it.scoreBasis == dev.repera.domain.ScoreBasis.PERSONAL_HISTORY
                }?.overallScore
            )
        }
        val imported = overview?.externalHealthHistory.orEmpty().filterNot { activity ->
            // Salud y Repera pueden referirse a la misma grabación: no duplicar.
            local.any { session ->
                kotlin.math.abs(session.finishedMillis - activity.endMillis) < 90_000L &&
                    kotlin.math.abs((session.minutes ?: 0.0) - activity.minutes) < 3.0
            }
        }.map { activity ->
            RecentWorkoutPlot(
                id = "health-" + activity.id, title = activity.title,
                finishedMillis = activity.endMillis,
                minutes = activity.minutes.takeIf { it > 0 }, verifiedScore = null
            )
        }
        (local + imported).sortedByDescending { it.finishedMillis }.take(7).reversed()
    }
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
    LaunchedEffect(Unit) {
        // Hub fijo: Últimos 7 días (mes solo en bloques «Este mes» / Media mes).
        selectedRange = ProgressTimeRange.WEEK.wire
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
        ProgressCategory.HEART, ProgressCategory.RECOVERY -> "Ahora"
        else -> "Últimos 7 días"
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
    val realHeartCharts = overview?.chartsByRange?.get(ProgressTimeRange.WEEK.wire)
    val heartWeekPoints = realHeartCharts?.heartRate.orEmpty().filter {
        ProgressTimeRange.WEEK.contains(it.day, today, monday)
    }
    val recentHeartPoint = heartWeekPoints.lastOrNull { it.avgBpm > 0 }
        ?: realHeartCharts?.heartRate?.lastOrNull { it.avgBpm > 0 }
    val recentHeartBpm = recentHeartPoint?.avgBpm?.takeIf { it > 0 }?.roundToInt()
        ?: realHeartCharts?.averageHeartRate?.takeIf { it > 0 }?.roundToInt()
        ?: snapshot?.averageHeartRate?.takeIf { it > 0 }?.roundToInt()
    val recentHeartMin = heartWeekPoints.mapNotNull { it.minBpm.takeIf { bpm -> bpm > 0 } }
        .minOrNull()?.roundToInt()
    val recentHeartMax = heartWeekPoints.mapNotNull { it.maxBpm.takeIf { bpm -> bpm > 0 } }
        .maxOrNull()?.roundToInt()
    val heartSparkFractions = heartDailyBarFractions(heartWeekPoints)
    val heartSparkRanges = heartDailyBarRanges(heartWeekPoints)
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
                            ProgressCategory.FITNESS -> {
                                // Misma métrica que Estímulo activo: media diaria de últimos 7 días.
                                val total = snapshot?.summary?.totalMinutes?.toInt() ?: 0
                                val avg = dailyAverageMinutes(total)
                                if (avg > 0) compactActiveDuration(avg) else "—"
                            }
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
                                    confidenceLabel = if (pro) overview?.sessionScoreConfidenceByRange?.get(selectedRange) else null,
                                    latestActivity = latestActivityTitle,
                                    recordedSessions = overview?.dayWorkoutCounts
                                        ?.filterKeys { rangeEnum.contains(it, today, monday) }
                                        ?.values?.sum() ?: 0,
                                    recentWorkouts = recentWorkoutBars
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
                    item { ProgressWeekConsistencyCard(today = today, overview = overview) }
                    item {
                        val monthSnap = overview?.progressByRange?.get(ProgressTimeRange.MONTH.wire)
                        val avg = overview?.sessionScoresByRange?.get(ProgressTimeRange.MONTH.wire)
                            ?.map { it.value }
                            ?.takeIf { it.isNotEmpty() }
                            ?.let { values ->
                                String.format(java.util.Locale("es", "ES"), "%.1f", values.average())
                            } ?: "—"
                        ProgressTrainingGlanceGrid(
                            monthSnap ?: snapshot,
                            averageText = avg,
                            streakOverride = snapshot.streak
                        )
                    }
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
                        val period = "últimos 7 días"
                        val strengthBars = strengthDailyBarFractions(snapshot.hubDailyVolumeKg)
                        val todayPrs = overview?.completeHistory.orEmpty().sumOf { entry ->
                            val day = entry.finishedAtIso?.let {
                                runCatching { java.time.Instant.parse(it) }.getOrNull()
                            }?.atZone(java.time.ZoneId.systemDefault())?.toLocalDate()
                            if (day == today) overview?.prCountBySessionId?.get(entry.id) ?: 0 else 0
                        }
                        val todaySummary = "Hoy " + (overview?.dayWorkoutCounts?.get(today) ?: 0) +
                            " ses. · " + (snapshot.hubDailyVolumeKg.lastOrNull()?.toInt() ?: 0) +
                            " kg · " + todayPrs + " PR"
                        ProgressSaludInsightCard(
                            title = stringResource(R.string.progress_tab_carga_y_marcas),
                            icon = Icons.Outlined.FitnessCenter,
                            tint = ProgressCategory.STRENGTH.accent,
                            narrative = strengthInsightCopy(
                                prCount = snapshot.records.size,
                                volumeKg = snapshot.summary.volumeKg.toInt(),
                                activitiesToday = overview?.dayWorkoutCounts?.get(today) ?: 0
                            ),
                            heroValue = if (snapshot.records.isEmpty()) "—" else "${snapshot.records.size}",
                            heroUnit = if (snapshot.records.isEmpty()) null else "PR",
                            heroCaption = when {
                                snapshot.summary.volumeKg > 0 ->
                                    snapshot.summary.volumeKg.toInt().toString() + " kg / 7 d\n" +
                                        todaySummary
                                (overview?.dayWorkoutCounts?.get(today) ?: 0) > 0 -> todaySummary
                                snapshot.records.isEmpty() -> "sin marcas aún"
                                else -> period
                            },
                            barFractions = strengthBars,
                            elevateChart = true,
                            chartBesideTitle = true,
                            chartStyle = ProgressMiniChartStyle.AREA
                        )
                    }
                    item {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            ProgressMetricGlanceCard(
                                title = stringResource(R.string.progress_tab_sesiones_fuerza),
                                value = if (snapshot.strengthSessionCount > 0) {
                                    "${snapshot.strengthSessionCount}"
                                } else {
                                    "—"
                                },
                                modifier = Modifier.weight(1f),
                                tint = ProgressCategory.STRENGTH.accent
                            )
                            ProgressMetricGlanceCard(
                                title = stringResource(R.string.tab_exercises),
                                value = if (snapshot.strengthExerciseCount > 0) {
                                    "${snapshot.strengthExerciseCount}"
                                } else {
                                    "—"
                                },
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
                item { ReperaSectionTitle("Físico") }
                item {
                    val minutes = snapshot?.summary?.totalMinutes?.toInt() ?: 0
                    val averageDaily = dailyAverageMinutes(minutes)
                    val hero = activeDurationHero(averageDaily)
                    val period = "últimos 7 días"
                    val spark = fitnessDailyBarFractions(
                        overview = overview,
                        today = today,
                        monday = monday,
                        range = ProgressTimeRange.WEEK
                    )
                    ProgressSaludInsightCard(
                        title = stringResource(R.string.progress_tab_estimulo_activo),
                        icon = Icons.Outlined.DirectionsWalk,
                        tint = ProgressCategory.FITNESS.accent,
                        narrative = if (averageDaily > 0) "" else activeDurationNarrative(averageDaily, period),
                        heroValue = hero.first,
                        heroUnit = hero.second,
                        heroCaption = if (averageDaily > 0) "media diaria" else null,
                        barFractions = spark,
                        elevateChart = true,
                        chartBesideTitle = true,
                        chartStyle = ProgressMiniChartStyle.FILL
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
                    val daysElapsed = daysElapsedInCalendarMonth(today)
                    val weeklyAvg = weeklyAverageMinutes(monthMins, daysElapsed)
                    val hero = activeDurationHero(weeklyAvg)
                    val spark = fitnessDailyBarFractions(
                        overview = overview,
                        today = today,
                        monday = monday,
                        range = ProgressTimeRange.MONTH
                    )
                    ProgressMonthSummaryCard(
                        title = "Actividad del mes",
                        icon = Icons.Outlined.DirectionsWalk,
                        tint = ProgressCategory.FITNESS.accent,
                        narrative = if (monthMins > 0) "" else {
                            "Cuando registres actividad este mes, verás aquí el resumen."
                        },
                        heroValue = hero.first,
                        heroUnit = hero.second,
                        heroCaption = if (monthMins > 0) "media semana" else null,
                        barFractions = spark,
                        elevateChart = true,
                        chartBesideTitle = true,
                        chartStyle = ProgressMiniChartStyle.FILL
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
                        narrative = if (recentHeartBpm != null) {
                            ""
                        } else {
                            "Conecta Health Connect o un pulsómetro para ver tu ritmo aquí."
                        },
                        heroValue = recentHeartBpm?.toString() ?: "—",
                        heroUnit = if (recentHeartBpm != null) "LPM" else null,
                        heroCaption = if (recentHeartBpm != null) "media reciente" else null,
                        barFractions = heartSparkFractions,
                        barRanges = heartSparkRanges,
                        elevateChart = true,
                        chartStyle = ProgressMiniChartStyle.RANGE
                    )
                }
                if (recentHeartMin != null || recentHeartMax != null) {
                    item {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            ProgressMetricGlanceCard(
                                title = "Mín. 7 d",
                                value = recentHeartMin?.toString() ?: "—",
                                modifier = Modifier.weight(1f),
                                tint = ProgressCategory.HEART.accent
                            )
                            ProgressMetricGlanceCard(
                                title = "Máx. 7 d",
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
                    val monthHr = overview?.chartsByRange?.get(ProgressTimeRange.MONTH.wire)
                        ?.heartRate.orEmpty()
                        .filter { it.avgBpm > 0 }
                        .sortedBy { it.day }
                    val weeklyBpm = heartWeeklyAverageBpm(monthHr)
                    val bpm = weeklyBpm
                        ?: overview?.chartsByRange?.get(ProgressTimeRange.MONTH.wire)
                            ?.averageHeartRate?.takeIf { it > 0 }?.roundToInt()
                        ?: overview?.progressByRange?.get(ProgressTimeRange.MONTH.wire)
                            ?.averageHeartRate?.takeIf { it > 0 }?.roundToInt()
                    val sparkRanges = heartDailyBarRanges(monthHr)
                    val spark = heartDailyBarFractions(monthHr)
                    ProgressMonthSummaryCard(
                        title = "Cardio del mes",
                        icon = Icons.Outlined.MonitorHeart,
                        tint = ProgressCategory.HEART.accent,
                        narrative = if (bpm != null) {
                            ""
                        } else {
                            "Con más lecturas de pulso este mes verás aquí la media."
                        },
                        heroValue = bpm?.toString() ?: "—",
                        heroCaption = if (bpm != null) "media/semana" else null,
                        heroUnit = if (bpm != null) "LPM" else null,
                        barFractions = spark,
                        barRanges = sparkRanges,
                        elevateChart = true,
                        chartStyle = ProgressMiniChartStyle.RANGE
                    )
                }
            }
            ProgressCategory.RECOVERY -> {
                val baseRecovery = overview?.recovery ?: RecoveryState(null, null, null, null)
                val recovery = if (PROGRESS_DEMO_CHARTS) enrichRecoveryWithDemo(baseRecovery, today) else baseRecovery
                item {
                    RecoveryHistoryCards(
                        recovery,
                        ProgressTimeRange.WEEK,
                        monday,
                        pro || PROGRESS_DEMO_CHARTS,
                        outerHorizontalPaddingDp = 32f
                    )
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
                val period = "últimos 7 días"
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
                val allLiveMins = allSportSessions.sumOf {
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
                val evolutionFractions = sportsDailyBarFractions(allSportSessions)
                val progressRows = overview?.exerciseProgress.orEmpty()
                    .filter { it.value.timesPerformed >= 2 && (it.value.estimatedOneRM ?: 0.0) > 0 }
                    .entries
                    .sortedByDescending { it.value.estimatedOneRM ?: 0.0 }
                    .take(5)
                val monthHighlights = monthActivityHighlights(
                    liveSessions = monthSportSessions,
                    external = overview?.externalHealthHistory.orEmpty().filter { entry ->
                        val day = java.time.Instant.ofEpochMilli(entry.startMillis)
                            .atZone(zone).toLocalDate()
                        ProgressTimeRange.MONTH.contains(day, today, monday)
                    }
                )
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
                            value = "7 días",
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
                            if (allSportSessions.isEmpty()) {
                                Text(
                                    "Registra salidas En vivo para ver evolución y récords.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            if (evolutionFractions.isNotEmpty()) {
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        compactActiveDuration(allLiveMins),
                                        style = MaterialTheme.typography.titleLarge,
                                        fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                                    )
                                    ProgressMiniBarRow(
                                        evolutionFractions,
                                        ProgressCategory.SPORTS.accent,
                                        modifier = Modifier
                                            .width((evolutionFractions.size * 10).coerceIn(88, 132).dp)
                                            .height((28 + evolutionFractions.size * 2).coerceIn(36, 56).dp)
                                    )
                                }
                            }
                        }
                    }
                }
                if (improved > 0) {
                    item {
                        ReperaCard(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                        Icon(Icons.Outlined.FitnessCenter, null, tint = ProgressCategory.STRENGTH.accent)
                                        Text(
                                            "Progresión en ejercicios",
                                            style = MaterialTheme.typography.titleSmall,
                                            color = ProgressCategory.STRENGTH.accent
                                        )
                                    }
                                    Text(
                                        "$improved al alza",
                                        style = MaterialTheme.typography.titleSmall,
                                        fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                                        color = ProgressCategory.STRENGTH.accent
                                    )
                                }
                                progressRows.forEach { (id, summary) ->
                                    val name = overview?.exerciseEntries?.firstOrNull { it.id == id }?.name
                                        ?: id
                                    val e1 = summary.estimatedOneRM?.toInt()
                                    Row(Modifier.fillMaxWidth()) {
                                        Text(
                                            name,
                                            modifier = Modifier.weight(1f),
                                            style = MaterialTheme.typography.bodyMedium,
                                            maxLines = 1
                                        )
                                        Text(
                                            e1?.let { "e1RM $it kg" } ?: "—",
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = ProgressCategory.STRENGTH.accent,
                                            fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        ReperaSectionTitle("Este mes")
                        ProgressSaludInsightCard(
                            title = "Resumen por actividad",
                            icon = Icons.Outlined.Flag,
                            tint = ProgressCategory.SPORTS.accent,
                            narrative = if (monthHighlights.isEmpty()) {
                                "Cuando registres salidas o actividades este mes, verás aquí el resumen."
                            } else {
                                ""
                            },
                            heroValue = when {
                                monthSportCount > 0 -> "$monthSportCount"
                                monthHighlights.isNotEmpty() -> "${monthHighlights.size}"
                                else -> "—"
                            },
                            heroUnit = null,
                            heroCaption = null,
                            stackedMetaTop = compactActiveDuration(monthSportMins),
                            stackedMetaBottom = when {
                                monthSportCount > 0 -> "salidas"
                                monthHighlights.isNotEmpty() -> "activ."
                                else -> null
                            }
                        )
                        monthHighlights.take(6).forEach { row ->
                            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                                Row(
                                    Modifier.padding(14.dp).fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column(Modifier.weight(1f)) {
                                        Text(
                                            row.title,
                                            style = MaterialTheme.typography.titleMedium,
                                            fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                                            color = MaterialTheme.colorScheme.onSurface,
                                            maxLines = 2
                                        )
                                        Text(
                                            "${row.sessionCount}× · ${row.bestLine}",
                                            style = MaterialTheme.typography.labelMedium,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                                            maxLines = 1
                                        )
                                    }
                                    Text(
                                        row.primaryValue,
                                        style = MaterialTheme.typography.headlineSmall,
                                        fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                                        maxLines = 1
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }
}

private fun strengthInsightCopy(prCount: Int, volumeKg: Int, activitiesToday: Int = 0): String {
    if (prCount == 0 && volumeKg == 0) {
        return if (activitiesToday > 0)
            activitiesToday.toString() + " actividades registradas hoy. La carga en kg necesita " +
                "series y pesos reales; tus sesiones sí cuentan en Progreso."
        else "Cuando registres series de fuerza, verás aquí la carga y tus marcas."
    }
    return ""
}

/** Volumen kg/día del hub (relativo al pico). */
private fun strengthDailyBarFractions(dailyKg: List<Double>): List<Float> {
    if (dailyKg.isEmpty()) return emptyList()
    val peak = dailyKg.maxOrNull()?.takeIf { it > 0 } ?: return emptyList()
    return dailyKg.map { vol ->
        if (vol > 0) (vol / peak).toFloat().coerceIn(0.12f, 1f) else 0.08f
    }
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
    if (minutes < 60) return "$minutes" to "m"
    val h = minutes / 60
    val m = minutes % 60
    return if (m == 0) "$h" to "h" else "$h h $m" to "m"
}

/** Media diaria = minutos totales / 7 (ventana fija; días sin estímulo = 0 min). */
private fun dailyAverageMinutes(total: Int, days: Int = 7): Int {
    if (total <= 0 || days <= 0) return 0
    return (total.toDouble() / days).roundToInt()
}

/** Media por semana del mes = total / (días transcurridos / 7). */
private fun weeklyAverageMinutes(total: Int, daysElapsedInMonth: Int): Int {
    if (total <= 0) return 0
    val weeks = maxOf(1.0, maxOf(1, daysElapsedInMonth) / 7.0)
    return (total.toDouble() / weeks).roundToInt()
}

private fun daysElapsedInCalendarMonth(today: LocalDate): Int =
    today.dayOfMonth.coerceAtLeast(1)

private fun activeDurationNarrative(averageDaily: Int, period: String): String {
    if (averageDaily <= 0) {
        return "Cuando camines o entrenes, verás aquí tu estímulo y el mapa de días activos."
    }
    return "Media de ${compactActiveDuration(averageDaily)} al día en $period."
}

private fun fitnessDailyBarFractions(
    overview: StateOverview?,
    today: LocalDate,
    monday: Boolean,
    range: ProgressTimeRange
): List<Float> {
    val start = range.startDate(today, monday) ?: today
    val zone = java.time.ZoneId.systemDefault()
    val byDay = linkedMapOf<LocalDate, Double>()
    val history = overview?.completeHistory.orEmpty().ifEmpty { overview?.history.orEmpty() }
    for (entry in history) {
        val day = entry.finishedAtIso?.let { iso ->
            runCatching { java.time.Instant.parse(iso).atZone(zone).toLocalDate() }.getOrNull()
        } ?: continue
        if (!range.contains(day, today, monday)) continue
        val mins = entry.displayDurationMinutes().coerceAtLeast(0.0)
        if (mins > 0) byDay[day] = (byDay[day] ?: 0.0) + mins
    }
    for (entry in overview?.externalHealthHistory.orEmpty()) {
        val day = java.time.Instant.ofEpochMilli(entry.startMillis).atZone(zone).toLocalDate()
        if (!range.contains(day, today, monday)) continue
        val mins = entry.minutes.coerceAtLeast(0.0)
        if (mins > 0) byDay[day] = (byDay[day] ?: 0.0) + mins
    }
    val values = generateSequence(start) { it.plusDays(1) }
        .takeWhile { !it.isAfter(today) }
        .map { byDay[it] ?: 0.0 }
        .toList()
    val peak = values.maxOrNull()?.takeIf { it > 0 } ?: return emptyList()
    return values.map { m ->
        if (m > 0) (m / peak).toFloat().coerceIn(0.12f, 1f) else 0.08f
    }
}

private fun heartWeeklyAverageBpm(points: List<HeartRatePlotPoint>): Int? {
    if (points.isEmpty()) return null
    val weeks = points.groupBy {
        it.day.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
    }
    val weekAvgs = weeks.values.map { vals -> vals.map { it.avgBpm }.average() }
    if (weekAvgs.isEmpty()) return null
    return weekAvgs.average().takeIf { it > 0 }?.roundToInt()
}

/** Alias de fracciones de altura a partir de rangos min–máx (Cardio del mes). */
private fun heartMonthBarFractions(points: List<HeartRatePlotPoint>): List<Float> =
    heartDailyBarFractions(points)

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

/** Altura relativa de rango FC (compat). Preferir `heartDailyBarRanges` para barras levitando. */
private fun heartDailyBarFractions(points: List<HeartRatePlotPoint>): List<Float> =
    heartDailyBarRanges(points).map { (lo, hi) -> (hi - lo).coerceIn(0.12f, 1f) }

/**
 * Rangos lpm min–máx → Y 0…1. El suelo del plot no es 0 lpm: es domainLo.
 * Un día 58…120 flota a media altura; no nace en el eje X.
 */
private fun heartDailyBarRanges(points: List<HeartRatePlotPoint>): List<Pair<Float, Float>> {
    val sample = points.filter {
        it.minBpm > 0 && it.maxBpm > 0 && it.maxBpm >= it.minBpm
    }
    if (sample.isEmpty()) return emptyList()
    val dataMin = sample.minOf { it.minBpm }
    val dataMax = sample.maxOf { it.maxBpm }
    val domainLo = minOf(dataMin - 12.0, dataMin * 0.85)
    val domainHi = maxOf(dataMax + 12.0, dataMin + 40.0)
    val span = (domainHi - domainLo).coerceAtLeast(1.0)
    return sample.map { point ->
        val lo = ((point.minBpm - domainLo) / span).toFloat().coerceIn(0.04f, 0.9f)
        val hi = ((point.maxBpm - domainLo) / span).toFloat().coerceIn(0.04f, 0.98f)
        lo to maxOf(hi, lo + 0.08f)
    }
}

/** Media móvil ligera (2 pases) para suavizar picos del área de carga. */
private fun smoothFractions(values: List<Float>): List<Float> {
    if (values.size <= 2) return values
    var current = values
    repeat(2) {
        val next = current.toMutableList()
        for (i in 1 until current.lastIndex) {
            next[i] = current[i - 1] * 0.22f + current[i] * 0.56f + current[i + 1] * 0.22f
        }
        current = next
    }
    return current
}

private data class MonthActivityHighlightRow(
    val title: String,
    val sessionCount: Int,
    val primaryValue: String,
    val bestLine: String,
    val sortMeters: Double,
    val sortMinutes: Double
)

private fun compactDistanceMeters(meters: Double): String {
    if (meters <= 0) return "—"
    if (meters < 1000) return "${meters.roundToInt()} m"
    return String.format(java.util.Locale("es", "ES"), "%.1f km", meters / 1000.0)
}

private fun monthActivityHighlights(
    liveSessions: List<dev.repera.domain.LiveSportHistory.LiveSession>,
    external: List<ExternalHealthHistoryEntry>
): List<MonthActivityHighlightRow> {
    data class Bucket(
        var title: String,
        var prefersDistance: Boolean,
        var count: Int = 0,
        var totalMinutes: Double = 0.0,
        var totalMeters: Double = 0.0,
        var bestMinutes: Double = 0.0,
        var bestMeters: Double = 0.0
    )
    val buckets = linkedMapOf<String, Bucket>()
    for (session in liveSessions) {
        val sport = LiveSport.byId(session.sportID)
        val key = "live:${session.sportID}"
        val bucket = buckets.getOrPut(key) {
            Bucket(
                title = sport?.title ?: session.title.ifBlank { "Deporte" },
                prefersDistance = sport?.usesGPS == true
            )
        }
        val mins = ((session.activeDurationSeconds ?: 0.0) / 60.0).coerceAtLeast(0.0)
        bucket.count += 1
        bucket.totalMinutes += mins
        bucket.bestMinutes = maxOf(bucket.bestMinutes, mins)
        val meters = session.recordedDistanceMeters?.takeIf { it > 0 }
        if (meters != null) {
            bucket.prefersDistance = true
            bucket.totalMeters += meters
            bucket.bestMeters = maxOf(bucket.bestMeters, meters)
        }
    }
    for (entry in external) {
        val key = "ext:${entry.exerciseTypeKey}"
        val bucket = buckets.getOrPut(key) {
            Bucket(
                title = entry.title.ifBlank { entry.exerciseTypeKey },
                prefersDistance = false
            )
        }
        bucket.count += 1
        bucket.totalMinutes += entry.minutes.coerceAtLeast(0.0)
        bucket.bestMinutes = maxOf(bucket.bestMinutes, entry.minutes.coerceAtLeast(0.0))
        val meters = entry.distanceMeters?.takeIf { it > 0 }
        if (meters != null) {
            bucket.prefersDistance = true
            bucket.totalMeters += meters
            bucket.bestMeters = maxOf(bucket.bestMeters, meters)
        }
    }
    return buckets.values.map { bucket ->
        val useDistance = bucket.prefersDistance && bucket.totalMeters > 0
        MonthActivityHighlightRow(
            title = bucket.title,
            sessionCount = bucket.count,
            primaryValue = if (useDistance) {
                compactDistanceMeters(bucket.totalMeters)
            } else {
                compactActiveDuration(bucket.totalMinutes.roundToInt())
            },
            bestLine = if (useDistance) {
                "Más larga · ${compactDistanceMeters(bucket.bestMeters)}"
            } else {
                "Más larga · ${compactActiveDuration(bucket.bestMinutes.roundToInt())}"
            },
            sortMeters = bucket.totalMeters,
            sortMinutes = bucket.totalMinutes
        )
    }.sortedWith(compareByDescending<MonthActivityHighlightRow> { it.sortMeters }.thenByDescending { it.sortMinutes })
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

@Composable
private fun ProgressMiniBarRow(
    fractions: List<Float>,
    tint: Color,
    modifier: Modifier = Modifier
        .fillMaxWidth()
        .height(56.dp),
    fillFromBottom: Boolean = true
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(if (fillFromBottom) 4.dp else 3.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        fractions.forEach { fraction ->
            val f = fraction.coerceIn(0.08f, 1f)
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight(f)
                    .clip(
                        if (fillFromBottom) RoundedCornerShape(6.dp)
                        else RoundedCornerShape(percent = 50)
                    )
                    .background(tint.copy(alpha = 0.85f))
            )
        }
    }
}

@Composable
private fun ProgressMiniLevitatingBars(
    ranges: List<Pair<Float, Float>>,
    tint: Color,
    modifier: Modifier = Modifier
) {
    // Canvas: Y(lo)→Y(hi) en coordenadas absolutas. Nunca Alignment.Bottom / fillMaxHeight(f).
    Canvas(modifier = modifier) {
        val n = ranges.size
        if (n == 0 || size.height <= 0f || size.width <= 0f) return@Canvas
        val spacing = if (n > 14) 2.dp.toPx() else 4.dp.toPx()
        val slot = (size.width - spacing * (n - 1)) / n
        val barW = (slot * 0.72f).coerceAtLeast(3.dp.toPx())
        ranges.forEachIndexed { i, (rawLo, rawHi) ->
            val lo = rawLo.coerceIn(0f, 1f)
            val hi = rawHi.coerceIn(lo + 0.06f, 1f)
            val yTop = size.height * (1f - hi)
            val yBot = size.height * (1f - lo)
            val barH = (yBot - yTop).coerceAtLeast(5.dp.toPx())
            val x = i * (slot + spacing) + (slot - barW) / 2f
            drawRoundRect(
                color = tint.copy(alpha = 0.92f),
                topLeft = androidx.compose.ui.geometry.Offset(x, yTop),
                size = androidx.compose.ui.geometry.Size(barW, barH),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(barW / 2f, barW / 2f)
            )
        }
    }
}

@Composable
private fun ProgressMiniChart(
    fractions: List<Float>,
    tint: Color,
    style: ProgressMiniChartStyle,
    modifier: Modifier = Modifier,
    ranges: List<Pair<Float, Float>> = emptyList()
) {
    when (style) {
        ProgressMiniChartStyle.FILL -> ProgressMiniBarRow(
            fractions = fractions,
            tint = tint,
            modifier = modifier,
            fillFromBottom = true
        )
        ProgressMiniChartStyle.RANGE -> ProgressMiniLevitatingBars(
            // Si faltan rangos, no usar 0…f (eso es fill desde cero). Levitación aproximada.
            ranges = ranges.ifEmpty {
                fractions.map { f ->
                    val mid = f.coerceIn(0.2f, 0.95f)
                    (mid * 0.55f).coerceAtLeast(0.12f) to mid
                }
            },
            tint = tint,
            modifier = modifier
        )
        ProgressMiniChartStyle.AREA -> {
            val smoothed = smoothFractions(fractions)
            Canvas(modifier = modifier) {
                if (smoothed.isEmpty()) return@Canvas
                val n = smoothed.size
                val step = if (n == 1) 0f else size.width / (n - 1)
                val pts = smoothed.mapIndexed { i, v ->
                    val x = i * step
                    val y = size.height * (1f - v.coerceIn(0f, 1f))
                    x to y
                }
                fun cubicPath(closeBaseline: Boolean): androidx.compose.ui.graphics.Path {
                    val path = androidx.compose.ui.graphics.Path()
                    if (closeBaseline) {
                        path.moveTo(pts.first().first, size.height)
                        path.lineTo(pts.first().first, pts.first().second)
                    } else {
                        path.moveTo(pts.first().first, pts.first().second)
                    }
                    for (i in 0 until pts.lastIndex) {
                        val p0 = pts[maxOf(i - 1, 0)]
                        val p1 = pts[i]
                        val p2 = pts[i + 1]
                        val p3 = pts[minOf(i + 2, pts.lastIndex)]
                        val cp1x = p1.first + (p2.first - p0.first) / 6f
                        val cp1y = p1.second + (p2.second - p0.second) / 6f
                        val cp2x = p2.first - (p3.first - p1.first) / 6f
                        val cp2y = p2.second - (p3.second - p1.second) / 6f
                        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.first, p2.second)
                    }
                    if (closeBaseline) {
                        path.lineTo(pts.last().first, size.height)
                        path.close()
                    }
                    return path
                }
                drawPath(
                    cubicPath(closeBaseline = true),
                    brush = androidx.compose.ui.graphics.Brush.verticalGradient(
                        listOf(tint.copy(alpha = 0.42f), tint.copy(alpha = 0.05f))
                    )
                )
                drawPath(
                    cubicPath(closeBaseline = false),
                    color = tint,
                    style = androidx.compose.ui.graphics.drawscope.Stroke(
                        width = 2.4.dp.toPx(),
                        cap = androidx.compose.ui.graphics.StrokeCap.Round,
                        join = androidx.compose.ui.graphics.StrokeJoin.Round
                    )
                )
            }
        }
    }
}


@Composable
private fun ProgressTrainingGlanceGrid(
    snapshot: ProgressSnapshotData,
    averageText: String,
    streakOverride: Int = snapshot.streak
) {
    val minutes = snapshot.summary.totalMinutes.toInt()
    val timeText = if (minutes >= 60) {
        val h = minutes / 60
        val m = minutes % 60
        if (m == 0) "${h} h" else "${h} h $m"
    } else {
        "${minutes}′"
    }
    val streak = if (streakOverride > 0) "$streakOverride sem" else "—"
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ProgressMetricGlanceCard(
                title = "Media mes",
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
    heroUnit: String? = null,
    barFractions: List<Float> = emptyList(),
    barRanges: List<Pair<Float, Float>> = emptyList(),
    elevateChart: Boolean = false,
    chartBesideTitle: Boolean = false,
    chartStyle: ProgressMiniChartStyle = ProgressMiniChartStyle.FILL
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
            heroCaption = heroCaption,
            barFractions = barFractions,
            barRanges = barRanges,
            elevateChart = elevateChart,
            chartBesideTitle = chartBesideTitle,
            chartStyle = chartStyle
        )
    }
}

private enum class ProgressMiniChartStyle { FILL, RANGE, AREA }

@Composable
private fun ProgressSaludInsightCard(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    tint: Color,
    narrative: String,
    heroValue: String,
    heroUnit: String?,
    heroCaption: String?,
    barFractions: List<Float> = emptyList(),
    barRanges: List<Pair<Float, Float>> = emptyList(),
    elevateChart: Boolean = false,
    chartBesideTitle: Boolean = false,
    stackedMetaTop: String? = null,
    stackedMetaBottom: String? = null,
    chartStyle: ProgressMiniChartStyle = ProgressMiniChartStyle.FILL
) {
    val barHeight = when {
        chartBesideTitle -> 118.dp
        elevateChart -> 72.dp
        else -> 64.dp
    }
    val barWidth = if (elevateChart || chartBesideTitle) 152.dp else 120.dp
    val alignChartBottom = chartStyle != ProgressMiniChartStyle.RANGE
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        if (elevateChart && barFractions.isNotEmpty() && narrative.isEmpty()) {
            if (chartBesideTitle) {
                Row(
                    Modifier.padding(16.dp).fillMaxWidth().height(IntrinsicSize.Min),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.Bottom
                ) {
                    Column(
                        Modifier.weight(1f).fillMaxHeight(),
                        verticalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(icon, contentDescription = null, tint = tint)
                            Text(
                                title,
                                style = MaterialTheme.typography.titleMedium,
                                color = tint,
                                fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold
                            )
                        }
                        Row(verticalAlignment = Alignment.Bottom) {
                            Text(
                                heroValue,
                                style = MaterialTheme.typography.displayLarge,
                                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                                maxLines = 1
                            )
                            if (heroUnit != null) {
                                Text(
                                    " $heroUnit",
                                    style = MaterialTheme.typography.titleLarge,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.padding(bottom = 8.dp)
                                )
                            }
                        }
                        if (heroCaption != null) {
                            Text(
                                heroCaption,
                                style = MaterialTheme.typography.labelLarge,
                                fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    ProgressMiniChart(
                        fractions = barFractions,
                        tint = tint,
                        style = chartStyle,
                        ranges = barRanges,
                        modifier = Modifier
                            .width(barWidth)
                            .height(barHeight)
                    )
                }
            } else {
                Column(
                    Modifier.padding(16.dp).fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(icon, contentDescription = null, tint = tint)
                        Text(
                            title,
                            style = MaterialTheme.typography.titleMedium,
                            color = tint,
                            fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold
                        )
                    }
                    Row(
                        Modifier.fillMaxWidth().height(IntrinsicSize.Min),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = if (alignChartBottom) Alignment.Bottom else Alignment.CenterVertically
                    ) {
                        Column(
                            Modifier.weight(1f).fillMaxHeight(),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(verticalAlignment = Alignment.Bottom) {
                                Text(
                                    heroValue,
                                    style = MaterialTheme.typography.displayLarge,
                                    fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                                    maxLines = 1
                                )
                                if (heroUnit != null) {
                                    Text(
                                        " $heroUnit",
                                        style = MaterialTheme.typography.titleLarge,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.padding(bottom = 8.dp)
                                    )
                                }
                            }
                            if (heroCaption != null) {
                                Text(
                                    heroCaption,
                                    style = MaterialTheme.typography.labelLarge,
                                    fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                        ProgressMiniChart(
                            fractions = barFractions,
                            tint = tint,
                            style = chartStyle,
                            ranges = barRanges,
                            modifier = Modifier
                                .width(barWidth)
                                .height(barHeight)
                        )
                    }
                }
            }
        } else {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(icon, contentDescription = null, tint = tint)
                    Text(
                        title,
                        style = MaterialTheme.typography.titleMedium,
                        color = tint,
                        fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold
                    )
                }
                if (narrative.isNotEmpty()) {
                    Text(
                        narrative,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    if (stackedMetaBottom != null && stackedMetaTop != null) {
                        Row(
                            Modifier.weight(1f),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text(
                                heroValue,
                                style = MaterialTheme.typography.displayMedium,
                                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                            )
                            Column {
                                Text(
                                    stackedMetaTop,
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    stackedMetaBottom,
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    } else {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Row(verticalAlignment = Alignment.Bottom) {
                                Text(
                                    heroValue,
                                    style = MaterialTheme.typography.displayMedium,
                                    fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                                )
                                if (heroUnit != null) {
                                    Text(
                                        " $heroUnit",
                                        style = MaterialTheme.typography.titleLarge,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.padding(bottom = 6.dp)
                                    )
                                }
                            }
                            if (heroCaption != null) {
                                Text(
                                    heroCaption,
                                    style = MaterialTheme.typography.titleSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                    if (barFractions.isNotEmpty()) {
                        ProgressMiniBarRow(
                            fractions = barFractions,
                            tint = tint,
                            modifier = Modifier
                                .width(barWidth)
                                .height(barHeight)
                        )
                    }
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
