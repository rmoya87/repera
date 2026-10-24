package dev.repera.mobile

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
    TabSpec("crear", "Crear", Icons.Outlined.AddCircleOutline),
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
    onCreateOneOffRoutine: (String, String, (String) -> Unit) -> Unit = { _, _, _ -> },
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
    onDeleteFinishedSet: (String, String, String) -> Unit,
    onLogBodyWeight: (Double) -> Unit,
    onSetRoutineProgression: (String, String) -> Unit,
    onSetRoutineFavorite: (String, Boolean) -> Unit,
    onSetExerciseFavorite: (String, Boolean) -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit,
    onDiscardSession: () -> Unit = {},
    onImportJson: () -> Unit,
    onImportCsv: () -> Unit,
    onExportJson: () -> Unit,
    onGoogleSignIn: () -> Unit,
    onDriveSync: () -> Unit,
    onSignOut: () -> Unit
) {
    val scheme = if (isSystemInDarkTheme()) {
        darkColorScheme(primary = brandGreen, onPrimary = Color.Black)
    } else lightColorScheme(primary = brandGreen, onPrimary = Color.Black)
    MaterialTheme(colorScheme = scheme) {
        if (!isAuthenticated) {
            Column(
                modifier = Modifier.fillMaxSize().padding(28.dp),
                verticalArrangement = Arrangement.Center
            ) {
                Text("repera", style = MaterialTheme.typography.displayLarge)
                Text("Tu entrenamiento, ahora en Android", style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.padding(12.dp))
                Button(
                    onClick = onGoogleSignIn, enabled = !busy,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = brandGreen, contentColor = Color.Black)
                ) { Text("Iniciar sesión con Google") }
                if (busy) CircularProgressIndicator(modifier = Modifier.padding(12.dp))
                if (status != null) Text(status, modifier = Modifier.padding(top = 12.dp))
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
        val centerVisible = centerSnapshot?.isLinkedOrInvited == true
        val visibleTabs = tabs.map { tab ->
            if (tab.route == "crear" && centerVisible)
                TabSpec("center", "Center", Icons.Outlined.Apartment) else tab
        }
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
                        onNext = onNext,
                        onFinish = onFinish,
                        onDiscardSession = onDiscardSession,
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
                            onCreateOneOffRoutine(dayIso, dayName) { newId ->
                                navController.navigate("rutina/$newId?fresh=1")
                            }
                        },
                        onDayPlusFavorites = { navController.navigate("favoritos") },
                        onDayPlusTimer = { navController.navigate("temporizador") },
                        onDayPlusScan = { navController.navigate("escaner") }
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
                        onBack = { navController.popBackStack() }
                    )
                }
                composable("temporizador") {
                    StandaloneTimerScreen(
                        onBack = { navController.popBackStack() }
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
                    route = "rutina/{routineId}?fresh={fresh}",
                    arguments = listOf(
                        navArgument("routineId") { type = NavType.StringType },
                        navArgument("fresh") { type = NavType.BoolType; defaultValue = false }
                    )
                ) { backStackEntry ->
                    val routineId = backStackEntry.arguments?.getString("routineId").orEmpty()
                    val freshFromDayPlus = backStackEntry.arguments?.getBoolean("fresh") ?: false
                    val routine = overview?.routineEntries?.firstOrNull { it.id == routineId }
                    if (routine == null) {
                        LaunchedEffect(Unit) { navController.popBackStack() }
                    } else {
                        RoutineBlocksEditorScreen(
                            routine = routine,
                            exercises = overview?.exerciseEntries.orEmpty(),
                            busy = busy,
                            onReplace = { drafts ->
                                onReplaceRoutineBlocks(routineId, drafts)
                                navController.popBackStack()
                            },
                            onBack = {
                                // Equivalencia iOS (borrador en memoria + Guardar):
                                // salir sin guardar de una rutina one-off recién
                                // creada y aún vacía no deja artefactos.
                                if (freshFromDayPlus &&
                                    routine.blocks.all { it.entries.isEmpty() }) {
                                    onDeleteRoutine(routineId)
                                }
                                navController.popBackStack()
                            }
                        )
                        // Mismo criterio para el botón físico/gesto de atrás.
                        BackHandler(enabled = !busy) {
                            if (freshFromDayPlus &&
                                routine.blocks.all { it.entries.isEmpty() }) {
                                onDeleteRoutine(routineId)
                            }
                            navController.popBackStack()
                        }
                    }
                }
                composable(
                    route = "ejercicio/{exerciseId}",
                    arguments = listOf(navArgument("exerciseId") { type = NavType.StringType })
                ) { backStackEntry ->
                    val exerciseId = backStackEntry.arguments?.getString("exerciseId").orEmpty()
                    val entry = overview?.exerciseEntries?.firstOrNull { it.id == exerciseId }
                    if (entry == null) {
                        LaunchedEffect(Unit) { navController.popBackStack() }
                    } else {
                        ExerciseDetailScreen(
                            entry = entry,
                            exerciseSeries = exerciseSeries,
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
private fun SettingsTab(
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
