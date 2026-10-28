package dev.repera.mobile

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
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
    // «＋» del día seleccionado (DayPlusSheet iOS desde HomeView, c5aae1cc).
    onDayPlusCreate: (String, String) -> Unit = { _, _ -> },
    onDayPlusFavorites: () -> Unit = {},
    onDayPlusTimer: () -> Unit = {},
    /** ISO day (`yyyy-MM-dd`) selected when opening the board scanner. */
    onDayPlusScan: (String) -> Unit = {},
    onDeleteRoutine: (String) -> Unit = {},
    onRemoveScheduledRoutine: (String) -> Unit = onDeleteRoutine,
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
    val selectedDay=LocalDate.parse(homeDateIso)
    var selectedHealth by remember(selectedDay) {mutableStateOf<TodayHealth?>(null)}
    LaunchedEffect(selectedDay,todayHealth,overview?.dayEnergyKcal) {selectedHealth=dayHealthProvider(selectedDay)}
    val dayHealth=selectedHealth ?: todayHealth.takeIf {selectedDay==LocalDate.now()}
    val weekStart=dev.repera.domain.StatsEngine.startOfWeek(selectedDay,overview?.trainingSettings?.weekStartsOnMonday ?: true)
    val selectedWeekCount=(0L..6L).sumOf {overview?.dayWorkoutCounts?.get(weekStart.plusDays(it)) ?: 0}
    val dragListState = androidx.compose.foundation.lazy.rememberLazyListState()
    ProvideLazyDragAutoScroll(dragListState) {
    LazyColumn(
        state = dragListState,
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            // Paridad HomeView: ogFixedTopBar("repera", subtitle: fecha) + avatar.
            val dateSubtitle = java.time.LocalDate.now().format(
                java.time.format.DateTimeFormatter.ofPattern("EEEE d MMMM", java.util.Locale("es", "ES"))
            ).replaceFirstChar { it.uppercase() }
            Column {
                ReperaPageHeader(
                    title = "repera",
                    subtitle = dateSubtitle,
                    trailing = {
                        HomeProfileButton(overview?.profileSettings ?: ProfileSettings(), onOpenSettings)
                    }
                )
                Text(
                    "Hola, " + (displayName ?: "Deportista"),
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                TextButton(onClick = onOpenMessages) { Text("Mensajes con centro o entrenador") }
            }
        }
        item {
            val day = LocalDate.parse(homeDateIso)
            val dayRoutines = overview?.routineEntries.orEmpty().filter {
                (overview?.trainingSettings?.scheduleMode=="rotation" && it.id==overview.rotationPlan?.nextRoutineId) ||
                    (overview?.trainingSettings?.scheduleMode!="rotation" && (it.scheduledDate == day.toString() ||
                    (it.scheduledDate == null && it.weekday == day.dayOfWeek.value)))
            }
            val visibleRoutines = HomePlannedFilter.visible(dayRoutines, { it.id },
                HomePlannedFilter.completedRoutineIds(overview?.completeHistory.orEmpty(), day), activeWorkout?.routineId, day, LocalDate.now())
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Calendario y entrenamientos",
                        style = MaterialTheme.typography.titleLarge)
                    WeekCalendarStrip(day,overview?.trainingSettings?.weekStartsOnMonday ?: true,
                        overview?.dayWorkoutCounts.orEmpty().filterValues {it>0}.keys) { homeDateIso = it.toString() }
                    Text("Entrenamientos · " + day.format(reperaDayFormatter),
                        style = MaterialTheme.typography.titleMedium)
                    if (visibleRoutines.isEmpty()) {
                        // Paridad iOS emptyWorkoutCard: icono + título + subtítulo día libre.
                        ReperaEmptyState(
                            title = "Sin entrenamientos programados",
                            subtitle = "Día libre · puedes añadir un entrenamiento",
                            icon = Icons.Outlined.EventBusy,
                            contentDescription = null
                        )
                    } else visibleRoutines.forEach { routine ->
                        // Tocar abre el resumen del plan (SessionPreviewView iOS);
                        // el Play dentro de la hoja sí inicia la sesión.
                        var preview by rememberSaveable(routine.id) { mutableStateOf(false) }
                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(routine.title, style = MaterialTheme.typography.bodyLarge)
                            TextButton(onClick = { preview = true },
                                enabled = !busy && activeWorkout == null) {
                                Text("Ver plan y empezar")
                            }
                        }
                        if (preview) {
                            @OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
                            ReperaModalBottomSheet(
                                onDismissRequest = { preview = false }
                            ) {
                                SessionPreviewSheet(
                                    routine = routine,
                                    busy = busy,
                                    onStart = { onStartRoutine(routine.id) },
                                    onEdit = { onNavigateCreate() },
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
                    // Apple 160f304c: la acción de añadir va separada de las
                    // tarjetas diarias (8dp extra sobre el espaciado de la columna).
                    Button(onClick = { showDayPlus = true },
                        enabled = !busy,
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                        colors = reperaPrimaryButtonColors()
                    ) { Text("Añadir nuevo entrenamiento") }
                    if (showDayPlus) {
                        val dayName = day.dayOfWeek.getDisplayName(java.time.format.TextStyle.FULL,
                            java.util.Locale("es")).replaceFirstChar { it.uppercase() }
                        DayPlusSheet(
                            dayName = dayName,
                            favoriteRoutines = overview?.routineEntries.orEmpty().count { it.isFavorite },
                            favoriteTimers = overview?.favoriteTimerCount ?: 0,
                            onCreateWorkout = { showDayPlus = false; onDayPlusCreate(homeDateIso, dayName) },
                            onOpenFavorites = { showDayPlus = false; onDayPlusFavorites() },
                            onOpenTimer = { showDayPlus = false; onDayPlusTimer() },
                            onScanBoard = { showDayPlus = false; onDayPlusScan(homeDateIso) },
                            onDismiss = { showDayPlus = false })
                    }
                }
            }
        }
        item {
            val days=dev.repera.domain.WeeklyWorkoutProgress.days(selectedDay,
                overview?.trainingSettings?.weekStartsOnMonday ?: true,
                overview?.dayWorkoutCounts.orEmpty(),overview?.routineEntries.orEmpty().map {routine ->
                    dev.repera.domain.WeeklyWorkoutProgress.Plan(
                        routine.scheduledDate?.let {runCatching {LocalDate.parse(it.take(10))}.getOrNull()},routine.weekday)
                })
            val activityContent: @Composable () -> Unit = {
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text("Actividad · ${selectedDay.format(reperaDayFormatter)}", style = MaterialTheme.typography.titleMedium)
                    val healthPlaceholder = when (healthAccess) {
                        HealthAccessState.NOT_GRANTED -> "Conecta Salud"
                        HealthAccessState.UNAVAILABLE -> "Salud no disponible"
                        HealthAccessState.GRANTED -> "Sin datos"
                        HealthAccessState.UNKNOWN -> "—"
                    }
                    Text("Pasos: " + (dayHealth?.steps?.toString() ?: healthPlaceholder))
                    val energy=dayHealth?.activeKcal ?: overview?.dayEnergyKcal?.get(selectedDay)
                    Text("Energía activa: " + (energy?.let {"${it.toInt()} kcal"} ?: healthPlaceholder))
                    val minutes=overview?.dayWorkoutMinutes?.get(selectedDay)
                    Text("Tiempo de entreno: " + (minutes?.let {"${it.toInt()} min"} ?: "—"))
                    overview?.healthGoals?.let { goals ->
                        goals.steps?.let {target -> Text("Objetivo pasos: ${dayHealth?.steps?.let {"${dev.repera.domain.ReperaNumberFormat.integer(it.toInt())} / ${dev.repera.domain.ReperaNumberFormat.integer(target)}"} ?: "$healthPlaceholder / ${dev.repera.domain.ReperaNumberFormat.integer(target)}"}")}
                        goals.energyKcal?.let {target -> Text("Objetivo energía: ${energy?.let {"${dev.repera.domain.ReperaNumberFormat.integer(it.toInt())} / ${dev.repera.domain.ReperaNumberFormat.integer(target)} kcal"} ?: "$healthPlaceholder / ${dev.repera.domain.ReperaNumberFormat.integer(target)} kcal"}")}
                        goals.minutes?.let {target -> Text("Objetivo tiempo: ${minutes?.let {"${dev.repera.domain.ReperaNumberFormat.integer(it.toInt())} / ${dev.repera.domain.ReperaNumberFormat.integer(target)} min"} ?: "Sin datos / ${dev.repera.domain.ReperaNumberFormat.integer(target)} min"}")}
                        goals.weeklyWorkouts?.let {target -> Text("Objetivo semanal: $selectedWeekCount / $target entrenamientos")}
                    }
                    TextButton(
                        enabled = !busy,
                        onClick = onHealthConnect
                    ) {
                        Text(
                            when (healthAccess) {
                                HealthAccessState.GRANTED -> "Actualizar Salud"
                                HealthAccessState.NOT_GRANTED -> "Conectar Salud"
                                HealthAccessState.UNAVAILABLE -> "Salud no disponible en este dispositivo"
                                HealthAccessState.UNKNOWN -> "Conectar o actualizar Salud"
                            }
                        )
                    }
                }
            }
            }
            AdaptiveCardPair(
                first={
                    if(overview!=null) HomeWeeklyProgressCard(days,overview.healthGoals.weeklyWorkouts)
                    else Text("Progreso semanal: sin datos locales")
                },second=activityContent)
        }
        overview?.recovery?.takeIf {selectedDay==LocalDate.now()}?.let {recovery ->
            HomeRecoveryModel.of(recovery.lastNightHours,recovery.sleepIndex,recovery.menstrualDays,LocalDate.now())?.let {model ->
                item {
                    ReperaCard(modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp)) {
                            Text("Tu estado de hoy", style = MaterialTheme.typography.titleMedium)
                            model.sleepHours?.let {
                                Text("${dev.repera.domain.ReperaNumberFormat.decimal(it)} h de sueño")
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
        items(professionalSessions.filter {it.scheduledDate==homeDateIso}) {session ->
            ProfessionalSessionCard(session,centerName(session.orgId),true)
        }
        item {
            if (activeWorkout != null) {
                key(activeWorkout.id, activeWorkout.index, activeWorkout.completedSets) {
                Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                    ActiveSessionControls(activeWorkout,busy,onSelectActiveExercise,onUpdateActiveNotes,onSaveActiveFavorite,onEditActivePlan,accountId)
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
                            effortUnit=overview?.trainingSettings?.effortUnit ?: "rir",
                            weightUnit=overview?.trainingSettings?.weightUnit ?: "kg",
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
                    // Sección «Lugar» (WorkoutView iOS): fila + mapa del pin activo.
                    ReperaCard(modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text("Lugar", style = MaterialTheme.typography.titleMedium)
                            WorkoutPlacePickerRow(
                                pin = overview?.activeLocationPin,
                                accountId = accountId,
                                onPinChange = onActivePinChange)
                        }
                    }
                }
                }
            } else {
                ReperaEmptyState(
                    title = "Sin entrenamiento iniciado",
                    subtitle = "Elige un plan del día o añade uno nuevo",
                    icon = Icons.Outlined.FitnessCenter
                )
            }
        }
        item { CountCard("Entrenamientos registrados", overview?.workouts, overview != null) }
        item {TextButton(onClick=onOpenHistory) {Text("Ver historial completo")} }
        item { ReperaSectionTitle("Historial reciente") }
        // Apple 0574e246: en Inicio, los entrenos del dia se leen en orden
        // cronologico (el mas antiguo arriba); el historial global sigue
        // mostrando el mas reciente primero.
        val workouts = overview?.completeHistory.orEmpty().filter {entry ->
            entry.startedAtIso?.let {BodyWeightHistory.day(it)}==selectedDay
        }.sortedBy { it.startedAtIso ?: "" }
        if (workouts.isEmpty()) item {
            ReperaEmptyState(
                title = "Todavía no hay sesiones registradas",
                subtitle = "Cuando completes un entreno aparecerá aquí",
                icon = Icons.Outlined.History
            )
        }
        items(workouts, key = { it.id }) { workout ->
            WorkoutHistoryCard(workout, busy,
                        onReviseFinishedSet, onDeleteFinishedSet,
                        onDeleteWorkout, onOpenExerciseFromSession,
                        accountId, overview?.exerciseEntries.orEmpty(), onUpdateFinishedWorkout,
                        heartSeriesProvider,
                        effortUnit = overview?.trainingSettings?.effortUnit ?: "rir")
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
    }
}
