package dev.repera.mobile

import androidx.compose.ui.res.stringResource
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
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Layers
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.platform.testTag
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
    wearTimerMirror: org.json.JSONObject? = null,
    onWearTimerCommand: (String) -> Unit = {},
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
    onSubstituteActiveExercise: (ExerciseEntry) -> Unit = {},
    onRemoveActiveExercise: () -> Unit = {},
    onEditActivePlan:()->Unit = {},
    clockMinimized: Boolean = false,
    onExpandClock: () -> Unit = {},
    onOpenActiveSession: () -> Unit = {},
    /** Continuar actividad Comenzar (en-vivo). */
    onOpenLiveActivity: () -> Unit = {},
    onFinish: () -> Unit,
    onDiscardSession: () -> Unit = {},
    accountId: String = "",
    onUpdateFinishedWorkout: (
        String,
        WorkoutRepository.FinishedWorkoutEdit,
        List<RoutineBlockDraft>?
    ) -> Unit = { _, _, _ -> },
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
    /** R5 P1-9: detalle de rutina a pantalla completa. */
    onOpenRoutinePreview: (String) -> Unit = {},
    /** R5 P1-10: resumen terminado a pantalla completa. */
    onOpenFinishedWorkout: (String) -> Unit = {},
    /** Swipe Editar → editor tipo crear (historial-editar), no solo el detalle. */
    onEditFinishedWorkout: (String) -> Unit = onOpenFinishedWorkout,
    onSetRoutineFavorite: (String, Boolean) -> Unit = { _, _ -> },
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
    centerSnapshot: BusinessCenterStore.Snapshot? = null,
    centerSubmitting: Boolean = false,
    loadClassRoster: (suspend (String) -> BusinessCenterStore.ClassRoster?)? = null,
    onBookClass: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit = { _, _ -> },
    onCancelClassBooking: (BusinessCenterStore.Booking) -> Unit = {},
    onStartClassPlan: (BusinessCenterStore.ProfessionalSession) -> Unit = {},
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
    centerName:(String)->String = {"Centro"},
    onOpenMessages:()->Unit = {},
    onOpenHistory:()->Unit = {},
    onOpenRecoverySettings:()->Unit = {},
    onOpenSettings:()->Unit = {},
    dayHealthProvider:suspend (java.time.LocalDate)->TodayHealth? = {null}
) {
    var homeDateIso by rememberSaveable { mutableStateOf(LocalDate.now().toString()) }
    var showDayPlus by rememberSaveable(accountId) { mutableStateOf(false) }
    var detailOccurrence by remember {
        mutableStateOf<BusinessCenterStore.Occurrence?>(null)
    }
    var pendingClassCancellation by remember {
        mutableStateOf<BusinessCenterStore.Booking?>(null)
    }
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
        contentPadding = PaddingValues(bottom = LocalReperaTabBarInset.current + 12.dp),
        verticalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        // Banda blanca iOS: topbar + calendario + cards del día + CTA
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surface)
                    .statusBarsPadding()
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
                                TextButton(onClick = onOpenMessages) { Text(stringResource(R.string.home_tab_mensajes)) }
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
                val dayBookingsEarly = remember(centerSnapshot, homeDateIso) {
                    val snap = centerSnapshot ?: return@remember emptyList()
                    val zone = java.time.ZoneId.systemDefault()
                    snap.bookings.mapNotNull { booking ->
                        if (booking.status != "booked" && booking.status != "waitlist") {
                            return@mapNotNull null
                        }
                        val occ = snap.occurrences.firstOrNull { it.id == booking.occurrenceId }
                            ?: return@mapNotNull null
                        val occDay = runCatching {
                            java.time.Instant.parse(occ.startsAt).atZone(zone).toLocalDate()
                        }.getOrNull() ?: return@mapNotNull null
                        if (occDay.toString() != homeDateIso) return@mapNotNull null
                        booking to occ
                    }
                }
                val classPlanIds = remember(dayBookingsEarly, centerSnapshot) {
                    buildSet {
                        dayBookingsEarly.forEach { (booking, occ) ->
                            if (occ.kind != "class") return@forEach
                            add(occ.id)
                            centerSnapshot?.classTrainingSession(occ.id, booking.clientId)
                                ?.id?.let { add(it) }
                        }
                    }
                }
                val visibleRoutines = HomePlannedFilter.visible(
                    dayRoutines, { it.id },
                    HomePlannedFilter.completedRoutineIds(
                        overview?.completeHistory.orEmpty(), day
                    ),
                    activeWorkout?.routineId, day, LocalDate.now()
                ).filter { it.id !in classPlanIds }
                val dayWorkouts = overview?.completeHistory.orEmpty().filter { entry ->
                    entry.startedAtIso?.let { BodyWeightHistory.day(it) } == day
                }.sortedBy { it.startedAtIso ?: "" }
                val completedRoutineIds = dayWorkouts.mapNotNull { it.routineId }.toSet()
                val dayExternal = overview?.externalHealthHistory.orEmpty().filter { entry ->
                    java.time.Instant.ofEpochMilli(entry.startMillis)
                        .atZone(java.time.ZoneId.systemDefault()).toLocalDate() == day
                }

                Column(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    // En curso (fuerza o Comenzar) sustituye el icono verde por play ámbar.
                    val isToday = day == LocalDate.now()
                    val homeContext = androidx.compose.ui.platform.LocalContext.current
                    val livePending = isToday && accountId.isNotBlank() &&
                        LiveActivityRuntime.hasPendingActivity(homeContext, accountId)
                    val liveTitle = if (livePending && accountId.isNotBlank()) {
                        runCatching {
                            LiveActivityRuntime.forAccount(homeContext, accountId).state.sport.title
                        }.getOrNull() ?: "Actividad en vivo"
                    } else "Actividad en vivo"
                    if (isToday && activeWorkout != null) {
                        HomeInProgressCard(
                            title = activeWorkout.exerciseName.ifBlank {
                                activeWorkout.title.ifBlank { "Entreno" }
                            },
                            subtitle = "${activeWorkout.index + 1}/${activeWorkout.total}",
                            onClick = onOpenActiveSession
                        )
                    } else if (livePending) {
                        HomeInProgressCard(
                            title = liveTitle,
                            subtitle = stringResource(R.string.tab_start),
                            onClick = onOpenLiveActivity
                        )
                    }
                    if (isToday && wearTimerMirror != null) {
                        WearLiveTimerHomeCard(wearTimerMirror, onWearTimerCommand)
                    }
                    val reviewDismissContext = LocalContext.current
                    var dismissedReviewIds by remember(accountId) {
                        mutableStateOf(
                            HomeReviewActionDismissals.load(reviewDismissContext, accountId)
                        )
                    }
                    fun acknowledgeReviewActions(workoutId: String) {
                        val next = dismissedReviewIds + workoutId
                        dismissedReviewIds = next
                        HomeReviewActionDismissals.save(
                            reviewDismissContext, next, accountId
                        )
                    }
                    dayWorkouts.forEach { workout ->
                        val showActions =
                            workout.timerDetails == null && workout.id !in dismissedReviewIds
                        HomeSwipeRevealCard(
                            key = workout.id,
                            busy = busy,
                            onDelete = { onDeleteWorkout(workout.id) },
                            // Swipe Editar → misma página de crear/editar (historial-editar).
                            onEdit = if (workout.timerDetails == null)
                                ({ onEditFinishedWorkout(workout.id) }) else null
                        ) {
                            HomeCompletedWorkoutCard(
                                workout = workout,
                                day = day,
                                prCount = overview?.prCountBySessionId?.get(workout.id) ?: 0,
                                onClick = { onOpenFinishedWorkout(workout.id) },
                                showReviewActions = showActions,
                                onDiscardActions = { acknowledgeReviewActions(workout.id) },
                                onReview = {
                                    acknowledgeReviewActions(workout.id)
                                    onEditFinishedWorkout(workout.id)
                                }
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
                        HomeSwipeRevealCard(
                            key = routine.id,
                            busy = busy,
                            onDelete = { onRemoveScheduledRoutine(routine.id) },
                            onEdit = { onEditRoutineContent(routine.id) }
                        ) {
                            HomePlannedRoutineCard(routine, day) {
                                onOpenRoutinePreview(routine.id)
                            }
                        }
                    }
                    val dayBookings = dayBookingsEarly
                    // Fan-out de clase: solo con reserva; la ficha la pinta el booking.
                    val dayProfessional = professionalSessions.filter { session ->
                        session.scheduledDate == homeDateIso &&
                            session.sourceOccurrenceId == null
                    }
                    dayProfessional.forEach { session ->
                        val center = centerName(session.orgId)
                        val time = session.scheduledTimeMinutes?.let {
                            "%d:%02d".format(java.util.Locale.ROOT, it / 60, it % 60)
                        }
                        val caption = buildString {
                            append(homeDayTimeCaption(day, time))
                            if (center.isNotBlank()) {
                                append(" · ")
                                append(center)
                            }
                        }
                        val planBlocks = session.prescription
                            ?.let { prescriptionToRoutineBlocks(it) }
                            .orEmpty()
                        val isClassPlan = session.sourceOccurrenceId != null
                        val chips = buildList {
                            add(
                                (if (isClassPlan) Icons.Outlined.Groups else Icons.Outlined.Person) to
                                    (if (isClassPlan) "Clase" else "Entrenador")
                            )
                            if (planBlocks.isNotEmpty()) {
                                add(Icons.Outlined.Layers to "${planBlocks.size} bloq.")
                                planBlocks.firstOrNull { it.format.isNotBlank() }?.let { block ->
                                    add(Icons.Outlined.Timer to homeWodChipLabel(block))
                                }
                            }
                        }
                        HomeDayRegisterCard(
                            caption = caption,
                            title = session.title,
                            leadingIcon = Icons.Outlined.FitnessCenter,
                            chips = chips,
                            onClick = { onStartClassPlan(session) },
                            leadingIconTint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    dayBookings.forEach { (booking, occurrence) ->
                        val isClass = occurrence.kind == "class"
                        val center = centerName(occurrence.orgId)
                        val time = homeTimeFromIso(occurrence.startsAt)
                        val caption = buildString {
                            append(homeDayTimeCaption(day, time))
                            if (isClass && center.isNotBlank()) {
                                append(" · ")
                                append(center)
                            }
                        }
                        val session = if (isClass) {
                            centerSnapshot?.asClassPlanSession(occurrence, booking.clientId)
                        } else null
                        val planBlocks = session?.prescription
                            ?.let { prescriptionToRoutineBlocks(it) }
                            .orEmpty()
                        val planId = session?.id
                        val planDone = planId != null && planId in completedRoutineIds
                        // Terminada: solo el resumen de workout (arriba). Sin ficha pendiente.
                        if (isClass && planDone) return@forEach
                        val chips = when {
                            !isClass -> listOf(Icons.Outlined.FitnessCenter to "Cita confirmada")
                            planBlocks.isNotEmpty() -> buildList {
                                add(Icons.Outlined.Groups to "Clase")
                                add(Icons.Outlined.Layers to "${planBlocks.size} bloq.")
                                planBlocks.firstOrNull { it.format.isNotBlank() }?.let {
                                    add(Icons.Outlined.Timer to homeWodChipLabel(it))
                                }
                            }
                            else -> listOf(Icons.Outlined.FitnessCenter to "Reserva confirmada")
                        }
                        val title = when {
                            !isClass || planBlocks.isEmpty() -> occurrence.title
                            !session?.title.isNullOrBlank() -> session!!.title
                            else -> occurrence.title
                        }
                        val card = @Composable {
                            HomeDayRegisterCard(
                                caption = caption,
                                title = title,
                                leadingIcon = Icons.Outlined.FitnessCenter,
                                chips = chips,
                                onClick = { detailOccurrence = occurrence },
                                leadingIconTint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        // Plan del centro: sin editar; swipe = cancelar reserva.
                        if (isClass && planBlocks.isNotEmpty()) {
                            HomeSwipeRevealCard(
                                key = booking.id,
                                busy = busy,
                                onDelete = { pendingClassCancellation = booking },
                                onEdit = null,
                                deleteContentDescription = "Cancelar reserva de clase",
                                askDeleteConfirm = false
                            ) { card() }
                        } else {
                            card()
                        }
                    }
                    if (activeWorkout == null && wearTimerMirror == null && dayWorkouts.isEmpty() && visibleRoutines.isEmpty()
                        && dayExternal.isEmpty()
                        && dayProfessional.isEmpty()
                        && dayBookings.isEmpty()
                    ) {
                        HomeEmptyDayCard(day)
                    }
                    if (activeWorkout == null) {
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
                        HomeWeeklyProgressCard(
                            days,
                            overview?.healthGoals?.weeklyWorkouts
                        )
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
                                    stringResource(R.string.home_tab_tu_estado_de_hoy),
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
                                    Text(stringResource(R.string.home_tab_ver_salud_y_recuperacion))
                                }
                            }
                        }
                    }
                }
            }
        }

        // Play / Comenzar en curso: solo ficha EN CURSO arriba + Continuar sobre el menú.
    }
    }

    val zone = remember { java.time.ZoneId.systemDefault() }
    val es = remember { java.util.Locale("es", "ES") }
    val dayFmt = remember {
        java.time.format.DateTimeFormatter.ofPattern("H:mm", es).withZone(zone)
    }
    val dateFmt = remember {
        java.time.format.DateTimeFormatter.ofPattern("EEEE d MMM", es).withZone(zone)
    }
    detailOccurrence?.let { occurrence ->
        ClassDetailPage(
            occurrence = occurrence,
            snapshot = centerSnapshot,
            dayFmt = dayFmt,
            submitting = centerSubmitting,
            loadRoster = loadClassRoster,
            onBook = onBookClass,
            onRequestCancel = { pendingClassCancellation = it },
            onStartClassPlan = onStartClassPlan,
            exerciseCatalog = exerciseCatalog,
            onOpenExercise = onOpenExercise,
            onClose = { detailOccurrence = null }
        )
    }
    pendingClassCancellation?.let { booking ->
        ReperaConfirmSheet(
            title = stringResource(R.string.center_cancel_title),
            message = stringResource(R.string.plus_hub_tab_se_te_desapunta_y_si_tenias),
            confirmTitle = stringResource(R.string.center_cancel_confirm),
            onConfirm = {
                pendingClassCancellation = null
                onCancelClassBooking(booking)
            },
            onCancel = { pendingClassCancellation = null },
            icon = Icons.Outlined.EventBusy,
            confirmDestructive = true
        )
    }
}


