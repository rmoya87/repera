package dev.repera.mobile

import dev.repera.mobile.monetization.LocalSubscriptions
import android.net.Uri
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.Apartment
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.OutlinedButton
import androidx.compose.foundation.layout.size
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.activity.compose.BackHandler
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.NavType
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController

private data class TabSpec(val route: String, val label: String, val icon: ImageVector)

private val tabs = listOf(
    TabSpec("inicio", "Inicio", Icons.Outlined.Home),
    TabSpec("diario", "Diario", Icons.Outlined.CalendarMonth),
    TabSpec("en-vivo", "Comenzar", Icons.Outlined.AddCircleOutline),
    TabSpec("progreso", "Progreso", Icons.Outlined.TrendingUp),
    TabSpec("ejercicios", "Ejercicios", Icons.Outlined.FitnessCenter)
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReperaMobileScreen(
    isAuthenticated: Boolean,
    displayName: String?,
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    todayHealth: TodayHealth?,
    onHealthConnect: () -> Unit,
    activeWorkout: ActiveWorkout?,
    wodTimer: WodTimerState?,
    onWodTimerAction: (String) -> Unit,
    onWodTimerTick: () -> Unit,
    onStartRoutine: (String) -> Unit,
    onEditRoutine: (String, String, RoutineSchedule) -> Unit,
    onDeleteRoutine: (String) -> Unit,
    onReplaceRoutineBlocks: (String, List<RoutineBlockDraft>) -> Unit,
    onCreateRoutine: (String, String, List<RoutineDraftEntry>, Int, Int,
        RoutineSchedule, Int, Int, Int, List<Int>?) -> Unit,
    onAddWodTemplate: (String) -> Unit,
    onCreateRoutineFromScan: (String, List<dev.repera.domain.RoutineBlock>) -> Unit,
    onSaveOneOffRoutine: (String, List<RoutineBlockDraft>, String) -> Unit = { _, _, _ -> },
    onStartSessionFromDrafts: (String, List<RoutineBlockDraft>, Boolean) -> Unit = { _, _, _ -> },
    centerConnected: Boolean,
    centerLoading: Boolean,
    centerSubmitting: Boolean,
    centerError: String?,
    centerSnapshot: BusinessCenterStore.Snapshot?,
    onCenterRefresh: () -> Unit,
    onCenterAccept: (BusinessCenterStore.Invitation) -> Unit,
    onCenterBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onCenterCancel: (BusinessCenterStore.Booking) -> Unit,
    sharingByCenter: Map<String, Boolean>,
    sharingUpdating: Boolean,
    onSetSharing: (String, Boolean) -> Unit,
    aiPrograms: List<AITrainingProgramsStore.Program>?,
    aiProgramsLoading: Boolean,
    aiProgramsUpdatingId: String?,
    aiProgramsError: String?,
    onAIProgramsRefresh: () -> Unit,
    onAIProgramStatus: (AITrainingProgramsStore.Program, String) -> Unit,
    aiConnected: Boolean,
    aiTokens: List<AIAccessStore.TokenInfo>?,
    aiBusy: Boolean,
    aiError: String?,
    aiSuccess: String?,
    aiCreatedToken: String?,
    aiChanges: List<AIChangeRequestStore.Change>,
    aiChangeBusy: Boolean,
    aiChangeError: String?,
    aiInboxPending: Int,
    aiInboxConflicts: List<String>,
    onAIRefresh: () -> Unit,
    onAICreate: (String, String, Boolean) -> Unit,
    onAIRevoke: (String) -> Unit,
    onAIDecide: (AIChangeRequestStore.Change, Boolean) -> Unit,
    onAIDismissCreated: () -> Unit,
    onAICopyCreated: () -> Unit,
    onWodScore: (Int?, Int?, Int?) -> Unit,
    onWodMovement: (Int, Int, Int, Double?) -> Unit,
    onCompleteWodBlock: () -> Unit,
    onReviseWodMovement: (String, Int, Double?) -> Unit,
    onDeleteWodMovement: (String) -> Unit,
    onQuickLog: (String) -> Unit,
    onInitializeLocal: () -> Unit,
    onLogSet: (Int, Double?, Double?, Boolean, String?, Int?, Int?) -> Unit,
    onLogDropSet: (Int, Double?, List<Pair<Int, Double?>>) -> Unit,
    onLogRestPauseSet: (List<Pair<Int, Int>>, Double?) -> Unit,
    onReviseSet: (String, Int, Double?, String?, Int?, Int?) -> Unit,
    onDeleteSet: (String) -> Unit,
    onReviseFinishedSet: (String, String, String, Int, Double?, Int?) -> Unit,
    exerciseSeries: (String, ExerciseProgressMetric, ExerciseProgressRange) ->
        List<ExerciseProgressPoint> = { _, _, _ -> emptyList() },
    sessionAppearances: (exerciseId: String, highlightSessionId: String,
        instanceId: String?) ->
        Pair<SessionAppearance?, SessionAppearance?> = { _, _, _ -> null to null },
    loadGuideProvider: (exerciseId: String, targetReps: Int, targetRir: Double?) ->
        LoadGuide? = { _, _, _ -> null },
    heartSeriesProvider: suspend (String) -> List<Pair<Long, Int>> = { emptyList() },
    onDeleteFinishedSet: (String, String, String) -> Unit,
    onDeleteWorkout: (String) -> Unit,
    onLogBodyWeight: (Double) -> Unit,
    onSetRoutineProgression: (String, String) -> Unit,
    onSetRoutineFavorite: (String, Boolean) -> Unit,
    onSetExerciseFavorite: (String, Boolean) -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit,
    onDiscardSession: () -> Unit = {},
    accountId: String = "",
    onLiveActivitySaved: () -> Unit = {},
    initialExternalRoute: String? = null, onExternalRouteHandled: () -> Unit = {},
    onUpdateFinishedWorkout: (String, WorkoutRepository.FinishedWorkoutEdit) -> Unit = { _, _ -> },
    onActivePinChange: (dev.repera.domain.WorkoutLocationPin?) -> Unit = {},
    onImportJson: () -> Unit,
    onImportCsv: () -> Unit,
    onExportJson: () -> Unit,
    onGoogleSignIn: () -> Unit,
    onDriveSync: () -> Unit,
    onSignOut: () -> Unit
) {
    val scheme = reperaColorScheme(isSystemInDarkTheme())
    MaterialTheme(colorScheme = scheme) {
        if (!isAuthenticated) {
            // OnboardingFlowView iOS: título centrado + subtítulo, botón Google
            // NEUTRO (surface con borde surface3 y texto label, no verde marca),
            // busy sustituye al icono DENTRO del botón (busy por proveedor).
            Column(
                modifier = Modifier.fillMaxSize().padding(28.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp, Alignment.CenterVertically)
            ) {
                Text("repera", style = MaterialTheme.typography.displayLarge)
                Column(horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Bienvenido a Repera",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                    Text("Accede con Google. Tu historial permanece protegido y la misma cuenta verificada conserva su identidad en Supabase.",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                }
                // Botón Google: surface + borde + texto label (OG.surface /
                // OG.surface3 / OG.label de iOS), icono "G" o spinner si busy.
                OutlinedButton(
                    onClick = onGoogleSignIn, enabled = !busy,
                    modifier = Modifier.fillMaxWidth(),
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp,
                        MaterialTheme.colorScheme.outlineVariant),
                    colors = ButtonDefaults.outlinedButtonColors(
                        containerColor = MaterialTheme.colorScheme.surface,
                        contentColor = MaterialTheme.colorScheme.onSurface),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(
                        vertical = 14.dp, horizontal = 16.dp)
                ) {
                    if (busy) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp),
                            strokeWidth = 2.dp,
                            color = MaterialTheme.colorScheme.onSurface)
                    } else {
                        Text("G", fontWeight = FontWeight.SemiBold,
                            style = MaterialTheme.typography.titleMedium)
                    }
                    Spacer(Modifier.size(10.dp))
                    Text("Continuar con Google",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold)
                }
                if (status != null) Text(status,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            }
            return@MaterialTheme
        }
        val navController = rememberNavController()
        val backStackEntry by navController.currentBackStackEntryAsState()
        val currentRoute = backStackEntry?.destination?.route ?: "inicio"
        val navigateTab: (String) -> Unit = { route ->
            navController.navigate(route) {
                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                launchSingleTop = true
                restoreState = true
            }
        }
        LaunchedEffect(initialExternalRoute) {
            initialExternalRoute?.takeIf { it == "en-vivo" || it == "inicio" || it == "entreno-activo" }?.let {
                navigateTab(LiveNavigationTarget.resolvedRoute(it,activeWorkout!=null))
                onExternalRouteHandled()
            }
        }
        var homeFocusDay by remember { mutableStateOf<java.time.LocalDate?>(null) }
        val centerVisible = centerSnapshot?.isLinkedOrInvited == true
        var showCenter by remember { mutableStateOf(false) }
        if (showCenter && centerVisible) {
            androidx.compose.material3.ModalBottomSheet(onDismissRequest = { showCenter = false }) {
                CenterTab(
                    connected = centerConnected, loading = centerLoading, submitting = centerSubmitting,
                    errorMessage = centerError, snapshot = centerSnapshot, onRefresh = onCenterRefresh,
                    sharingByCenter = sharingByCenter, sharingUpdating = sharingUpdating,
                    onSetSharing = onSetSharing, onAccept = onCenterAccept,
                    onBook = onCenterBook, onCancel = onCenterCancel)
            }
        }
        val visibleTabs = tabs
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("repera") },
                    actions = {
                        IconButton(onClick = { navigateTab("ajustes") }) {
                            Icon(imageVector = Icons.Outlined.Settings,
                                contentDescription = "Ajustes")
                        }
                    })
            },
            bottomBar = {
                NavigationBar {
                    visibleTabs.forEach { tab ->
                        NavigationBarItem(
                            selected = currentRoute == tab.route,
                            onClick = { navigateTab(tab.route) },
                            icon = { Icon(imageVector = tab.icon, contentDescription = null) },
                            label = { Text(tab.label) }
                        )
                    }
                }
            }
        ) { padding ->
            NavHost(
                navController = navController,
                startDestination = "inicio",
                modifier = Modifier.padding(padding)
            ) {
                composable("inicio") {
                    HomeTab(
                        focusDay=homeFocusDay,
                        heartSeriesProvider = heartSeriesProvider,
                        displayName = displayName,
                        busy = busy,
                        syncing = syncing,
                        status = status,
                        overview = overview,
                        todayHealth = todayHealth,
                        onHealthConnect = onHealthConnect,
                        activeWorkout = activeWorkout,
                        wodTimer = wodTimer,
                        onWodTimerAction = onWodTimerAction,
                        onWodTimerTick = onWodTimerTick,
                        onStartRoutine = onStartRoutine,
                        onWodScore = onWodScore,
                        onWodMovement = onWodMovement,
                        onCompleteWodBlock = onCompleteWodBlock,
                        onReviseWodMovement = onReviseWodMovement,
                        onDeleteWodMovement = onDeleteWodMovement,
                        onLogSet = onLogSet,
                        onLogDropSet = onLogDropSet,
                        onLogRestPauseSet = onLogRestPauseSet,
                        onReviseSet = onReviseSet,
                        onDeleteSet = onDeleteSet,
                        onReviseFinishedSet = onReviseFinishedSet,
                        onDeleteFinishedSet = onDeleteFinishedSet,
                        onDeleteWorkout = onDeleteWorkout,
                        onOpenExerciseFromSession = { entryId, sessionId, instanceId ->
                            navController.navigate(
                                "ejercicio/" + entryId + "?sesion=" + sessionId +
                                    "&instancia=" + instanceId)
                        },
                        onNext = onNext,
                        onFinish = onFinish,
                        onDiscardSession = onDiscardSession,
                        accountId = accountId,
                        onUpdateFinishedWorkout = onUpdateFinishedWorkout,
                        onActivePinChange = onActivePinChange,
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut,
                        onNavigateCreate = { navigateTab("crear") },
                        onDeleteRoutine = onDeleteRoutine,
                        onOpenClock = {
                            if (activeWorkout?.wod != null) navController.navigate("reloj")
                        }
                    )
                }
                composable("diario") {
                    DiaryTab(
                        aiPrograms = aiPrograms ?: emptyList(),
                        onOpenAIPrograms = { navController.navigate("programas-ia") },
                        busy = busy,
                        syncing = syncing,
                        status = status,
                        overview = overview,
                        activeWorkout = activeWorkout,
                        onStartRoutine = onStartRoutine,
                        onEditRoutine = onEditRoutine,
                        onDeleteRoutine = onDeleteRoutine,
                        onEditRoutineContent = { routineId ->
                            navController.navigate("rutina/$routineId")
                        },
                        onSetRoutineProgression = onSetRoutineProgression,
                        onSetRoutineFavorite = onSetRoutineFavorite,
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut,
                        onNavigateHome = { navigateTab("inicio") },
                        onDayPlusCreate = { dayIso, dayName ->
                            // Borrador en memoria (equivalencia iOS DayEditorView):
                            // nada se persiste hasta Guardar; Volver no deja
                            // rutina vacía ni consume cuota.
                            navController.navigate(
                                "rutina-nueva?fecha=" + dayIso + "&nombre=" +
                                    Uri.encode("Entreno · " + dayName))
                        },
                        onDayPlusFavorites = { navController.navigate("favoritos") },
                        onDayPlusTimer = { navController.navigate("temporizador") },
                        onDayPlusScan = { navController.navigate("escaner") }
                    )
                }
                composable("entreno-libre") {
                    // DayEditorView .session: borrador puro; nada se persiste hasta «Empezar» (y solo con Favorito se guarda rutina).
                    val subs = LocalSubscriptions.current
                    val draft = remember {
                        RoutineEntry(id = java.util.UUID.randomUUID().toString(), title = "Mi entreno", supported = true,
                            blocks = emptyList())
                    }
                    var favorite by remember { mutableStateOf(false) }
                    RoutineBlocksEditorScreen(
                        routine = draft,
                        exercises = overview?.exerciseEntries.orEmpty(),
                        busy = busy || activeWorkout != null,
                        loadGuideProvider = loadGuideProvider,
                        importableRoutines = overview?.routineEntries.orEmpty(),
                        sessionMode = true,
                        onFavoriteChosen = { favorite = it },
                        onReplace = { drafts ->
                            if (favorite && subs != null && !subs.canCreateLibraryRoutine(isNew = true).allowed) {
                                subs.presentPaywall(
                                    dev.repera.domain.monetization.PaywallContext.ROUTINES_LIMIT,
                                    feature = dev.repera.domain.monetization.ReperaFeature.UNLIMITED_ROUTINES)
                            } else {
                                onStartSessionFromDrafts(draft.title, drafts, favorite)
                                navController.popBackStack()
                            }
                        },
                        onBack = { navController.popBackStack() }
                    )
                }
                composable("crear") {
                    CreateTab(
                        busy = busy,
                        syncing = syncing,
                        status = status,
                        overview = overview,
                        onCreateRoutine = onCreateRoutine,
                        onAddWodTemplate = onAddWodTemplate,
                        onOpenBoardScan = { navController.navigate("escaner") },
                        onOpenTimer = { navController.navigate("temporizador") },
                        onOpenFreeWorkout = { navController.navigate("entreno-libre") },
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut
                    )
                }
                composable("favoritos") {
                    FavoritesHubScreen(
                        overview = overview,
                        busy = busy,
                        activeWorkout = activeWorkout,
                        onStartRoutine = onStartRoutine,
                        onOpenTimer = { favId ->
                            if (favId != null) navController.navigate("temporizador?fav=" + favId)
                            else navController.navigate("temporizador")
                        },
                        onBack = { navController.popBackStack() },
                        onSetWeekday = { r, d ->
                            onEditRoutine(r.id, r.title, RoutineSchedule(weekday = d,
                                timeMinutes = if (d == null) null else r.timeMinutes))
                        }
                    )
                }
                composable(
                    route = "temporizador?fav={fav}",
                    arguments = listOf(navArgument("fav") {
                        type = NavType.StringType; nullable = true; defaultValue = null
                    })
                ) { backStackEntry ->
                    StandaloneTimerScreen(
                        onBack = { navController.popBackStack() },
                        favoriteId = backStackEntry.arguments?.getString("fav")
                    )
                }
                composable("escaner") {
                    BoardScanScreen(
                        busy = busy,
                        overview = overview,
                        onConfirm = { title, blocks ->
                            onCreateRoutineFromScan(title, blocks)
                            navController.popBackStack()
                        },
                        onBack = { navController.popBackStack() }
                    )
                }
                composable("entreno-activo") {
                    val workout=activeWorkout
                    if(workout==null) {
                        LaunchedEffect(Unit) { navigateTab("inicio") }
                    } else {
                        ActiveWorkoutScreen(workout,busy,wodTimer,onWodTimerAction,onWodTimerTick,
                            onWodScore,onWodMovement,onCompleteWodBlock,onReviseWodMovement,onDeleteWodMovement,
                            onLogSet,onLogDropSet,onLogRestPauseSet,onReviseSet,onDeleteSet,onNext,onFinish,
                            onDiscardSession,{navController.navigate("reloj")},{navController.popBackStack()},
                            overview?.activeLocationPin,accountId,onActivePinChange)
                    }
                }
                composable("en-vivo") {
                    LiveActivityScreen(accountId = accountId,
                        hasActiveWorkout = activeWorkout != null, onOpenWorkout = { navController.navigate("entreno-activo") },
                        onSaved = { onLiveActivitySaved(); navigateTab("inicio") },
                        onSavedDay={ homeFocusDay=java.time.Instant.ofEpochMilli(it).atZone(java.time.ZoneId.systemDefault()).toLocalDate() },
                        onOpenTools = { navController.navigate("crear") },
                        onOpenCenter = if (centerVisible) ({ showCenter = true }) else null)
                }
                composable("center") {
                    CenterTab(
                        connected = centerConnected,
                        loading = centerLoading,
                        submitting = centerSubmitting,
                        errorMessage = centerError,
                        snapshot = centerSnapshot,
                        onRefresh = onCenterRefresh,
                        sharingByCenter = sharingByCenter,
                        sharingUpdating = sharingUpdating,
                        onSetSharing = onSetSharing,
                        onAccept = onCenterAccept,
                        onBook = onCenterBook,
                        onCancel = onCenterCancel
                    )
                }
                composable("progreso") {
                    ProgressTab(
                        busy = busy,
                        syncing = syncing,
                        status = status,
                        overview = overview,
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut,
                        onReviseFinishedSet = onReviseFinishedSet,
                        onDeleteFinishedSet = onDeleteFinishedSet,
                        onLogBodyWeight = onLogBodyWeight
                    )
                }
                composable("reloj") {
                    val clockWorkout = activeWorkout
                    if (clockWorkout?.wod != null) {
                        WodClockScreen(
                            active = clockWorkout,
                            busy = busy,
                            timer = wodTimer,
                            onTimerAction = onWodTimerAction,
                            onTimerTick = onWodTimerTick,
                            onBack = { navController.popBackStack() }
                        )
                    } else {
                        LaunchedEffect(Unit) { navController.popBackStack() }
                    }
                }
                composable("ejercicios") {
                    ExercisesTab(
                        heartSeriesProvider = heartSeriesProvider,
                        onUpdateFinishedWorkout = onUpdateFinishedWorkout,
                        accountId = accountId, onArchiveChanged = onLiveActivitySaved,
                        busy = busy,
                        syncing = syncing,
                        status = status,
                        overview = overview,
                        activeWorkout = activeWorkout,
                        onQuickLog = onQuickLog,
                        onSetExerciseFavorite = onSetExerciseFavorite,
                        onOpenExercise = { exerciseId ->
                            navController.navigate("ejercicio/$exerciseId")
                        },
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut,
                        onNavigateHome = { navigateTab("inicio") }
                    )
                }
                composable("ajustes") {
                    SettingsTab(
                        busy = busy,
                        onOpenAIAccess = {
                            navController.navigate("acceso-ia")
                        },
                        onImportJson = onImportJson,
                        onImportCsv = onImportCsv
                    )
                }
                composable("programas-ia") {
                    LaunchedEffect(Unit) { onAIProgramsRefresh() }
                    AIProgramsScreen(
                        connected = aiConnected,
                        loading = aiProgramsLoading,
                        programs = aiPrograms,
                        updatingId = aiProgramsUpdatingId,
                        errorMessage = aiProgramsError,
                        onRefresh = onAIProgramsRefresh,
                        onChangeStatus = onAIProgramStatus
                    )
                }
                composable("acceso-ia") {
                    // iOS .task: recuperar tokens + cambios al entrar.
                    LaunchedEffect(Unit) { onAIRefresh() }
                    AIAccessScreen(
                        connected = aiConnected,
                        busy = aiBusy,
                        tokens = aiTokens,
                        errorMessage = aiError,
                        successMessage = aiSuccess,
                        createdToken = aiCreatedToken,
                        changes = aiChanges,
                        changeBusy = aiChangeBusy,
                        changeError = aiChangeError,
                        inboxPending = aiInboxPending,
                        inboxConflicts = aiInboxConflicts,
                        onRefresh = onAIRefresh,
                        onCreate = onAICreate,
                        onRevoke = onAIRevoke,
                        onDecide = onAIDecide,
                        onDismissCreated = onAIDismissCreated,
                        onCopyCreated = onAICopyCreated
                    )
                }
                composable(
                    route = "rutina/{routineId}",
                    arguments = listOf(navArgument("routineId") { type = NavType.StringType })
                ) { backStackEntry ->
                    val routineId = backStackEntry.arguments?.getString("routineId").orEmpty()
                    val routine = overview?.routineEntries?.firstOrNull { it.id == routineId }
                    if (routine == null) {
                        LaunchedEffect(Unit) { navController.popBackStack() }
                    } else {
                        // Editor sobre borrador local (RoutineBlocksEditorScreen):
                        // solo «Guardar» persiste; «Volver» descarta sin tocar
                        // la rutina, igual que en iOS.
                        RoutineBlocksEditorScreen(
                            routine = routine,
                            exercises = overview?.exerciseEntries.orEmpty(),
                            busy = busy,
                            loadGuideProvider = loadGuideProvider,
                            importableRoutines = overview?.routineEntries.orEmpty(),
                            onTitleSuggested = { t ->
                                onEditRoutine(routineId, t, RoutineSchedule(routine.scheduledDate, routine.weekday, routine.timeMinutes))
                            },
                            onReplace = { drafts ->
                                onReplaceRoutineBlocks(routineId, drafts)
                                navController.popBackStack()
                            },
                            onBack = { navController.popBackStack() }
                        )
                    }
                }
                composable(
                    route = "rutina-nueva?fecha={fecha}&nombre={nombre}",
                    arguments = listOf(
                        navArgument("fecha") { type = NavType.StringType },
                        navArgument("nombre") { type = NavType.StringType }
                    )
                ) { backStackEntry ->
                    // DayPlus: alta one-off como borrador puro. La rutina no
                    // existe en el almacén hasta «Guardar» (persistencia única
                    // en Guardar, como DayEditorView de iOS); «Volver» —con o
                    // sin contenido— descarta el borrador íntegro y no consume
                    // cuota de rutinas. El identificador se reserva al abrir
                    // para que el estado del borrador sea recuperable durante
                    // la sesión de edición.
                    val fecha = backStackEntry.arguments?.getString("fecha").orEmpty()
                    val nombre = backStackEntry.arguments?.getString("nombre")
                        .orEmpty().ifBlank { "Entreno" }
                    val draft = remember(fecha, nombre) {
                        RoutineEntry(
                            id = java.util.UUID.randomUUID().toString(),
                            title = nombre,
                            supported = true,
                            scheduledDate = fecha,
                            blocks = emptyList())
                    }
                    var oneOffTitle by remember(fecha, nombre) { mutableStateOf<String?>(null) }
                    RoutineBlocksEditorScreen(
                        routine = draft,
                        exercises = overview?.exerciseEntries.orEmpty(),
                        busy = busy,
                        loadGuideProvider = loadGuideProvider,
                        importableRoutines = overview?.routineEntries.orEmpty(),
                        onTitleSuggested = { t -> oneOffTitle = t },
                        onReplace = { drafts ->
                            onSaveOneOffRoutine(oneOffTitle ?: nombre, drafts, fecha)
                            navController.popBackStack()
                        },
                        onBack = { navController.popBackStack() }
                    )
                }
                composable(
                    // Sesión opcional: al abrir la ficha desde un entreno
                    // terminado aparece la tarjeta «Esta sesión» (iOS).
                    route = "ejercicio/{exerciseId}?sesion={sessionId}&instancia={instanceId}",
                    arguments = listOf(
                        navArgument("exerciseId") { type = NavType.StringType },
                        navArgument("sessionId") {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        },
                        navArgument("instanceId") {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        }
                    )
                ) { backStackEntry ->
                    val exerciseId = backStackEntry.arguments?.getString("exerciseId").orEmpty()
                    val highlightSessionId =
                        backStackEntry.arguments?.getString("sessionId")
                    val highlightInstanceId =
                        backStackEntry.arguments?.getString("instanceId")
                            ?.takeIf { it.isNotBlank() }
                    val entry = overview?.exerciseEntries?.firstOrNull { it.id == exerciseId }
                    if (entry == null) {
                        LaunchedEffect(Unit) { navController.popBackStack() }
                    } else {
                        ExerciseDetailScreen(
                            entry = entry,
                            exerciseSeries = exerciseSeries,
                            highlightSessionId = highlightSessionId,
                            highlightInstanceId = highlightInstanceId,
                            sessionAppearances = sessionAppearances,
                            onBack = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }
}


/** Ajustes mínimos: sección Datos con la entrada Acceso IA (paridad con la
 *  ubicación de iOS en SettingsView). El resto de ajustes de iOS aún no
 *  tiene pantalla Android. */
@Composable
internal fun SettingsTab(
    busy: Boolean,
    onOpenAIAccess: () -> Unit,
    onImportJson: () -> Unit,
    onImportCsv: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Ajustes", style = MaterialTheme.typography.titleLarge)
        Text("Datos", style = MaterialTheme.typography.titleMedium)
        Row(modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onOpenAIAccess)
            .padding(vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically) {
            Text("Acceso IA", style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.weight(1f))
            Icon(imageVector = Icons.Outlined.KeyboardArrowRight,
                contentDescription = null)
        }
        // Misma sección Datos de iOS: traspaso del JSON de Apple y CSV.
        OutlinedButton(onClick = onImportJson, enabled = !busy,
            modifier = Modifier.fillMaxWidth()) {
            Text("Importar JSON (traspaso desde Apple)")
        }
        OutlinedButton(onClick = onImportCsv, enabled = !busy,
            modifier = Modifier.fillMaxWidth()) {
            Text("Importar CSV Strong/Hevy")
        }
    }
}
