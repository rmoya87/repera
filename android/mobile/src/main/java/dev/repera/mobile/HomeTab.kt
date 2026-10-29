package dev.repera.mobile

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.background
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.automirrored.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.EventBusy
import androidx.compose.material.icons.outlined.History
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
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import dev.repera.domain.ExerciseAliasSearch
import dev.repera.domain.WodFormat
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import java.time.LocalDate
import java.time.LocalTime
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.delay


@Composable
internal fun HomeTab(
    displayName: String?,
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    todayHealth: TodayHealth?,
    healthAccess: HealthAccessState = HealthAccessState.UNKNOWN,
    onHealthConnect: () -> Unit,
    activeWorkout: ActiveWorkout?,
    wodTimer: WodTimerState?,
    onWodTimerAction: (String) -> Unit,
    onWodTimerTick: () -> Unit,
    onStartRoutine: (String) -> Unit,
    onWodScore: (Int?, Int?, Int?) -> Unit,
    onWodMovement: (Int, Int, Int, Double?) -> Unit,
    onCompleteWodBlock: () -> Unit,
    onReviseWodMovement: (String, Int, Double?) -> Unit,
    onDeleteWodMovement: (String) -> Unit,
    onLogSet: (Int, Double?, Double?, Boolean, String?, Int?, Int?, Boolean) -> Unit,
    onLogDropSet: (Int, Double?, List<Pair<Int, Double?>>, Double?, Boolean) -> Unit,
    onLogRestPauseSet: (List<Pair<Int, Int>>, Double?, Double?, Boolean) -> Unit,
    onReviseSet: (String, Int, Double?, String?, Int?, Int?) -> Unit,
    onDeleteSet: (String) -> Unit,
    onNext: () -> Unit,
    onSelectActiveExercise:(Int)->Unit = {},
    onUpdateActiveNotes:(String)->Unit = {},
    onSaveActiveFavorite:()->Unit = {},
    onEditActivePlan:()->Unit = {},
    onFinish: () -> Unit,
    onDiscardSession: () -> Unit = {},
    accountId: String = "",
    onUpdateFinishedWorkout: (String, WorkoutRepository.FinishedWorkoutEdit) -> Unit = { _, _ -> },
    onActivePinChange: (dev.repera.domain.WorkoutLocationPin?) -> Unit = {},
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    onReviseFinishedSet: (String, String, String, Int, Double?, Int?) -> Unit,
    onDeleteFinishedSet: (String, String, String) -> Unit,
    onDeleteWorkout: (String) -> Unit = {},
    onOpenExerciseFromSession: (String, String, String) -> Unit = { _, _, _ -> },
    /** Apple 3666d1ac: tap de ejercicio en la vista previa del entreno. */
    onOpenExercise: (String) -> Unit = {},
    heartSeriesProvider: suspend (String) -> List<Pair<Long, Int>> = { emptyList() },

    onNavigateCreate: () -> Unit,
    /** Editar contenido de una rutina planificada (ruta `rutina/{id}`). */
    onEditRoutineContent: (String) -> Unit = {},
    // «＋» del día seleccionado (DayPlusSheet iOS desde HomeView, c5aae1cc).
    onDayPlusCreate: (String, String) -> Unit = { _, _ -> },
    onDayPlusFavorites: (String) -> Unit = {},
    onDayPlusTimer: () -> Unit = {},
    /** ISO day (`yyyy-MM-dd`) selected when opening the board scanner. */
    onDayPlusScan: (String) -> Unit = {},
    onDeleteRoutine: (String) -> Unit = {},
    onRemoveScheduledRoutine: (String) -> Unit = onDeleteRoutine,
    /** iOS `restoresAddSheetAfterPage`: reabrir DayPlus al volver de Favoritos/Tempo. */
    restoreDayPlus: Boolean = false,
    onRestoreDayPlusConsumed: () -> Unit = {},
    onOpenClock: () -> Unit,
    modifier: Modifier = Modifier,
    focusDay: java.time.LocalDate? = null,
    professionalSessions:List<BusinessCenterStore.ProfessionalSession> = emptyList(),
    centerName:(String)->String = {"Centro"},
    onOpenMessages:()->Unit = {},
    onOpenHistory:()->Unit = {},
    onOpenRecoverySettings:()->Unit = {},
    onOpenSettings:()->Unit = {},
    dayHealthProvider:suspend (java.time.LocalDate)->TodayHealth? = {null}
) {
    var homeDateIso by rememberSaveable { mutableStateOf(LocalDate.now().toString()) }
    var showDayPlus by rememberSaveable(accountId) { mutableStateOf(false) }
    LaunchedEffect(focusDay) { focusDay?.let { homeDateIso=it.toString() } }
    LaunchedEffect(restoreDayPlus) {
        if (restoreDayPlus) {
            showDayPlus = true
            onRestoreDayPlusConsumed()
        }
    }
    val selectedDay=LocalDate.parse(homeDateIso)
    var selectedHealth by remember(selectedDay) {mutableStateOf<TodayHealth?>(null)}
    LaunchedEffect(selectedDay,todayHealth,overview?.dayEnergyKcal) {selectedHealth=dayHealthProvider(selectedDay)}
    val dayHealth=selectedHealth ?: todayHealth.takeIf {selectedDay==LocalDate.now()}
    val weekStart=dev.repera.domain.StatsEngine.startOfWeek(selectedDay,overview?.trainingSettings?.weekStartsOnMonday ?: true)
    val selectedWeekCount=(0L..6L).sumOf {overview?.dayWorkoutCounts?.get(weekStart.plusDays(it)) ?: 0}
    val dragListState = androidx.compose.foundation.lazy.rememberLazyListState()
    ProvideLazyDragAutoScroll(dragListState) {
    // Lienzo OG.bg (gris) hasta abajo: la banda blanca es solo topbar+calendario+día.
    // Tras «Actividad de hoy» no debe quedar franja blanca (ampliación Ramón).
    LazyColumn(
        state = dragListState,
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentPadding = PaddingValues(bottom = 28.dp),
        verticalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        // Banda blanca iOS: topbar + calendario + cards del día + CTA
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surface)
                    .padding(top = 12.dp, bottom = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                val dateSubtitle = selectedDay.format(
                    java.time.format.DateTimeFormatter.ofPattern(
                        "EEEE d MMMM", java.util.Locale("es", "ES")
                    )
                ).replaceFirstChar { it.uppercase() }
                ReperaPageHeader(
                    title = "repera",
                    subtitle = dateSubtitle,
                    modifier = Modifier.padding(horizontal = 16.dp),
                    trailing = {
                        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                            if (professionalSessions.isNotEmpty()) {
                                TextButton(onClick = onOpenMessages) { Text("Mensajes") }
                            }
                            HomeProfileButton(
                                overview?.profileSettings ?: ProfileSettings(),
                                onOpenSettings
                            )
                        }
                    }
                )
                WeekCalendarStrip(
                    selectedDay,
                    overview?.trainingSettings?.weekStartsOnMonday ?: true,
                    overview?.dayWorkoutCounts.orEmpty().filterValues { it > 0 }.keys,
                    returnToDay = java.time.LocalDate.now()
                ) { homeDateIso = it.toString() }

                val day = selectedDay
                val dayRoutines = overview?.routineEntries.orEmpty().filter {
                    (overview?.trainingSettings?.scheduleMode == "rotation" &&
                        it.id == overview.rotationPlan?.nextRoutineId) ||
                        (overview?.trainingSettings?.scheduleMode != "rotation" &&
                            (it.scheduledDate == day.toString() ||
                                (it.scheduledDate == null &&
                                    it.weekday == day.dayOfWeek.value)))
                }
                val visibleRoutines = HomePlannedFilter.visible(
                    dayRoutines, { it.id },
                    HomePlannedFilter.completedRoutineIds(
                        overview?.completeHistory.orEmpty(), day
                    ),
                    activeWorkout?.routineId, day, LocalDate.now()
                )
                val dayWorkouts = overview?.completeHistory.orEmpty().filter { entry ->
                    entry.startedAtIso?.let { BodyWeightHistory.day(it) } == day
                }.sortedBy { it.startedAtIso ?: "" }
                val dayExternal = overview?.externalHealthHistory.orEmpty().filter { entry ->
                    java.time.Instant.ofEpochMilli(entry.startMillis)
                        .atZone(java.time.ZoneId.systemDefault()).toLocalDate() == day
                }

                Column(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    dayWorkouts.forEach { workout ->
                        var expanded by rememberSaveable(workout.id) { mutableStateOf(false) }
                        HomeSwipeRevealCard(
                            key = workout.id,
                            busy = busy,
                            onDelete = { onDeleteWorkout(workout.id) },
                            onEdit = if (workout.timerDetails == null)
                                ({ expanded = true }) else null
                        ) {
                            HomeCompletedWorkoutCard(workout, day) { expanded = !expanded }
                        }
                        if (expanded) {
                            WorkoutHistoryCard(
                                workout, busy,
                                onReviseFinishedSet, onDeleteFinishedSet,
                                onDeleteWorkout, onOpenExerciseFromSession,
                                accountId, overview?.exerciseEntries.orEmpty(),
                                onUpdateFinishedWorkout,
                                heartSeriesProvider,
                                effortUnit = overview?.trainingSettings?.effortUnit ?: "rir"
                            )
                        }
                    }
                    dayExternal.forEach { entry ->
                        HomeDayRegisterCard(
                            caption = homeDayTimeCaption(
                                day,
                                java.time.format.DateTimeFormatter.ofPattern("H:mm")
                                    .withZone(java.time.ZoneId.systemDefault())
                                    .format(java.time.Instant.ofEpochMilli(entry.startMillis))
                            ),
                            title = entry.title,
                            leadingIcon = Icons.AutoMirrored.Outlined.DirectionsWalk,
                            chips = listOf(
                                Icons.Outlined.Schedule to "${entry.minutes.toInt()} min"
                            ),
                            onClick = { }
                        )
                    }
                    visibleRoutines.forEach { routine ->
                        var preview by rememberSaveable(routine.id) { mutableStateOf(false) }
                        HomeSwipeRevealCard(
                            key = routine.id,
                            busy = busy,
                            onDelete = { onRemoveScheduledRoutine(routine.id) },
                            onEdit = {
                                preview = false
                                onEditRoutineContent(routine.id)
                            }
                        ) {
                            HomePlannedRoutineCard(routine, day) { preview = true }
                        }
                        if (preview) {
                            @OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
                            ReperaModalBottomSheet(onDismissRequest = { preview = false }) {
                                SessionPreviewSheet(
                                    routine = routine,
                                    busy = busy,
                                    onStart = { onStartRoutine(routine.id) },
                                    onEdit = {
                                        preview = false
                                        onEditRoutineContent(routine.id)
                                    },
                                    onDelete = {
                                        preview = false
                                        onRemoveScheduledRoutine(routine.id)
                                    },
                                    onClose = { preview = false },
                                    onOpenExercise = onOpenExercise
                                )
                            }
                        }
                    }
                    professionalSessions.filter { it.scheduledDate == homeDateIso }.forEach { session ->
                        ProfessionalSessionCard(session, centerName(session.orgId), true)
                    }
                    if (activeWorkout == null && dayWorkouts.isEmpty() && visibleRoutines.isEmpty()
                        && dayExternal.isEmpty()
                        && professionalSessions.none { it.scheduledDate == homeDateIso }
                    ) {
                        HomeEmptyDayCard(day)
                    }
                    if (activeWorkout == null) {
                        androidx.compose.foundation.layout.Spacer(
                            modifier = Modifier.padding(top = 4.dp)
                        )
                        HomeAddWorkoutButton(enabled = !busy) { showDayPlus = true }
                    }
                    if (showDayPlus) {
                        val dayName = day.dayOfWeek.getDisplayName(
                            java.time.format.TextStyle.FULL,
                            java.util.Locale("es")
                        ).replaceFirstChar { it.uppercase() }
                        DayPlusSheet(
                            dayName = dayName,
                            favoriteRoutines = overview?.routineEntries.orEmpty()
                                .count { it.isFavorite },
                            favoriteTimers = overview?.favoriteTimerCount ?: 0,
                            onCreateWorkout = {
                                showDayPlus = false; onDayPlusCreate(homeDateIso, dayName)
                            },
                            onOpenFavorites = {
                                showDayPlus = false; onDayPlusFavorites(homeDateIso)
                            },
                            onOpenTimer = { showDayPlus = false; onDayPlusTimer() },
                            onScanBoard = { showDayPlus = false; onDayPlusScan(homeDateIso) },
                            onDismiss = { showDayPlus = false })
                    }
                }
            }
        }

        // Banda gris iOS (OG.bg): progreso semanal + actividad + recuperación
        item {
            val days = dev.repera.domain.WeeklyWorkoutProgress.days(
                selectedDay,
                overview?.trainingSettings?.weekStartsOnMonday ?: true,
                overview?.dayWorkoutCounts.orEmpty(),
                overview?.routineEntries.orEmpty().map { routine ->
                    dev.repera.domain.WeeklyWorkoutProgress.Plan(
                        routine.scheduledDate?.let {
                            runCatching { LocalDate.parse(it.take(10)) }.getOrNull()
                        },
                        routine.weekday
                    )
                }
            )
            val energy = dayHealth?.activeKcal ?: overview?.dayEnergyKcal?.get(selectedDay)
            val minutes = overview?.dayWorkoutMinutes?.get(selectedDay)
            val healthPlaceholder = when (healthAccess) {
                HealthAccessState.NOT_GRANTED -> "Conecta Salud"
                HealthAccessState.UNAVAILABLE -> "Salud no disponible"
                HealthAccessState.GRANTED -> "Sin datos"
                HealthAccessState.UNKNOWN -> "—"
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.background)
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                AdaptiveCardPair(
                    first = {
                        if (overview != null)
                            HomeWeeklyProgressCard(days, overview.healthGoals.weeklyWorkouts)
                        else Text("Progreso semanal: sin datos locales")
                    },
                    second = {
                        HomeActivityTodayCard(
                            isToday = selectedDay == LocalDate.now(),
                            steps = dayHealth?.steps,
                            stepsGoal = overview?.healthGoals?.steps,
                            energyKcal = energy,
                            energyGoal = overview?.healthGoals?.energyKcal,
                            minutes = minutes,
                            minutesGoal = overview?.healthGoals?.minutes,
                            healthPlaceholder = healthPlaceholder,
                            onHealthConnect = onHealthConnect,
                            healthAccess = healthAccess
                        )
                    },
                    outerHorizontalPaddingDp = 32f
                )
                overview?.recovery?.takeIf { selectedDay == LocalDate.now() }?.let { recovery ->
                    HomeRecoveryModel.of(
                        recovery.lastNightHours, recovery.sleepIndex,
                        recovery.menstrualDays, LocalDate.now()
                    )?.let { model ->
                        ReperaCard(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp)) {
                                Text(
                                    "Tu estado de hoy",
                                    style = MaterialTheme.typography.titleMedium
                                )
                                model.sleepHours?.let {
                                    Text(
                                        "${dev.repera.domain.ReperaNumberFormat.decimal(it)} h de sueño"
                                    )
                                }
                                model.sleepIndexOutOf10?.let { Text("Índice de sueño: $it/10") }
                                model.cycleLabel?.let { Text(it) }
                                TextButton(onClick = onOpenRecoverySettings) {
                                    Text("Ver Salud y recuperación")
                                }
                            }
                        }
                    }
                }
            }
        }

        item {
            if (activeWorkout != null) {
                key(activeWorkout.id, activeWorkout.index, activeWorkout.completedSets) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(MaterialTheme.colorScheme.background)
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        var showBlockTimer by remember(activeWorkout.id, activeWorkout.index) {
                            mutableStateOf(false)
                        }
                        if (showBlockTimer) {
                            val rounds = (activeWorkout.wod?.rounds
                                ?: activeWorkout.prescribedQuantity ?: 3).coerceAtLeast(1)
                            BlockTimerConfigSheet(
                                rounds = rounds,
                                initialWorkSeconds = activeWorkout.wod?.workSeconds ?: 60,
                                initialRestSeconds = activeWorkout.wod?.restSeconds
                                    ?: activeWorkout.wod?.restBetweenRoundsSeconds ?: 0,
                                onDismiss = { showBlockTimer = false },
                                onStart = { _, _ ->
                                    showBlockTimer = false
                                    onWodTimerAction("start")
                                    onOpenClock()
                                }
                            )
                        }
                        ActiveSessionControls(
                            active = activeWorkout,
                            busy = busy,
                            onSelect = onSelectActiveExercise,
                            onNotes = onUpdateActiveNotes,
                            onFavorite = onSaveActiveFavorite,
                            onEdit = onEditActivePlan,
                            onDiscard = onDiscardSession,
                            onConfigureBlockTimer = { showBlockTimer = true },
                            accountId = accountId
                        )
                        if (activeWorkout.wod != null) {
                            WodScoreCard(
                                active = activeWorkout,
                                busy = busy,
                                timer = wodTimer,
                                onTimerAction = onWodTimerAction,
                                onTimerTick = onWodTimerTick,
                                onSave = onWodScore,
                                onMovement = onWodMovement,
                                onCompleteBlock = onCompleteWodBlock,
                                onReviseMovement = onReviseWodMovement,
                                onDeleteMovement = onDeleteWodMovement,
                                onFinish = onFinish,
                                onDiscard = onDiscardSession,
                                onOpenClock = onOpenClock
                            )
                        } else {
                            ActiveWorkoutCard(
                                effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
                                weightUnit = overview?.trainingSettings?.weightUnit ?: "kg",
                                active = activeWorkout,
                                busy = busy,
                                onLogSet = onLogSet,
                                onLogDropSet = onLogDropSet,
                                onLogRestPauseSet = onLogRestPauseSet,
                                onReviseSet = onReviseSet,
                                onDeleteSet = onDeleteSet,
                                onNext = onNext,
                                onFinish = onFinish,
                                onDiscard = onDiscardSession
                            )
                        }
                        // Mapa full-bleed sin padding cuando hay pin; chip = lugar.
                        val activePin = overview?.activeLocationPin
                        ReperaCard(modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
                            if (activePin != null) {
                                WorkoutPlacePickerRow(
                                    pin = activePin,
                                    accountId = accountId,
                                    onPinChange = onActivePinChange
                                )
                            } else {
                                Column(Modifier.padding(16.dp)) {
                                    Text("Lugar", style = MaterialTheme.typography.titleMedium)
                                    WorkoutPlacePickerRow(
                                        pin = null,
                                        accountId = accountId,
                                        onPinChange = onActivePinChange
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        if (overview == null) {
            item {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.background)
                        .padding(horizontal = 16.dp)
                ) {
                    OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson)
                }
            }
        }
    }
    }
}