/** Tarjeta de temporizador del reloj: sin GPS/Health ficticios y sin doble contador. */
@Composable
private fun WearLiveTimerHomeCard(
    mirror: org.json.JSONObject,
    onCommand: (String) -> Unit
) {
    val id = mirror.optString("id")
    var now by remember(id) { mutableStateOf(System.currentTimeMillis()) }
    LaunchedEffect(id) {
        while (true) {
            delay(1_000)
            now = System.currentTimeMillis()
        }
    }
    val age = now - mirror.optLong("updatedAtMillis", 0L)
    val fresh = age in 0..20_000L
    val running = mirror.optString("phase") == "running"
    val configured = mirror.optInt("configuredSeconds", 1).coerceAtLeast(1)
    val elapsed = mirror.optInt("elapsedSeconds", 0).coerceAtLeast(0)
    val shown = (elapsed + if (running) (age / 1_000L).toInt().coerceIn(0, 15) else 0)
        .coerceIn(0, configured)
    val mode = when (mirror.optString("modeRaw")) {
        "intervals" -> "Intervalos"
        "down" -> "Cuenta atrás"
        else -> "Cronómetro"
    }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(stringResource(R.string.home_tab_temporizador_wear_os), style = MaterialTheme.typography.titleSmall)
                Text(if (running) "En curso" else "En pausa",
                    style = MaterialTheme.typography.labelSmall)
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(mode, style = MaterialTheme.typography.labelMedium)
                    Text(
                        "%d:%02d".format(java.util.Locale.ROOT, shown / 60, shown % 60),
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.reperaColors.timerRed
                    )
                }
                if (mode == "Intervalos") {
                    Text("Ronda " + mirror.optInt("round", 1),
                        color = MaterialTheme.reperaColors.timerGreen,
                        style = MaterialTheme.typography.labelLarge)
                }
            }
            if (!fresh) {
                Text(stringResource(R.string.home_tab_sin_conexion_reciente_con_el_reloj),
                    style = MaterialTheme.typography.labelSmall)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = { onCommand(if (running) "pause" else "resume") },
                    enabled = fresh
                ) { Text(if (running) "Pausar" else "Reanudar") }
                OutlinedButton(onClick = { onCommand("finish") }, enabled = fresh) {
                    Text(stringResource(R.string.home_tab_finalizar))
                }
            }
        }
    }
}
