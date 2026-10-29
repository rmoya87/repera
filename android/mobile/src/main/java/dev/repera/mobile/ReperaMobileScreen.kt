package dev.repera.mobile

import dev.repera.mobile.monetization.LocalSubscriptions
import android.net.Uri
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Psychology
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.mutableIntStateOf
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.background
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.activity.compose.BackHandler
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.material3.TextButton
import kotlinx.coroutines.launch
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.NavType
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.compose.ui.platform.LocalContext
import androidx.compose.runtime.SideEffect
import android.app.Activity
import android.graphics.Color as AndroidColor
import androidx.core.view.WindowInsetsControllerCompat
import androidx.navigation.compose.rememberNavController

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
    healthAccess: HealthAccessState = HealthAccessState.UNKNOWN,
    onHealthConnect: () -> Unit,
    onPrivateSleepChanged:(Boolean)->Unit = {},
    onPrivateCycleChanged:(Boolean)->Unit = {},
    onProgressRangeChange:(String)->Unit = {},
    externalHealthDetail:suspend(ExternalHealthHistoryEntry)->ExternalHealthDetail? = {null},
    activeWorkout: ActiveWorkout?,
    wodTimer: WodTimerState?,
    onWodTimerAction: (String) -> Unit,
    onWodTimerTick: () -> Unit,
    onStartRoutine: (String) -> Unit,
    onEditRoutine: (String, String, RoutineSchedule) -> Unit,
    onDeleteRoutine: (String) -> Unit,
    onRemoveScheduledRoutine: (String) -> Unit = onDeleteRoutine,
    onCopyPreviousWeek: (java.time.LocalDate) -> Unit = {},
    onAssignRoutineToDate: (String, java.time.LocalDate) -> Unit = { _, _ -> },
    onClearWeeklySchedule: (java.time.LocalDate) -> Unit = {},
    onReplaceRoutineBlocks: (String, List<RoutineBlockDraft>,String?,()->Unit) -> Unit,
    onCreateTemplate: (String,List<RoutineBlockDraft>,RoutineSchedule,String,()->Unit)->Unit,
    onCreateRoutine: (String, String, List<RoutineDraftEntry>, Int, Int,
        RoutineSchedule, Int, Int, Int, List<Int>?) -> Unit,
    onAddWodTemplate: (String) -> Unit,
    onToggleWodFavorite:(String)->Unit,
    onPlayWod:(String,String,()->Unit)->Unit,
    onCreateRoutineFromScan: (String, List<dev.repera.domain.RoutineBlock>, String, String?, () -> Unit) -> Unit,
    /** Escáner → Empezar: crea one-off/plantilla e inicia sesión. */
    onStartRoutineFromScan: (String, List<dev.repera.domain.RoutineBlock>, String, String?, () -> Unit) -> Unit =
        onCreateRoutineFromScan,
    onSaveOneOffRoutine: (
        String,
        List<RoutineBlockDraft>,
        String,
        String,
        Int?,
        Boolean,
        dev.repera.domain.WorkoutLocationPin?,
        () -> Unit
    ) -> Unit = { _, _, _, _, _, _, _, _ -> },
    onStartSessionFromDrafts: (String, List<RoutineBlockDraft>, Boolean,String,()->Unit) -> Unit = { _, _, _, _, _ -> },
    centerConnected: Boolean,
    centerLoading: Boolean,
    centerSubmitting: Boolean,
    centerError: String?,
    centerSnapshot: BusinessCenterStore.Snapshot?,
    onCenterRefresh: () -> Unit,
    onExerciseCatalogRefreshRequest: () -> Unit = {},
    onCenterAccept: (BusinessCenterStore.Invitation) -> Unit,
    centerDirectory:List<BusinessCenterStore.Organization> = emptyList(),
    centerDirectorySearching:Boolean = false,
    onSearchCenterDirectory:(String)->Unit = {},
    onRequestCenterLink:(BusinessCenterStore.Organization,String,String?)->Unit = {_,_,_->},
    onLeaveCenter:(BusinessCenterStore.Organization)->Unit = {},
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
    onSaveQuickSets:(String,List<QuickLogRow>,String?,String,()->Unit)->Unit = {_,_,_,_,_->},
    onInitializeLocal: () -> Unit,
    onLogSet: (Int, Double?, Double?, Boolean, String?, Int?, Int?, Boolean) -> Unit,
    onLogDropSet: (Int, Double?, List<Pair<Int, Double?>>, Double?, Boolean) -> Unit,
    onLogRestPauseSet: (List<Pair<Int, Int>>, Double?, Double?, Boolean) -> Unit,
    onReviseSet: (String, Int, Double?, String?, Int?, Int?) -> Unit,
    onDeleteSet: (String) -> Unit,
    onReviseFinishedSet: (String, String, String, Int, Double?, Int?) -> Unit,
    onSetTestedOneRM:(String,Double?)->Unit = {_,_->},
    exerciseSummary: (String) -> dev.repera.domain.ExerciseHistorySummary? = { null },
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
    onDeleteBodyWeight:(String)->Unit = {},
    onSetRoutineProgression: (String, String) -> Unit,
    onSetRoutineFavorite: (String, Boolean) -> Unit,
    onSetExerciseFavorite: (String, Boolean) -> Unit,
    onCreateCustomExercise: (
        name: String, muscleGroup: String, equipment: String?,
        targetMuscle: String?, secondary: List<String>,
        description: String?, instructions: String?,
        onDone: () -> Unit
    ) -> Unit = { _, _, _, _, _, _, _, _ -> },
    onOpenPaywallForCustomExercise: () -> Unit = {},
    onNext: () -> Unit,
    onSelectActiveExercise:(Int)->Unit = {},
    onUpdateActiveNotes:(String)->Unit = {},
    onSaveActiveFavorite:()->Unit = {},
    onSubstituteActiveExercise: (ExerciseEntry) -> Unit = {},
    onRemoveActiveExercise: () -> Unit = {},
    activeEditorDraft:()->RoutineEntry? = {null},
    onUpdateActivePlan:(String,String,List<RoutineBlockDraft>,()->Unit)->Unit = {_,_,_,_->},
    onFinish: () -> Unit,
    onDiscardSession: () -> Unit = {},
    accountId: String = "",
    dayHealthProvider:suspend (java.time.LocalDate)->TodayHealth? = {null},
    onUpdateProfile:(ProfileSettings)->Unit = {},
    onSendCenterMessage:(String,String,String)->Unit = {_,_,_->},
    onUpdateHealthGoals:(HealthGoals)->Unit = {},
    onUpdateRotation:(dev.repera.domain.RotationPlan?)->Unit = {},
    onUpdateTrainingSettings: (TrainingSettings) -> Unit = {},
    onLiveActivitySaved: () -> Unit = {},
    onRemoveSportFavorite: (String) -> Unit = {},
    onSaveTimerSession: (StandaloneTimerCompletion) -> Boolean = { false },
    initialExternalRoute: String? = null, onExternalRouteHandled: () -> Unit = {},
    onUpdateFinishedWorkout: (String, WorkoutRepository.FinishedWorkoutEdit) -> Unit = { _, _ -> },
    onActivePinChange: (dev.repera.domain.WorkoutLocationPin?) -> Unit = {},
    onImportJson: () -> Unit,
    onImportCsv: () -> Unit,
    onExportJson: () -> Unit,
    onGoogleSignIn: () -> Unit,
    onDriveSync: () -> Unit,
    onSignOut: () -> Unit,
    onDeleteAccount: () -> Unit = {},
    deletingAccount: Boolean = false,
    accountDeleteError: String? = null,
    onDismissAccountDeleteError: () -> Unit = {}
) {
    ReperaTheme {
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
            return@ReperaTheme
        }
        val navController = rememberNavController()
        // Apple SessionPreviewView: con una sesión activa, Empezar la continúa en lugar de intentar iniciar otra.
        val startOrContinueRoutine: (String) -> Unit = { id ->
            if (activeWorkout != null) navController.navigate("entreno-activo") else onStartRoutine(id)
        }
        var libraryModeRequest by rememberSaveable {mutableStateOf<String?>(null)}
        // Favoritos → Comenzar: deporte a preseleccionar al abrir en-vivo.
        var pendingLiveSportId by rememberSaveable { mutableStateOf<String?>(null) }
        val backStackEntry by navController.currentBackStackEntryAsState()
        val currentRoute = backStackEntry?.destination?.route ?: "inicio"
        val darkTheme = isSystemInDarkTheme()
        val activityContext = LocalContext.current
        SideEffect {
            val activity = activityContext as? Activity ?: return@SideEffect
            val window = activity.window
            val controller = WindowInsetsControllerCompat(window, window.decorView)
            val homeLightHeader = currentRoute == "inicio" && !darkTheme
            controller.isAppearanceLightStatusBars = if (homeLightHeader) true else !darkTheme
            window.statusBarColor = if (homeLightHeader) {
                AndroidColor.WHITE
            } else {
                AndroidColor.TRANSPARENT
            }
        }
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
        // I-42: Minimizar reloj → barra flotante sobre la sesión (no destruye el timer).
        var clockMinimized by rememberSaveable(accountId) { mutableStateOf(false) }
        LaunchedEffect(activeWorkout?.id, activeWorkout?.wod) {
            if (activeWorkout?.wod == null) clockMinimized = false
        }
        // iOS restoresAddSheetAfterPage: reabrir DayPlus al volver de Favoritos/Tempo.
        var restoreDayPlus by rememberSaveable(accountId) { mutableStateOf(false) }
        val centerVisible = centerSnapshot?.isLinkedOrInvited == true
        var showCenter by remember { mutableStateOf(false) }
        if (showCenter && centerVisible) {
            ReperaModalBottomSheet(onDismissRequest = { showCenter = false }) {
                CenterTab(
                    accountId = accountId,
                    connected = centerConnected, loading = centerLoading, submitting = centerSubmitting,
                    errorMessage = centerError, snapshot = centerSnapshot, onRefresh = onCenterRefresh,
                    sharingByCenter = sharingByCenter, sharingUpdating = sharingUpdating,
                    onSetSharing = onSetSharing, onAccept = onCenterAccept,
                    onBook = onCenterBook, onCancel = onCenterCancel,
                    directory=centerDirectory,directorySearching=centerDirectorySearching,onSearchDirectory=onSearchCenterDirectory,
                    onRequestLink=onRequestCenterLink,onLeave=onLeaveCenter)
            }
        }
        var showSettingsPanel by androidx.compose.runtime.saveable.rememberSaveable(accountId) {mutableStateOf(false)}
        // Expanded Inicio edits a routine in the same trailing column instead of navigating away.
        var routinePanelId by androidx.compose.runtime.saveable.rememberSaveable(accountId) {mutableStateOf<String?>(null)}
        val settingsContent: @Composable (onBack: (() -> Unit)?)->Unit = { onBack ->
                    val subs=dev.repera.mobile.monetization.LocalSubscriptions.current
                    SettingsTab(
                        busy = busy,
                        onBack = onBack,
                        onOpenAIAccess = {
                            navController.navigate("acceso-ia")
                        },
                        onImportJson = onImportJson,
                        onImportCsv = onImportCsv,
                        onOpenCenter={navController.navigate("center")},
                        onOpenBodyWeights={navController.navigate("peso-corporal")},
                        onOpenHistory={navController.navigate("historial")},
                        onOpenHealthGoals={navController.navigate("ajustes-objetivos")},
                        onOpenPro={subs?.presentPaywall(dev.repera.domain.monetization.PaywallContext.SETTINGS,
                            feature=dev.repera.domain.monetization.ReperaFeature.ADVANCED_PROGRESS)},
                        proStatus=if(subs?.businessSponsoredAccess==true) "Acceso por centro o entrenador" else subs?.status?.displayName,
                        onUpdateProfile=onUpdateProfile,
                        overview=overview,onUpdateTrainingSettings=onUpdateTrainingSettings,onUpdateRotation=onUpdateRotation,onUpdateHealthGoals=onUpdateHealthGoals,
                        onExportJson=onExportJson,onHealthConnect=onHealthConnect,onPrivateSleepChanged=onPrivateSleepChanged,onPrivateCycleChanged=onPrivateCycleChanged,onSignOut=onSignOut,
                        onDeleteAccount=onDeleteAccount,deletingAccount=deletingAccount,
                        accountDeleteError=accountDeleteError,
                        onDismissAccountDeleteError=onDismissAccountDeleteError
                    )

        }
        androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxSize()) {
        val expanded=adaptiveCardColumns(maxWidth.value)==2
        LaunchedEffect(expanded,currentRoute,accountId) {if(!expanded || currentRoute!="inicio") {showSettingsPanel=false;routinePanelId=null}}
        val openSettings:()->Unit = {
            if(expanded && currentRoute=="inicio") {routinePanelId=null;showSettingsPanel=true} else navigateTab("ajustes")
        }
        // Paridad iOS: las 4 tabs usan large title in-content (`ogFixedTopBar` /
        // título en scroll), no un TopAppBar global «repera» encima de todas.
        // Ajustes se abre desde el avatar de Inicio o la ruta `ajustes`.
        val tabRoutes = reperaTabRoutes
        val hideAppShell = reperaRouteHidesAppShell(currentRoute)
        val showTabBar = currentRoute in tabRoutes && !hideAppShell
        val showChromeTopBar = currentRoute != null && currentRoute !in tabRoutes && !hideAppShell
        Scaffold(
            containerColor = MaterialTheme.colorScheme.background,
            topBar = {
                if (showChromeTopBar) {
                    TopAppBar(
                        title = { Text("repera") },
                        colors = androidx.compose.material3.TopAppBarDefaults.topAppBarColors(
                            containerColor = MaterialTheme.colorScheme.background,
                            titleContentColor = MaterialTheme.colorScheme.onBackground,
                            actionIconContentColor = MaterialTheme.colorScheme.onBackground
                        ),
                        actions = {
                            IconButton(onClick = openSettings) {
                                Icon(imageVector = Icons.Outlined.Settings,
                                    contentDescription = "Ajustes")
                            }
                        })
                }
            },
            bottomBar = {
                val session = activeWorkout
                val continueTitle = if (session != null && showTabBar) {
                    session.exerciseName.takeIf { it.isNotBlank() }
                        ?: session.title.takeIf { it.isNotBlank() }
                        ?: "Entreno"
                } else null
                val continueProgress = if (session != null && session.total > 0)
                    "${session.index + 1}/${session.total}" else ""
                ReperaTabBarChrome(
                    showTabBar = showTabBar,
                    selectedRoute = currentRoute,
                    onTabSelected = navigateTab,
                    continueTitle = continueTitle,
                    continueProgress = continueProgress,
                    onContinue = { navController.navigate("entreno-activo") }
                )
            }
        ) { padding ->
            androidx.compose.foundation.layout.Box(Modifier.fillMaxSize().padding(padding)) {
            NavHost(
                navController = navController,
                startDestination = "inicio",
                modifier = Modifier.fillMaxSize()
            ) {
                composable("inicio") {
                    HomeTab(
                        onOpenSettings=openSettings,
                        onOpenRecoverySettings=openSettings,
                        professionalSessions=centerSnapshot?.trainingSessions.orEmpty(),
                        centerName={id -> centerSnapshot?.centerName(id) ?: "Centro"},
                        onOpenMessages={navController.navigate("mensajes")},
                        onOpenHistory={navController.navigate("historial")},
                        focusDay=homeFocusDay,
                        heartSeriesProvider = heartSeriesProvider,
                        displayName = displayName,
                        busy = busy,
                        syncing = syncing,
                        status = status,
                        overview = overview,
                        todayHealth = todayHealth,
                        healthAccess = healthAccess,
                        dayHealthProvider=dayHealthProvider,
                        onHealthConnect = onHealthConnect,
                        activeWorkout = activeWorkout,
                        wodTimer = wodTimer,
                        onWodTimerAction = onWodTimerAction,
                        onWodTimerTick = onWodTimerTick,
                        onStartRoutine = startOrContinueRoutine,
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
                        onOpenExercise = { exerciseId ->
                            navController.navigate("ejercicio/$exerciseId")
                        },
                        onNext = onNext,
                        onSelectActiveExercise = onSelectActiveExercise,
                        onUpdateActiveNotes = onUpdateActiveNotes,
                        onSaveActiveFavorite = onSaveActiveFavorite,
                        onSubstituteActiveExercise = onSubstituteActiveExercise,
                        onRemoveActiveExercise = onRemoveActiveExercise,
                        onEditActivePlan = {navController.navigate("entreno-activo-editar")},
                        clockMinimized = clockMinimized,
                        onExpandClock = {
                            clockMinimized = false
                            navController.navigate("reloj")
                        },
                        onOpenActiveSession = { navController.navigate("entreno-activo") },
                        onOpenClock = {
                            clockMinimized = false
                            navController.navigate("reloj")
                        },
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
                        onEditRoutineContent = { id ->
                            navController.navigate("rutina/" + Uri.encode(id))
                        },
                        onSetRoutineFavorite = onSetRoutineFavorite,
                        onDeleteRoutine = onDeleteRoutine,
                        onRemoveScheduledRoutine = onRemoveScheduledRoutine,
                        restoreDayPlus = restoreDayPlus,
                        onRestoreDayPlusConsumed = { restoreDayPlus = false },
                        onDayPlusCreate = { dayIso, dayName ->
                            navController.navigate(
                                "rutina-nueva?fecha=" + dayIso + "&nombre=" +
                                    Uri.encode("Entreno · " + dayName))
                        },
                        onDayPlusFavorites = { dayIso ->
                            restoreDayPlus = true
                            navController.navigate("favoritos?fecha=" + dayIso)
                        },
                        onDayPlusTimer = {
                            restoreDayPlus = true
                            navController.navigate("temporizador")
                        },
                        onDayPlusScan = { dayIso ->
                            navController.navigate("escaner?fecha=" + dayIso)
                        }
                    )
                }
                composable("entreno-libre") {
                    // DayEditorView .session: borrador puro; nada se persiste hasta «Empezar» (y solo con Favorito se guarda rutina).
                    val requestId=androidx.compose.runtime.saveable.rememberSaveable(accountId) {java.util.UUID.randomUUID().toString()}
                    val draft = remember(accountId,requestId) {
                        RoutineEntry(id = requestId, title = "Mi entreno", supported = true,
                            blocks = emptyList())
                    }
                    var favorite by remember { mutableStateOf(false) }
                    var sessionTitle by remember(accountId, requestId) { mutableStateOf("Mi entreno") }
                    RoutineBlocksEditorScreen(accountId=accountId,
                        effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
                        routine = draft,
                        exercises = overview?.exerciseEntries.orEmpty(),
                        busy = busy || (activeWorkout != null && activeWorkout.draftRequestId!=requestId),
                        loadGuideProvider = loadGuideProvider,
                        importableRoutines = overview?.routineEntries.orEmpty(),
                        sessionMode = true,
                        pageTitle = "Crear entreno",
                        showPlaceSection = true,
                        saveStatus=status,
                        onFavoriteChosen = { favorite = it },
                        onTitleSuggested = { sessionTitle = it },
                        onReplace = { drafts ->
                            onStartSessionFromDrafts(sessionTitle, drafts, favorite,requestId) {navController.popBackStack()}
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
                composable(
                    route = "favoritos?fecha={fecha}",
                    arguments = listOf(navArgument("fecha") {
                        type = NavType.StringType; nullable = true; defaultValue = null
                    })
                ) { backStackEntry ->
                    val favDay = backStackEntry.arguments?.getString("fecha")
                        ?.takeIf { it.isNotBlank() }
                        ?.let { runCatching { java.time.LocalDate.parse(it) }.getOrNull() }
                    FavoritesHubScreen(
                        overview = overview,
                        busy = busy,
                        activeWorkout = activeWorkout,
                        targetDate = favDay,
                        onAssignRoutineToDate = { id, date ->
                            onAssignRoutineToDate(id, date)
                            restoreDayPlus = false
                            navController.popBackStack()
                        },
                        onStartRoutine = { id ->
                            restoreDayPlus = false
                            startOrContinueRoutine(id)
                        },
                        onOpenTimer = { favId ->
                            restoreDayPlus = false
                            if (favId != null) navController.navigate("temporizador?fav=" + favId)
                            else navController.navigate("temporizador")
                        },
                        onBack = { navController.popBackStack() },
                        onCreateFavoriteWorkout = {
                            restoreDayPlus = false
                            navController.navigate("favorito-nuevo")
                        },
                        onEditFavoriteWorkout = { id ->
                            restoreDayPlus = false
                            navController.navigate("rutina/" + Uri.encode(id))
                        },
                        onRemoveFavoriteWorkout = { id ->
                            onSetRoutineFavorite(id, false)
                        },
                        onSetWeekday = { r, d ->
                            onEditRoutine(r.id, r.title, RoutineSchedule(weekday = d,
                                timeMinutes = if (d == null) null else r.timeMinutes))
                        },
                        onOpenSport = { sportId ->
                            restoreDayPlus = false
                            pendingLiveSportId = sportId
                            navigateTab("en-vivo")
                        },
                        onRemoveSportFavorite = onRemoveSportFavorite
                    )
                }
                composable("favoritos") {
                    // Acceso general (Crear): sin fecha → iniciar sesión al tocar.
                    FavoritesHubScreen(
                        overview = overview,
                        busy = busy,
                        activeWorkout = activeWorkout,
                        onStartRoutine = startOrContinueRoutine,
                        onOpenTimer = { favId ->
                            if (favId != null) navController.navigate("temporizador?fav=" + favId)
                            else navController.navigate("temporizador")
                        },
                        onBack = { navController.popBackStack() },
                        onCreateFavoriteWorkout = {
                            navController.navigate("favorito-nuevo")
                        },
                        onEditFavoriteWorkout = { id ->
                            navController.navigate("rutina/" + Uri.encode(id))
                        },
                        onRemoveFavoriteWorkout = { id ->
                            onSetRoutineFavorite(id, false)
                        },
                        onSetWeekday = { r, d ->
                            onEditRoutine(r.id, r.title, RoutineSchedule(weekday = d,
                                timeMinutes = if (d == null) null else r.timeMinutes))
                        },
                        onOpenSport = { sportId ->
                            pendingLiveSportId = sportId
                            navigateTab("en-vivo")
                        },
                        onRemoveSportFavorite = onRemoveSportFavorite
                    )
                }
                composable("favorito-nuevo") {
                    val requestId = rememberSaveable(accountId) {
                        java.util.UUID.randomUUID().toString()
                    }
                    var favTitle by remember(accountId, requestId) {
                        mutableStateOf("Mi favorito")
                    }
                    val draft = remember(accountId, requestId) {
                        RoutineEntry(
                            id = requestId,
                            title = "Mi favorito",
                            supported = true,
                            isFavorite = true,
                            blocks = listOf(
                                RoutineBlockInfo(
                                    title = "Bloque 1",
                                    format = "strength",
                                    id = java.util.UUID.randomUUID().toString()
                                )
                            )
                        )
                    }
                    RoutineBlocksEditorScreen(
                        accountId = accountId,
                        effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
                        routine = draft,
                        saveStatus = status,
                        exercises = overview?.exerciseEntries.orEmpty(),
                        busy = busy,
                        loadGuideProvider = loadGuideProvider,
                        importableRoutines = overview?.routineEntries.orEmpty(),
                        editableTitle = true,
                        onTitleSuggested = { favTitle = it },
                        onReplace = { drafts ->
                            onCreateTemplate(
                                favTitle.ifBlank { "Mi favorito" },
                                drafts,
                                RoutineSchedule(),
                                requestId
                            ) {
                                onSetRoutineFavorite(requestId, true)
                                navController.popBackStack()
                            }
                        },
                        onBack = { navController.popBackStack() }
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
                        favoriteId = backStackEntry.arguments?.getString("fav"),
                        onPersistSession = onSaveTimerSession,
                        onSavedDay = { millis ->
                            restoreDayPlus = false
                            homeFocusDay = java.time.Instant.ofEpochMilli(millis)
                                .atZone(java.time.ZoneId.systemDefault()).toLocalDate()
                            navigateTab("inicio")
                        }
                    )
                }
                composable(
                    route = "escaner?fecha={fecha}",
                    arguments = listOf(navArgument("fecha") {
                        type = NavType.StringType; nullable = true; defaultValue = null
                    })
                ) { backStackEntry ->
                    val scanDayIso = backStackEntry.arguments?.getString("fecha")
                        ?.takeIf { it.isNotBlank() }
                    androidx.compose.runtime.key(accountId, scanDayIso) {
                    BoardScanScreen(
                        busy = busy,
                        saveStatus=status,
                        overview = overview,
                        onConfirm = { title, blocks,requestId ->
                            onCreateRoutineFromScan(title, blocks, requestId, scanDayIso) {
                                navController.popBackStack()
                            }
                        },
                        onStart = { title, blocks, requestId ->
                            onStartRoutineFromScan(title, blocks, requestId, scanDayIso) {
                                navController.navigate("entreno-activo") {
                                    popUpTo("inicio") { inclusive = false }
                                }
                            }
                        },
                        onBack = { navController.popBackStack() }
                    )
                }
                }
                composable("escaner") {
                    // Ajustes / Crear sin día: misma ruta sin query.
                    androidx.compose.runtime.key(accountId) {
                    BoardScanScreen(
                        busy = busy,
                        saveStatus=status,
                        overview = overview,
                        onConfirm = { title, blocks,requestId ->
                            onCreateRoutineFromScan(title, blocks, requestId, null) {
                                navController.popBackStack()
                            }
                        },
                        onStart = { title, blocks, requestId ->
                            onStartRoutineFromScan(title, blocks, requestId, null) {
                                navController.navigate("entreno-activo") {
                                    popUpTo("inicio") { inclusive = false }
                                }
                            }
                        },
                        onBack = { navController.popBackStack() }
                    )
                }
                }
                composable("entreno-activo-editar") {
                    val editorSessionId=androidx.compose.runtime.saveable.rememberSaveable(accountId) {activeWorkout?.id.orEmpty()}
                    val draft=remember(accountId,editorSessionId) {activeEditorDraft()}
                    if(draft==null || activeWorkout==null || editorSessionId.isBlank() || activeWorkout.id!=editorSessionId) {
                        LaunchedEffect(Unit) {navController.popBackStack()}
                    } else RoutineBlocksEditorScreen(draft,overview?.exerciseEntries.orEmpty(),busy,accountId=accountId,
                        effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
                        onReplace={blocks ->onUpdateActivePlan(editorSessionId,draft.id,blocks) {navController.popBackStack()}},
                        onBack={navController.popBackStack()},loadGuideProvider=loadGuideProvider,
                        saveStatus=status,importableRoutines=overview?.routineEntries.orEmpty())
                }
                composable("entreno-activo") {
                    val workout=activeWorkout
                    if(workout==null) {
                        LaunchedEffect(Unit) { navigateTab("inicio") }
                    } else {
                        ActiveWorkoutScreen(
                            workout, busy, wodTimer, onWodTimerAction, onWodTimerTick,
                            onWodScore, onWodMovement, onCompleteWodBlock, onReviseWodMovement,
                            onDeleteWodMovement,
                            onLogSet, onLogDropSet, onLogRestPauseSet, onReviseSet, onDeleteSet,
                            onNext, onFinish,
                            onDiscardSession,
                            onOpenClock = {
                                clockMinimized = false
                                navController.navigate("reloj")
                            },
                            onBack = { navController.popBackStack() },
                            pin = overview?.activeLocationPin,
                            accountId = accountId,
                            onPinChange = onActivePinChange,
                            effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
                            weightUnit = overview?.trainingSettings?.weightUnit ?: "kg",
                            onSelectExercise = onSelectActiveExercise,
                            onUpdateNotes = onUpdateActiveNotes,
                            onSaveFavorite = onSaveActiveFavorite,
                            onEditPlan = { navController.navigate("entreno-activo-editar") },
                            activeEditorDraft = activeEditorDraft,
                            onApplyActivePlan = onUpdateActivePlan,
                            catalog = overview?.exerciseEntries.orEmpty(),
                            onSubstituteExercise = onSubstituteActiveExercise,
                            onRemoveExercise = onRemoveActiveExercise,
                            clockMinimized = clockMinimized,
                            onExpandClock = {
                                clockMinimized = false
                                navController.navigate("reloj")
                            }
                        )
                    }
                }
                composable("en-vivo") {
                    LiveActivityScreen(accountId = accountId,
                        hasActiveWorkout = activeWorkout != null, onOpenWorkout = { navController.navigate("entreno-activo") },
                        onSaved = { onLiveActivitySaved(); navigateTab("inicio") },
                        onSavedDay={ homeFocusDay=java.time.Instant.ofEpochMilli(it).atZone(java.time.ZoneId.systemDefault()).toLocalDate() },
                        onOpenTools = { navController.navigate("crear") },
                        onOpenCenter = if (centerVisible) ({ showCenter = true }) else null,
                        initialSportId = pendingLiveSportId,
                        onInitialSportConsumed = { pendingLiveSportId = null })
                }
                composable("center") {
                    CenterTab(
                    accountId = accountId,
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
                        onCancel = onCenterCancel,
                        directory=centerDirectory,directorySearching=centerDirectorySearching,onSearchDirectory=onSearchCenterDirectory,
                        onRequestLink=onRequestCenterLink,onLeave=onLeaveCenter
                    )
                }
                composable("progreso") {
                    ProgressTab(onOpenExercise={id ->navController.navigate("ejercicio/$id")},
                        onOpenSports={libraryModeRequest="Deportes";navController.navigate("ejercicios")},
                        accountId = accountId,
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
                        onLogBodyWeight = onLogBodyWeight,
                        onOpenBodyWeights = { navController.navigate("peso-corporal") },
                        onOpenHistory = {navController.navigate("historial")},
                        healthAccess = healthAccess,
                        onHealthConnect = onHealthConnect
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
                            onBack = {
                                clockMinimized = true
                                navController.popBackStack()
                            }
                        )
                    } else {
                        LaunchedEffect(Unit) { navController.popBackStack() }
                    }
                }
                composable("ejercicios") {
                    // Apple 11ea29a6: entrar en Ejercicios refresca el catalogo.
                    LaunchedEffect(Unit) { onExerciseCatalogRefreshRequest() }
                    val exerciseSubs = LocalSubscriptions.current
                    ExercisesTab(
                        requestedLibraryMode=libraryModeRequest,onLibraryModeRequestConsumed={libraryModeRequest=null},
                        onPlayWod={id,request ->onPlayWod(id,request) {navigateTab("inicio")}},
                        wodFavorites=overview?.wodTemplateFavorites.orEmpty(),onToggleWodFavorite=onToggleWodFavorite,
                        exerciseSummary=exerciseSummary,
                        exerciseSeries=exerciseSeries,onSetTestedOneRM=onSetTestedOneRM,
                        heartSeriesProvider = heartSeriesProvider,
                        onUpdateFinishedWorkout = onUpdateFinishedWorkout,
                        accountId = accountId, onArchiveChanged = onLiveActivitySaved,
                        busy = busy,
                        syncing = syncing,
                        status = status,
                        overview = overview,
                        activeWorkout = activeWorkout,
                        onQuickLog = onQuickLog,
                        onQuickLogOpened = onExerciseCatalogRefreshRequest,
                        onSaveQuickSets=onSaveQuickSets,
                        onSetExerciseFavorite = onSetExerciseFavorite,
                        onCreateExercise = {
                            val allowed = exerciseSubs?.policy?.canCreateCustomExercise(true)?.allowed == true
                            if (allowed) navController.navigate("ejercicio-nuevo")
                            else onOpenPaywallForCustomExercise()
                        },
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
                composable("ejercicio-nuevo") {
                    NewExerciseScreen(
                        busy = busy,
                        onBack = { navController.popBackStack() },
                        onCreate = { name, group, equip, target, secondary, desc, steps ->
                            onCreateCustomExercise(name, group, equip, target, secondary, desc, steps) {
                                navController.popBackStack()
                            }
                        }
                    )
                }
                composable("ajustes") {
                    BackHandler { navController.popBackStack() }
                    settingsContent { navController.popBackStack() }
                }
                composable("ajustes-objetivos") {
                    BackHandler { navController.popBackStack() }
                    val goalsScroll = rememberScrollState()
                    ProvideScrollDragAutoScroll(goalsScroll) {
                        Column(
                            Modifier
                                .fillMaxSize()
                                .verticalScroll(goalsScroll)
                                .padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            IconButton(
                                onClick = { navController.popBackStack() },
                                enabled = !busy,
                                modifier = Modifier
                                    .size(44.dp)
                                    .background(MaterialTheme.colorScheme.surfaceVariant, CircleShape)
                            ) {
                                Icon(
                                    Icons.AutoMirrored.Outlined.ArrowBack,
                                    contentDescription = "Volver",
                                    tint = MaterialTheme.colorScheme.onSurface
                                )
                            }
                            ReperaPageHeader(title = "Objetivos")
                            ReperaCard(Modifier.fillMaxWidth()) {
                                Column(Modifier.padding(16.dp)) {
                                    HealthGoalsSection(
                                        overview?.healthGoals ?: HealthGoals(),
                                        busy || overview == null,
                                        onUpdateHealthGoals
                                    )
                                }
                            }
                        }
                    }
                }
                composable("historial") {
                    CompleteHistoryScreen(
                        overview, busy, accountId,
                        onReviseFinishedSet, onDeleteFinishedSet, onDeleteWorkout,
                        onUpdateFinishedWorkout, heartSeriesProvider, externalHealthDetail,
                        onOpenExercise = { exerciseId, sessionId, instanceId ->
                            navController.navigate(
                                "ejercicio/" + Uri.encode(exerciseId) +
                                    "?sesion=" + Uri.encode(sessionId) +
                                    "&instancia=" + Uri.encode(instanceId)
                            )
                        },
                        onOpenSports = {
                            libraryModeRequest = "Deportes"
                            navController.navigate("ejercicios")
                        }
                    )
                }
                composable("peso-corporal") {
                    BodyWeightHistoryScreen(overview?.bodyWeightHistory.orEmpty(),busy,onLogBodyWeight,onDeleteBodyWeight,accountId)
                }
                composable("mensajes") {
                    LaunchedEffect(Unit) {onCenterRefresh()}
                    CenterMessagesScreen(centerConnected,centerLoading,centerSubmitting,centerError,centerSnapshot,onCenterRefresh,onSendCenterMessage)
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
                        var suggestedTitle by remember(accountId,routineId) {mutableStateOf<String?>(null)}
                        RoutineBlocksEditorScreen(accountId=accountId,
                            effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
                            routine = routine,
                            saveStatus=status,
                            exercises = overview?.exerciseEntries.orEmpty(),
                            busy = busy,
                            loadGuideProvider = loadGuideProvider,
                            importableRoutines = overview?.routineEntries.orEmpty(),
                            onTitleSuggested = { t ->
                                suggestedTitle=t
                            },
                            onReplace = { drafts ->
                                onReplaceRoutineBlocks(routineId, drafts,suggestedTitle) {navController.popBackStack()}
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
                    val requestId=androidx.compose.runtime.saveable.rememberSaveable(accountId,fecha,nombre) {java.util.UUID.randomUUID().toString()}
                    val draft = remember(accountId,fecha, nombre,requestId) {
                        // Semilla iOS HomeView: [.strength(title: "Bloque 1")].
                        RoutineEntry(
                            id = requestId,
                            title = nombre,
                            supported = true,
                            scheduledDate = fecha,
                            blocks = listOf(
                                RoutineBlockInfo(
                                    title = "Bloque 1",
                                    format = "",
                                    id = java.util.UUID.randomUUID().toString()
                                )
                            ))
                    }
                    var oneOffTitle by remember(fecha, nombre) { mutableStateOf<String?>(null) }
                    val oneOffMetaSnap = remember(fecha, nombre) {
                        arrayOf<Any?>(null, false, null)
                    }
                    RoutineBlocksEditorScreen(
                        accountId = accountId,
                        effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
                        routine = draft,
                        saveStatus = status,
                        exercises = overview?.exerciseEntries.orEmpty(),
                        busy = busy,
                        loadGuideProvider = loadGuideProvider,
                        importableRoutines = overview?.routineEntries.orEmpty(),
                        oneOffEditor = true,
                        scheduledDayIso = fecha,
                        pageTitle = "Crear entreno",
                        onTitleSuggested = { t -> oneOffTitle = t },
                        onOneOffMeta = { time, fav, pin ->
                            oneOffMetaSnap[0] = time
                            oneOffMetaSnap[1] = fav
                            oneOffMetaSnap[2] = pin
                        },
                        onReplace = { drafts ->
                            onSaveOneOffRoutine(
                                oneOffTitle ?: nombre,
                                drafts,
                                fecha,
                                draft.id,
                                oneOffMetaSnap[0] as Int?,
                                oneOffMetaSnap[1] as Boolean,
                                oneOffMetaSnap[2] as dev.repera.domain.WorkoutLocationPin?
                            ) { navController.popBackStack() }
                        },
                        onBack = {
                            restoreDayPlus = true
                            navController.popBackStack()
                        }
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
                        var quick by rememberSaveable(entry.id,accountId) {mutableStateOf(false)}
                        if(quick) QuickLogSheet(entry,accountId,busy,loadGuideProvider(entry.id,8,null)?.lastSession?.sets?.lastOrNull(),{quick=false}) {rows,notes,requestId ->
                            onSaveQuickSets(entry.id,rows,notes,requestId) {quick=false}
                        }
                        ExerciseDetailScreen(
                            entry = entry,
                            onQuickLog={quick=true},
                            onToggleFavorite={onSetExerciseFavorite(entry.id,!entry.isFavorite)},
                            testedOneRM = overview?.testedOneRMByExercise?.get(entry.id),
                            estimatedOneRM = overview?.exerciseProgress?.get(entry.id)?.estimatedOneRM,
                            incrementKg = overview?.trainingSettings?.weightIncrementKg ?: 2.5,
                            onSetTestedOneRM = {onSetTestedOneRM(entry.id,it)},
                            busy = busy,
                            exerciseSummary = exerciseSummary,
                            exerciseSeries = exerciseSeries,
                            highlightSessionId = highlightSessionId,
                            highlightInstanceId = highlightInstanceId,
                            sessionAppearances = sessionAppearances,
                            onBack = { navController.popBackStack() }
                        )
                    }
                }
            }
            if(expanded && currentRoute=="inicio" && showSettingsPanel) TrailingColumnPanel(onDismiss={showSettingsPanel=false}) {settingsContent(null)}
            val panelRoutine=routinePanelId?.let {id -> overview?.routineEntries?.firstOrNull {it.id==id}}
            if(expanded && currentRoute=="inicio" && routinePanelId!=null) {
                if(panelRoutine==null) LaunchedEffect(routinePanelId,overview) {routinePanelId=null}
                else TrailingColumnPanel(onDismiss={routinePanelId=null},closeLabel="‹ Cerrar rutina") {
                    var suggestedTitle by remember(accountId,panelRoutine.id) {mutableStateOf<String?>(null)}
                    RoutineBlocksEditorScreen(accountId=accountId,
                        effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
                        routine = panelRoutine,
                        saveStatus=status,
                        exercises = overview?.exerciseEntries.orEmpty(),
                        busy = busy,
                        loadGuideProvider = loadGuideProvider,
                        importableRoutines = overview?.routineEntries.orEmpty(),
                        onTitleSuggested = { t -> suggestedTitle=t },
                        onReplace = { drafts ->
                            onReplaceRoutineBlocks(panelRoutine.id, drafts,suggestedTitle) {routinePanelId=null}
                        },
                        onBack = { routinePanelId=null }
                    )
                }
            }
            }
        }
        }
    }
}


/** Account settings with persisted consumers; unresolved parity is tracked separately. */
@Composable
internal fun SettingsTab(
    busy: Boolean,
    onOpenAIAccess: () -> Unit,
    onImportJson: () -> Unit,
    onImportCsv: () -> Unit,
    overview:StateOverview? = null,
    onUpdateTrainingSettings:(TrainingSettings)->Unit = {},
    onUpdateHealthGoals:(HealthGoals)->Unit = {},
    onUpdateRotation:(dev.repera.domain.RotationPlan?)->Unit = {},
    onExportJson:()->Unit = {},
    onHealthConnect:()->Unit = {},
    onPrivateSleepChanged:(Boolean)->Unit = {},
    onPrivateCycleChanged:(Boolean)->Unit = {},
    onSignOut:()->Unit = {},
    onDeleteAccount:()->Unit = {},
    deletingAccount:Boolean = false,
    accountDeleteError:String? = null,
    onDismissAccountDeleteError:()->Unit = {},
    onOpenCenter:()->Unit = {},
    onOpenPro:()->Unit = {},
    onOpenBodyWeights:()->Unit = {},
    onOpenHistory:()->Unit = {},
    onOpenHealthGoals:()->Unit = {},
    proStatus:String? = null,
    onUpdateProfile:(ProfileSettings)->Unit = {},
    onBack: (() -> Unit)? = null
) {
    var confirmSignOut by remember {mutableStateOf(false)}
    var confirmDeleteAccount by remember {mutableStateOf(false)}
    if(confirmSignOut) androidx.compose.material3.AlertDialog(
        onDismissRequest={confirmSignOut=false},title={Text("¿Cerrar sesión?")},
        text={Text("Volverás al acceso con Google. Tus datos locales se conservan.")},
        confirmButton={androidx.compose.material3.TextButton(enabled=!busy,onClick={confirmSignOut=false;onSignOut()}) {Text("Cerrar sesión")}},
        dismissButton={androidx.compose.material3.TextButton(onClick={confirmSignOut=false}) {Text("Cancelar")}})
    if(confirmDeleteAccount) androidx.compose.material3.AlertDialog(
        onDismissRequest={if(!deletingAccount) confirmDeleteAccount=false},
        title={Text("¿Eliminar mi cuenta definitivamente?")},
        text={Text("Se eliminarán definitivamente tu cuenta y tus datos personales almacenados en Repera. Las empresas vinculadas conservarán como histórico de solo lectura los registros que ya tenían autorizados, sin acceso a tu cuenta ni posibilidad de generar actividad nueva. Esta acción no se puede deshacer. Health Connect y las suscripciones de Google Play se gestionan por separado.")},
        confirmButton={androidx.compose.material3.TextButton(
            enabled=!busy && !deletingAccount,
            onClick={confirmDeleteAccount=false;onDeleteAccount()}) {Text("Eliminar mi cuenta")}},
        dismissButton={androidx.compose.material3.TextButton(
            enabled=!deletingAccount,
            onClick={confirmDeleteAccount=false}) {Text("Cancelar")}})
    if(accountDeleteError!=null) androidx.compose.material3.AlertDialog(
        onDismissRequest=onDismissAccountDeleteError,
        title={Text("No se ha podido eliminar la cuenta")},
        text={Text(accountDeleteError)},
        confirmButton={androidx.compose.material3.TextButton(onClick=onDismissAccountDeleteError) {Text("Aceptar")}})

    val settingsScroll=rememberScrollState()
    ProvideScrollDragAutoScroll(settingsScroll) {
    Column(modifier = Modifier.fillMaxSize().verticalScroll(settingsScroll).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)) {
        if (onBack != null) {
            IconButton(
                onClick = onBack,
                enabled = !busy,
                modifier = Modifier
                    .size(44.dp)
                    .background(MaterialTheme.colorScheme.surfaceVariant, CircleShape)
                    .testTag("settings_back")
            ) {
                Icon(
                    Icons.AutoMirrored.Outlined.ArrowBack,
                    contentDescription = "Volver",
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
        }
        ReperaPageHeader(title = "Ajustes")
        val settingsSubs = LocalSubscriptions.current
        val settingsScope = rememberCoroutineScope()
        var restoreBusy by remember { mutableStateOf(false) }
        var restoreMessage by remember { mutableStateOf<String?>(null) }
        var accessFeedbackTitle by remember { mutableStateOf("Acceso Pro") }
        ReperaSectionTitle("Cuenta", uppercase = false)
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(vertical = 8.dp)) {
                ProfileSettingsSection(
                    overview?.profileSettings ?: ProfileSettings(),
                    busy || overview == null,
                    onUpdateProfile,
                    onRequestSignOut = { confirmSignOut = true }
                )
            }
        }
        ReperaSectionTitle("Centro y entrenador", uppercase = false)
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            SettingsListRow(
                title = "Buscar",
                leadingIcon = Icons.Outlined.Search,
                enabled = !busy,
                onClick = onOpenCenter
            )
        }
        ReperaSectionTitle("Acceso", uppercase = false)
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                when {
                    settingsSubs?.businessSponsoredAccess == true -> {
                        SettingsListRow(
                            title = "Acceso completo",
                            subtitle = "Incluido con tu centro o entrenador",
                            showChevron = false,
                            onClick = null
                        )
                    }
                    settingsSubs?.snapshot?.grantsProAccess == true -> {
                        SettingsListRow(
                            title = "Repera Pro activo",
                            subtitle = buildString {
                                proStatus?.let { append(it) }
                                settingsSubs.snapshot.expirationDate?.let { exp ->
                                    if (isNotEmpty()) append('\n')
                                    append("Renueva o finaliza: ")
                                    append(
                                        java.text.SimpleDateFormat(
                                            "d MMM yyyy",
                                            java.util.Locale("es", "ES")
                                        ).format(java.util.Date(exp))
                                    )
                                }
                            }.takeIf { it.isNotBlank() },
                            showChevron = false,
                            onClick = null
                        )
                    }
                    else -> {
                        SettingsListRow(
                            title = "Repera Pro",
                            subtitle = "O vincula un centro para acceso completo",
                            trailingIcon = Icons.Outlined.Lock,
                            showChevron = false,
                            onClick = null
                        )
                    }
                }
                if (settingsSubs?.businessSponsoredAccess != true) {
                    SettingsCardDivider()
                    SettingsListRow(
                        title = "Descubrir Pro",
                        enabled = !busy,
                        onClick = onOpenPro
                    )
                    SettingsCardDivider()
                    SettingsListRow(
                        title = if (restoreBusy) "Comprobando acceso…" else "Comprobar acceso Pro",
                        leadingIcon = Icons.Outlined.VerifiedUser,
                        enabled = !busy && !restoreBusy,
                        onClick = {
                            accessFeedbackTitle = "Comprobar acceso Pro"
                            restoreBusy = true
                            restoreMessage = null
                            settingsScope.launch {
                                val ok = settingsSubs?.restorePurchases() == true
                                restoreBusy = false
                                restoreMessage = when {
                                    ok -> "Acceso Pro actualizado"
                                    settingsSubs?.snapshot?.grantsProAccess == true ->
                                        "Acceso verificado en este dispositivo."
                                    else -> settingsSubs?.lastErrorMessage
                                        ?: "No se ha encontrado un acceso Pro activo."
                                }
                            }
                        }
                    )
                    SettingsCardDivider()
                    SettingsListRow(
                        title = "Restaurar compras",
                        enabled = !busy && !restoreBusy,
                        onClick = {
                            accessFeedbackTitle = "Restaurar compras"
                            restoreBusy = true
                            restoreMessage = null
                            settingsScope.launch {
                                val ok = settingsSubs?.restorePurchases() == true
                                restoreBusy = false
                                restoreMessage = if (ok) {
                                    "Suscripción restaurada."
                                } else {
                                    settingsSubs?.lastErrorMessage
                                        ?: "No se encontró ninguna suscripción."
                                }
                            }
                        }
                    )
                }
                SettingsCardDivider()
                SettingsListRow(
                    title = "Conecta tu IA",
                    leadingIcon = Icons.Outlined.Psychology,
                    enabled = !busy,
                    onClick = onOpenAIAccess
                )
            }
        }
        if (restoreMessage != null) {
            AlertDialog(
                onDismissRequest = { restoreMessage = null },
                title = { Text(accessFeedbackTitle) },
                text = { Text(restoreMessage.orEmpty()) },
                confirmButton = {
                    TextButton(onClick = { restoreMessage = null }) { Text("OK") }
                }
            )
        }
        ReperaSectionTitle("Salud", uppercase = false)
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            SettingsHealthRows(
                busy = busy,
                onHealthConnect = onHealthConnect,
                onOpenHealthGoals = onOpenHealthGoals,
                onOpenBodyWeights = onOpenBodyWeights,
                overviewReady = overview != null
            )
        }
        ReperaSectionTitle("Entrenamiento", uppercase = false)
        val training = overview?.trainingSettings ?: TrainingSettings()
        val trainingBusy = busy || overview == null
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                SettingsListRow(
                    title = "Historial",
                    enabled = !trainingBusy,
                    onClick = onOpenHistory
                )
                SettingsCardDivider()
                SettingsDropdownPickerRow(
                    label = "Unidad",
                    value = training.weightUnit,
                    options = listOf("kg" to "kg", "lb" to "lb"),
                    enabled = !trainingBusy,
                    onSelect = { onUpdateTrainingSettings(training.copy(weightUnit = it)) }
                )
                SettingsCardDivider()
                SettingsDropdownPickerRow(
                    label = "Semana empieza",
                    value = if (training.weekStartsOnMonday) "Lunes" else "Domingo",
                    options = listOf("Lunes" to "monday", "Domingo" to "sunday"),
                    enabled = !trainingBusy,
                    onSelect = {
                        onUpdateTrainingSettings(
                            training.copy(weekStartsOnMonday = it == "monday")
                        )
                    }
                )
                SettingsCardDivider()
                SettingsDropdownPickerRow(
                    label = "Esfuerzo (registro)",
                    value = training.effortUnit.uppercase(),
                    options = listOf("RIR" to "rir", "RPE" to "rpe"),
                    enabled = !trainingBusy,
                    onSelect = { onUpdateTrainingSettings(training.copy(effortUnit = it)) }
                )
            }
        }
        ReperaSectionTitle("Datos", uppercase = false)
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                SettingsTextActionRow(
                    text = "Exportar JSON",
                    enabled = !busy && overview != null,
                    onClick = onExportJson
                )
                SettingsCardDivider()
                SettingsTextActionRow(
                    text = "Importar JSON",
                    enabled = !busy && !deletingAccount,
                    onClick = onImportJson
                )
                SettingsCardDivider()
                SettingsTextActionRow(
                    text = "Importar CSV Strong/Hevy",
                    enabled = !busy && !deletingAccount,
                    onClick = onImportCsv
                )
                SettingsCardDivider()
                SettingsTextActionRow(
                    text = if (deletingAccount) "Eliminando cuenta…" else "Eliminar mi cuenta",
                    enabled = !busy && !deletingAccount,
                    destructive = true,
                    onClick = { confirmDeleteAccount = true },
                    modifier = Modifier.testTag("delete_account")
                )
            }
        }
    }
    }
}

