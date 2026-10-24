package dev.repera.mobile

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
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
    centerConnected: Boolean,
    centerLoading: Boolean,
    centerSubmitting: Boolean,
    centerError: String?,
    centerSnapshot: BusinessCenterStore.Snapshot?,
    onCenterRefresh: () -> Unit,
    onCenterAccept: (BusinessCenterStore.Invitation) -> Unit,
    onCenterBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onCenterCancel: (BusinessCenterStore.Booking) -> Unit,
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
    onNext: () -> Unit,
    onFinish: () -> Unit,
    onImportJson: () -> Unit,
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
            topBar = { TopAppBar(title = { Text("repera") }) },
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
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut,
                        onNavigateCreate = { navigateTab("crear") },
                        onOpenClock = {
                            if (activeWorkout?.wod != null) navController.navigate("reloj")
                        }
                    )
                }
                composable("diario") {
                    DiaryTab(
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
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut,
                        onNavigateHome = { navigateTab("inicio") }
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
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut
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
                composable(
                    route = "rutina/{routineId}",
                    arguments = listOf(navArgument("routineId") { type = NavType.StringType })
                ) { backStackEntry ->
                    val routineId = backStackEntry.arguments?.getString("routineId").orEmpty()
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
                            onBack = { navController.popBackStack() }
                        )
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
