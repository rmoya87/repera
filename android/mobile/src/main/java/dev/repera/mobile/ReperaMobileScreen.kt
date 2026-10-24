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
import androidx.navigation.compose.composable
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
    onCreateRoutine: (String, String, List<RoutineDraftEntry>, Int, Int,
        RoutineSchedule, Int, Int, Int) -> Unit,
    onWodScore: (Int?, Int?, Int?) -> Unit,
    onWodMovement: (Int, Int, Int, Double?) -> Unit,
    onCompleteWodBlock: () -> Unit,
    onReviseWodMovement: (String, Int, Double?) -> Unit,
    onDeleteWodMovement: (String) -> Unit,
    onQuickLog: (String) -> Unit,
    onInitializeLocal: () -> Unit,
    onLogSet: (Int, Double?, Double?, Boolean, String?, Int?, Int?) -> Unit,
    onReviseSet: (String, Int, Double?, String?, Int?, Int?) -> Unit,
    onDeleteSet: (String) -> Unit,
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
        Scaffold(
            topBar = { TopAppBar(title = { Text("repera") }) },
            bottomBar = {
                NavigationBar {
                    tabs.forEach { tab ->
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
                        onReviseSet = onReviseSet,
                        onDeleteSet = onDeleteSet,
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
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut
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
                        onSignOut = onSignOut
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
                        onInitializeLocal = onInitializeLocal,
                        onImportJson = onImportJson,
                        onDriveSync = onDriveSync,
                        onExportJson = onExportJson,
                        onSignOut = onSignOut,
                        onNavigateHome = { navigateTab("inicio") }
                    )
                }
            }
        }
    }
}