@Composable
private fun SettingsDropdownPickerRow(
    label: String,
    value: String,
    options: List<Pair<String, String>>,
    enabled: Boolean,
    onSelect: (String) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        SettingsListRow(
            title = label,
            trailing = value,
            trailingColor = MaterialTheme.colorScheme.primary,
            showChevron = false,
            enabled = enabled,
            onClick = if (enabled) {{ expanded = true }} else null
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            options.forEach { (display, wire) ->
                DropdownMenuItem(
                    text = { Text(display) },
                    onClick = {
                        expanded = false
                        onSelect(wire)
                    }
                )
            }
        }
    }
}

@Composable
private fun SettingsHealthRows(
    busy: Boolean,
    onHealthConnect: () -> Unit,
    onOpenHealthGoals: () -> Unit,
    onOpenBodyWeights: () -> Unit,
    overviewReady: Boolean
) {
    val context = LocalContext.current
    var revision by remember { mutableIntStateOf(0) }
    val owner = androidx.lifecycle.compose.LocalLifecycleOwner.current
    DisposableEffect(owner) {
        val observer = androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_RESUME) revision++
        }
        owner.lifecycle.addObserver(observer)
        onDispose { owner.lifecycle.removeObserver(observer) }
    }
    var healthAuthorized by remember { mutableStateOf(false) }
    LaunchedEffect(revision) {
        healthAuthorized = runCatching {
            val reader = HealthConnectReader(context)
            reader.available() && reader.hasPermissions()
        }.getOrDefault(false)
    }
    @Suppress("UNUSED_VARIABLE") val observed = revision
    val locationGranted =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    val notificationsGranted = NotificationManagerCompat.from(context).areNotificationsEnabled()
    val locationLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { revision++ }
    val notificationsLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { revision++ }
    fun openAppSettings() {
        context.startActivity(
            Intent(
                android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${context.packageName}")
            )
        )
    }
    Column {
        SettingsListRow(
            title = "Notificaciones",
            trailing = if (notificationsGranted) "Permitidas" else "No permitidas",
            leadingIcon = Icons.Outlined.Notifications,
            showChevron = false,
            enabled = !busy,
            onClick = {
                if (Build.VERSION.SDK_INT >= 33 && !notificationsGranted) {
                    notificationsLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                } else {
                    openAppSettings()
                }
            }
        )
        SettingsCardDivider()
        SettingsListRow(
            title = if (healthAuthorized) "Health Connect" else "Conectar con Salud",
            leadingIcon = Icons.Outlined.FavoriteBorder,
            enabled = !busy,
            onClick = onHealthConnect
        )
        SettingsCardDivider()
        SettingsListRow(
            title = "Ubicación",
            trailing = if (locationGranted) "Permitida" else "No permitida",
            leadingIcon = Icons.Outlined.LocationOn,
            showChevron = false,
            enabled = !busy,
            onClick = {
                if (!locationGranted) {
                    locationLauncher.launch(
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        )
                    )
                } else {
                    openAppSettings()
                }
            }
        )
        SettingsCardDivider()
        SettingsListRow(
            title = "Objetivos",
            enabled = !busy && overviewReady,
            onClick = onOpenHealthGoals
        )
        SettingsCardDivider()
        SettingsListRow(
            title = "Peso",
            enabled = !busy && overviewReady,
            onClick = onOpenBodyWeights
        )
    }
}
