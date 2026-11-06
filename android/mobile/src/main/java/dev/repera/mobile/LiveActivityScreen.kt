package dev.repera.mobile

import androidx.compose.ui.res.stringResource
import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.LockOpen
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.Map
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.Timeline
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.ViewInAr
import androidx.compose.material.icons.outlined.VolumeOff
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material.icons.outlined.Whatshot
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.unit.IntOffset
import android.view.HapticFeedbackConstants
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import dev.repera.domain.LiveActivityState
import dev.repera.domain.ReperaNumberFormat
import dev.repera.domain.LiveSport
import dev.repera.mobile.analytics.ReperaAnalytics
import dev.repera.domain.LiveSportHistory
import dev.repera.domain.AdaptiveRoutePace
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.coroutines.withContext
import kotlin.math.roundToInt

/** Estado UI compartido con el shell para no dejar la tab bar operativa con candado activo. */
internal object LiveActivityTouchLockState {
    var locked by mutableStateOf(false)
}

/** Primer wiring ejecutable: no estima kcal/pulso ni escribe Salud.
 * Rutas, voz y revisión visual se completan por separado, no se ocultan. */
@Composable
internal fun LiveActivityScreen(accountId: String, onSaved: (sessionId: String) -> Unit,
    onSavedAndEdit: (sessionId: String) -> Unit = onSaved,
    onOpenTools: () -> Unit, onOpenCenter: (() -> Unit)? = null,
    hasActiveWorkout: Boolean = false, onOpenWorkout: () -> Unit = {},
    onMapRendered: (() -> Unit)? = null,
    onSavedDay: (Long) -> Unit = {},
    initialSportId: String? = null,
    /** Tras elegir deporte (clase sin plan): cuenta atrás automática como iOS. */
    autoStartAfterChoose: Boolean = false,
    onInitialSportConsumed: () -> Unit = {},
    onAutoStartConsumed: () -> Unit = {}) {
    val context=LocalContext.current
    val scope = rememberCoroutineScope()
    val subscriptions = dev.repera.mobile.monetization.LocalSubscriptions.current
    // La comprobación es reactiva y se basa en el entitlement efectivo, no en SharedPreferences.
    val canNavigate3D = subscriptions?.policy?.canUse3DNavigation == true
    var checking3DAccess by remember { mutableStateOf(false) }
    var show3DAccessVerificationError by remember { mutableStateOf(false) }
    if (show3DAccessVerificationError) {
        AlertDialog(
            onDismissRequest = { show3DAccessVerificationError = false },
            title = { Text(stringResource(R.string.live_activity_screen_no_se_pudo_comprobar_pro)) },
            text = { Text(stringResource(R.string.live_activity_screen_no_se_ha_podido_verificar_tu)) },
            confirmButton = {
                TextButton(onClick = { show3DAccessVerificationError = false }) { Text(stringResource(R.string.live_activity_screen_aceptar)) }
            }
        )
    }
    // Paridad iOS AppStorage("repera.live.map.navigation3D.enabled").
    val mapPrefs = remember {
        context.getSharedPreferences("repera.live.map", android.content.Context.MODE_PRIVATE)
    }
    var navigationMode by remember {
        // R8: default 2D como iOS AppStorage navigation3D.enabled = false.
        mutableStateOf(mapPrefs.getBoolean("navigation3D.enabled", false))
    }
    fun setNavigationMode(enabled: Boolean) {
        navigationMode = enabled
        mapPrefs.edit().putBoolean("navigation3D.enabled", enabled).apply()
        ReperaAnalytics.track(
            ReperaAnalytics.Event.NAVIGATION_MODE_CHANGED,
            mapOf(
                "feature_area" to "live_sport",
                "action_name" to if (enabled) "nav_3d" else "nav_2d",
                "result" to "success"
            )
        )
    }
    var followingMap by remember { mutableStateOf(true) }
    var recenterToken by remember { mutableStateOf(0) }
    val effectiveNavigationMode = canNavigate3D && navigationMode
    LaunchedEffect(canNavigate3D) {
        // Si Pro caduca o se revoca mientras navega, volver inmediatamente al 2D.
        // La preferencia 3D puede recuperarse tras restaurar la suscripción.
        if (!canNavigate3D && navigationMode) {
            followingMap = true
            recenterToken++
        }
    }
    var lastUserMapMoveAt by remember { mutableLongStateOf(0L) }
    // No volver a centrar durante el gesto ni durante sus 5 segundos de reposo.
    // LaunchedEffect cancela el temporizador anterior ante cada nuevo movimiento.
    LaunchedEffect(followingMap, lastUserMapMoveAt) {
        if (!followingMap) {
            delay(LiveMapCamera.FOLLOW_RESUME_DELAY_MS)
            if (LiveMapCamera.shouldResumeFollowing(
                followingMap, lastUserMapMoveAt, android.os.SystemClock.elapsedRealtime()
            )) {
                followingMap = true
                recenterToken++
            }
        }
    }
    var previewPosition by remember { mutableStateOf<dev.repera.domain.WorkoutRoutePoint?>(null) }
    // Apple 3f84691a: el cronometro del mapa/metricas avanza de forma continua
    // (1 Hz) incluso sin fixes GPS (deporte indoor o senal perdida); la pausa
    // congela la duracion por diseno (tiempo activo).
    var nowTick by remember { mutableStateOf(System.currentTimeMillis()) }
    var previewMessage by remember { mutableStateOf<String?>(null) }
    // Cuenta atrás 3-2-1 antes de empezar (paridad beginStartCountdown iOS).
    var startCountdown by remember { mutableStateOf(0) }
    var startCountdownToken by remember { mutableStateOf(0) }
    fun capturePosition() { scope.launch {
        val pin = runCatching { WorkoutLocationTracker(context).capturePin() }.getOrNull()
        followingMap=true;recenterToken++
        previewPosition = pin?.let { dev.repera.domain.WorkoutRoutePoint(0,it.latitude,it.longitude,System.currentTimeMillis()) }
        previewMessage = if (pin == null) "Sin posición GPS disponible. El mapa no representa tu ubicación." else null
    } }
    val centerPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { capturePosition() }

    if(accountId.isBlank()) { Text(stringResource(R.string.live_activity_screen_inicia_sesion_para_guardar_actividades));return }
    // Altura real del chrome (menú + Continuar). Sin sumar navigationBars otra vez:
    // tabChromeInset ya incluye nav bars medidos en el host.
    val tabChromeInset = LocalReperaTabBarInset.current
    val runtime=remember(accountId) { LiveActivityRuntime.forAccount(context,accountId) }
    val revision by runtime.updates.collectAsStateWithLifecycle()
    // Leer antes de cualquier retorno (también canvas GPS): los campos de
    // recorder son puros, la señal Flow invalida todas las ramas de UI.
    @Suppress("UNUSED_VARIABLE") val observedRevision = revision
    val state=runtime.state
    val sessionActive = state.phase == LiveActivityState.Phase.RECORDING ||
        state.phase == LiveActivityState.Phase.PAUSED
    // En sesión el menú está oculto: no usar tabChromeInset (deja un hueco enorme).
    // Solo un aire mínimo sobre el home indicator / gesture bar.
    val bottomChromePad = when {
        sessionActive || state.phase == LiveActivityState.Phase.REVIEW -> 8.dp
        tabChromeInset > 0.dp -> tabChromeInset
        else -> 96.dp
    }
    val maxHeartRateBpm by produceState(initialValue = 190, accountId) {
        value = withContext(Dispatchers.IO) {
            trainingSettingsForAccount(context, accountId).heartRateMaxBpm ?: 190
        }
    }
    // Mantener el último rumbo medido dentro de la misma sesión. Un fix sin
    // avance no debe hacer girar el mapa de vuelta hacia el norte.
    var lastReliableHeading by remember(state.gpsSessionID, state.sport.id) {
        mutableStateOf<Double?>(null)
    }
    val currentMeasuredHeading = LiveMapCamera.measuredHeading(state.points)
    val compassHeading = rememberLiveMapCompassHeading(
        enabled = state.sport.usesGPS && state.phase == LiveActivityState.Phase.IDLE,
        latitude = previewPosition?.latitude, longitude = previewPosition?.longitude
    )
    LaunchedEffect(currentMeasuredHeading) {
        if (currentMeasuredHeading != null) lastReliableHeading = currentMeasuredHeading
    }
    var pendingAutoStart by remember { mutableStateOf(false) }
    LaunchedEffect(initialSportId, state.phase) {
        val sportId = initialSportId ?: return@LaunchedEffect
        if (state.phase != LiveActivityState.Phase.IDLE) {
            onInitialSportConsumed()
            if (autoStartAfterChoose) onAutoStartConsumed()
            return@LaunchedEffect
        }
        LiveSport.byId(sportId)?.let {
            runtime.choose(it)
            if (autoStartAfterChoose) pendingAutoStart = true
        }
        onInitialSportConsumed()
        if (autoStartAfterChoose) onAutoStartConsumed()
    }
    LaunchedEffect(state.phase) {
        while (state.phase == LiveActivityState.Phase.RECORDING ||
            state.phase == LiveActivityState.Phase.PAUSED) {
            delay(1000L)
            nowTick = System.currentTimeMillis()
        }
    }
    val routesStore = remember(accountId) { runCatching { LiveRoutesStore(context, accountId) }.getOrNull() }
    var routesVersion by remember { mutableStateOf(0) }
    // Se utiliza en la importación de GPX por LaunchedEffect: debe declararse antes.
    var error by remember { mutableStateOf<String?>(null) }
    var showRoutes by remember { mutableStateOf(false) }
    var pendingDeleteRoute by remember { mutableStateOf<LiveSavedRoute?>(null) }
    LaunchedEffect(routesStore) {
        if (routesStore != null) {
            try { kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                val overview = StateOverview.fromBytes(LocalSnapshotStore(context, accountId).read())
                val candidates = overview?.liveSportSessions.orEmpty().mapNotNull { session ->
                    val routeID = session.liveRouteID ?: return@mapNotNull null
                    val detail = overview?.completeHistory?.firstOrNull { it.id == session.id } ?: return@mapNotNull null
                    if (detail.routePoints.size < 2) return@mapNotNull null
                    LiveSavedRoute(id = routeID, title = detail.title, points = detail.routePoints,
                        sportID = session.sportID, createdAtMillis = session.startedEpochMillis ?: Long.MIN_VALUE)
                }
                routesStore.recoverFromSessions(candidates) };routesVersion++
            } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled
            } catch (_: Exception) { /* Keep prior routes; no destructive recovery. */ }
        }
    }
    // System share / “Open with…” GPX: prefs written by MainActivity → import once.
    LaunchedEffect(routesStore, accountId) {
        val store = routesStore ?: return@LaunchedEffect
        val pending = withContext(Dispatchers.IO) { SystemImportPending.takeGpx(context) } ?: return@LaunchedEffect
        try {
            val bytes = withContext(Dispatchers.IO) {
                require(pending.file.length() <= 16L * 1024L * 1024L)
                pending.file.readBytes()
            }
            store.addGPX(bytes, pending.displayName.substringBeforeLast('.', pending.displayName))
            withContext(Dispatchers.IO) { pending.file.delete() }
            routesVersion++
            error = null
        } catch (cancelled: kotlinx.coroutines.CancellationException) {
            throw cancelled
        } catch (_: Exception) {
            error = "No se pudo importar el GPX compartido (máximo 16 MB)."
        }
    }
    val routes by produceState<List<LiveSavedRoute>>(emptyList(), routesStore, routesVersion) {
        value = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
            routesStore?.recentRoutes(runCatching {
                val bytes = LocalSnapshotStore(context, accountId).read()
                bytes?.let { LiveSportSnapshot.sessions(org.json.JSONObject(String(it, Charsets.UTF_8))) }.orEmpty()
            }.getOrDefault(emptyList())).orEmpty()
        }
    }
    var title by androidx.compose.runtime.saveable.rememberSaveable(accountId) { mutableStateOf("") }
    var notes by androidx.compose.runtime.saveable.rememberSaveable(accountId) { mutableStateOf("") }
    var savingActivity by remember { mutableStateOf(false) }
    var confirmDiscard by remember { mutableStateOf(false) }
    var showSportPicker by remember { mutableStateOf(false) }
    var showStartOptions by remember(accountId) { mutableStateOf(false) }
    var confirmFinish by remember(accountId) { mutableStateOf(false) }
    var sportQuery by remember {mutableStateOf("")}
    var showingMetrics by remember(accountId) {
        mutableStateOf(true)
    }
    /** Pager en vivo: 0 opciones · 1 centro · 2 opuesto (si GPS). */
    var liveSessionPage by remember(accountId) { mutableIntStateOf(1) }
    var touchLocked by remember(accountId, state.gpsSessionID) { mutableStateOf(false) }
    val touchLockAvailable = state.phase == LiveActivityState.Phase.RECORDING ||
        state.phase == LiveActivityState.Phase.PAUSED
    var lockTarget by remember { mutableStateOf<Rect?>(null) }
    var lockContainer by remember { mutableStateOf<Rect?>(null) }
    val rootView = LocalView.current
    fun lockTouch() {
        touchLocked = true
        rootView.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
    }
    fun unlockTouch() {
        touchLocked = false
        rootView.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
    }
    BackHandler(enabled = touchLocked) { /* La flecha física tampoco cierra la sesión accidentalmente. */ }
    LaunchedEffect(state.phase) {
        if (!touchLockAvailable) { touchLocked = false; liveSessionPage = 1 }
        if (state.phase == LiveActivityState.Phase.RECORDING) {
            showStartOptions = false
            liveSessionPage = 1
        }
    }
    LaunchedEffect(showingMetrics) {
        if (touchLockAvailable) liveSessionPage = 1
    }
    DisposableEffect(touchLocked, touchLockAvailable, rootView) {
        val keepAwake = touchLocked && touchLockAvailable
        LiveActivityTouchLockState.locked = keepAwake
        if (keepAwake) rootView.keepScreenOn = true
        onDispose {
            if (keepAwake) rootView.keepScreenOn = false
            if (keepAwake) LiveActivityTouchLockState.locked = false
        }
    }

    // Pulso medido y reciente, solo mientras hay sesión activa.
    // Android no inventa FC cuando Salud no tiene lecturas sincronizadas.
    var liveHeartRateBpm by remember(accountId) { mutableStateOf<Int?>(null) }
    LaunchedEffect(accountId, state.gpsSessionID, state.phase) {
        liveHeartRateBpm = null
        val start = state.startedMillis
        if (start != null && (state.phase == LiveActivityState.Phase.RECORDING ||
                state.phase == LiveActivityState.Phase.PAUSED)) {
            val reader = HealthConnectReader(context)
            while (true) {
                val measured = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                    runCatching { reader.latestHeartRateBpm(start) }.getOrNull()
                }
                // El efecto se cancela al cambiar fase o UUID; no se conserva FC anterior.
                liveHeartRateBpm = measured
                delay(5_000L)
            }
        }
    }
    // Sensor Wear enlazado a la sesión actual tiene prioridad; Health Connect es respaldo.
    // Cuando se desconecta, la lectura del reloj caduca automáticamente a los 20 s.
    val displayedHeartRateBpm = runtime.currentWearHeartRateBpm(nowTick) ?: liveHeartRateBpm
    var previewHealth by remember { mutableStateOf<dev.repera.domain.SessionCardioSample?>(null) }
    LaunchedEffect(state.phase, state.gpsSessionID) {
        previewHealth = null
        if (state.phase == LiveActivityState.Phase.REVIEW) {
            val start = state.startedMillis
            val end = state.finishedMillis
            if (start != null && end != null) {
                previewHealth = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                    // Solo permisos ya concedidos, sesión inequívoca y datos
                    // medidos. No se pide acceso ni escribe Salud al revisar.
                    runCatching { HealthConnectReader(context).readSessionSample(start, end) }.getOrNull()
                }
            }
        }
    }
    fun startService() {
        try { LiveActivityService.startFromVisibleUI(context,accountId) }
        catch (_: Exception) { runtime.pause();error="No se pudo mantener el registro en segundo plano. La actividad queda en pausa." }
    }
    // Título sugerido al pasar a revisión, sin invadir lo que escriba el usuario.
    LaunchedEffect(state.phase, state.gpsSessionID) {
        if (state.phase == LiveActivityState.Phase.REVIEW) {
            val defaultName = state.sport.title
            if (title.isBlank()) title = defaultName
            val suggestion = LiveActivityLocationName.suggest(context, state.sport, state.points)
            if (!suggestion.isNullOrBlank() && (title.isBlank() || title == defaultName)) {
                title = suggestion
            }
        }
    }
    val currentActiveWorkout by rememberUpdatedState(hasActiveWorkout)
    val currentOpenWorkout by rememberUpdatedState(onOpenWorkout)
    fun start() {
        // También comprobar tras volver del diálogo de permiso, no solo
        // antes: puede haberse reactivado un entreno clásico mientras tanto.
        if (currentActiveWorkout) { currentOpenWorkout();return }
        if (runtime.recoveryBlocked) { error=runtime.lastError;return }
        runtime.start();startService()
    }
    fun cancelStartCountdown() {
        startCountdownToken++
        startCountdown = 0
    }
    /** Los tres pitidos son los del temporizador; el GPS empieza DESPUÉS.
     * Si la preferencia de cuenta atrás está off, arranca al instante. */
    fun beginStartCountdown() {
        if (currentActiveWorkout) { currentOpenWorkout(); return }
        if (runtime.recoveryBlocked) { error = runtime.lastError; return }
        if (startCountdown > 0 || state.phase != LiveActivityState.Phase.IDLE) return
        if (!runtime.startCountdownEnabled) {
            start()
            return
        }
        startCountdownToken++
        startCountdown = 3
        LiveStartFeedback.tick(context, 3, sound = runtime.spokenGuidanceEnabled)
    }
    LaunchedEffect(pendingAutoStart, state.phase, state.sport.id) {
        if (!pendingAutoStart) return@LaunchedEffect
        if (state.phase != LiveActivityState.Phase.IDLE) {
            pendingAutoStart = false
            return@LaunchedEffect
        }
        pendingAutoStart = false
        beginStartCountdown()
    }
    LaunchedEffect(startCountdownToken) {
        val token = startCountdownToken
        if (startCountdown <= 0) return@LaunchedEffect
        for (second in listOf(2, 1, 0)) {
            delay(1000L)
            if (token != startCountdownToken || state.phase != LiveActivityState.Phase.IDLE) return@LaunchedEffect
            startCountdown = second
            if (second > 0) {
                LiveStartFeedback.tick(context, second, sound = runtime.spokenGuidanceEnabled)
            } else {
                LiveStartFeedback.complete(context, sound = runtime.spokenGuidanceEnabled)
                start()
            }
        }
    }
    val notificationPermission=rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {}
    var confirmRecordingWithoutGPS by remember(accountId) { mutableStateOf(false) }
    val permissions=rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        if (grants.values.any { it }) beginStartCountdown()
        else confirmRecordingWithoutGPS = true
    }
    if (confirmRecordingWithoutGPS) {
        AlertDialog(
            onDismissRequest = { confirmRecordingWithoutGPS = false },
            title = { Text(stringResource(R.string.live_activity_screen_ubicacion_no_autorizada)) },
            text = { Text(stringResource(R.string.live_activity_screen_puedes_registrar_el_tiempo_sin_recorrido)) },
            confirmButton = {
                TextButton(onClick = {
                    confirmRecordingWithoutGPS = false
                    beginStartCountdown()
                }) { Text(stringResource(R.string.live_activity_screen_continuar_sin_gps)) }
            },
            dismissButton = {
                TextButton(onClick = { confirmRecordingWithoutGPS = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            }
        )
    }
    val importGPX = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            try {
                val name = context.contentResolver.query(uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getString(0) else null
                } ?: "Ruta GPX"
                val bytes = context.contentResolver.openInputStream(uri)?.use { input ->
                    // Límite de bytes además del tope de puntos; no agotar memoria
                    // con un archivo seleccionado accidentalmente.
                    val output = java.io.ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        output.write(buffer, 0, count)
                        require(output.size() <= 16 * 1024 * 1024)
                    }
                    output.toByteArray()
                } ?: error("No se pudo abrir el archivo")
                require(bytes.size <= 16 * 1024 * 1024)
                routesStore?.addGPX(bytes, name.substringBeforeLast('.', name)) ?: error("Almacén no disponible")
                routesVersion++;error = null
            } catch (_: Exception) { error = "No se pudo importar el GPX. Comprueba el archivo y el almacenamiento (máximo 16 MB)." }
        }
    }
    LaunchedEffect(runtime) {
        while(true) { delay(1000);runtime.publish() }
    }
    if (showStartOptions && state.phase == LiveActivityState.Phase.IDLE) {
        ReperaModalBottomSheet(onDismissRequest = { showStartOptions = false }) {
            LiveIdleOptionsSheet(
                audioEnabled = runtime.spokenGuidanceEnabled,
                countdownEnabled = runtime.startCountdownEnabled,
                showMap = !showingMetrics,
                hasGPS = state.sport.usesGPS,
                onClose = { showStartOptions = false },
                onAudio = { runtime.toggleSpokenGuidance() },
                onCountdown = { runtime.toggleStartCountdown() },
                onMap = { showingMetrics = !it },
                onRoute = {
                    showStartOptions = false
                    showRoutes = true
                }
            )
        }
    }
    if (showSportPicker) {
        // R8 P1-6: sheet alto tipo iOS LiveSportPicker — ✕, tarjetas, búsqueda abajo.
        @OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
        ReperaModalBottomSheet(onDismissRequest = { showSportPicker = false }) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(0.92f)
                    .padding(horizontal = 16.dp)
                    .padding(top = 8.dp, bottom = 12.dp)
            ) {
                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        stringResource(R.string.live_activity_screen_elegir_actividad),
                        style = MaterialTheme.typography.titleLarge,
                        modifier = Modifier.weight(1f)
                    )
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.Close,
                        contentDescription = stringResource(R.string.action_close),
                        onClick = { showSportPicker = false },
                        modifier = Modifier.testTag("sport_picker_close")
                    )
                }
                Column(
                    Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState())
                        .padding(top = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    LiveSport.groups.forEach { group ->
                        val filtered = LiveSport.selectableCases.filter {
                            it.group == group && foldForSearch(it.title).contains(foldForSearch(sportQuery))
                        }
                        if (filtered.isNotEmpty()) {
                            Text(
                                group,
                                style = MaterialTheme.typography.titleSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(top = 12.dp, bottom = 4.dp)
                            )
                        }
                        filtered.forEach { sport ->
                            Surface(
                                onClick = {
                                    runtime.choose(sport)
                                    ReperaAnalytics.track(
                                        ReperaAnalytics.Event.ACTIVITY_SELECTED,
                                        mapOf(
                                            "feature_area" to "live_sport",
                                            "activity_type" to sport.id,
                                            "activity_family" to ReperaAnalytics.activityFamily(sport.group)
                                        )
                                    )
                                    showSportPicker = false
                                },
                                shape = RoundedCornerShape(14.dp),
                                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("choose_sport_${sport.id}")
                            ) {
                                Row(
                                    Modifier.padding(horizontal = 12.dp, vertical = 12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        sport.materialIcon,
                                        contentDescription = null,
                                        tint = brandGreen,
                                        modifier = Modifier.size(28.dp)
                                    )
                                    Spacer(Modifier.width(12.dp))
                                    Column(Modifier.weight(1f)) {
                                        Text(
                                            sport.title,
                                            style = MaterialTheme.typography.bodyLarge,
                                            fontWeight = FontWeight.Medium,
                                            color = MaterialTheme.colorScheme.onSurface
                                        )
                                        Text(
                                            sport.metricDescription,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                                            maxLines = 2
                                        )
                                    }
                                    if (state.sport == sport) {
                                        Text("✓", color = brandGreen, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                            Spacer(Modifier.height(6.dp))
                        }
                    }
                }
                ReperaMetaTextField(
                    caption = "Buscar actividad",
                    value = sportQuery,
                    onValueChange = { sportQuery = it },
                    placeholder = stringResource(R.string.live_activity_screen_buscar_actividad),
                    modifier = Modifier
                        .padding(top = 8.dp)
                        .testTag("sport_picker_search")
                )
            }
        }
    }
    if (showRoutes) {
        BackHandler { showRoutes = false }
        Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
            Column(
                Modifier.fillMaxSize().statusBarsPadding()
                    .padding(start = 20.dp, end = 20.dp, bottom = bottomChromePad),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Row(Modifier.fillMaxWidth().padding(top = 20.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    Text("Mis rutas", style = MaterialTheme.typography.headlineLarge,
                        modifier = Modifier.weight(1f))
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.Close,
                        contentDescription = "Cerrar Mis rutas",
                        onClick = { showRoutes = false }
                    )
                }
                TextButton(onClick = {
                    importGPX.launch(arrayOf(
                        "application/gpx+xml", "application/xml", "text/xml",
                        "application/octet-stream"
                    ))
                }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                    Icon(Icons.Outlined.Route, null)
                    Spacer(Modifier.width(10.dp))
                    Text("Importar archivo GPX")
                }
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (routes.isEmpty()) {
                        ReperaEmptyState(
                            title = stringResource(R.string.live_activity_screen_todavia_no_hay_rutas),
                            subtitle = stringResource(R.string.live_activity_screen_graba_un_recorrido_o_importa_un)
                        )
                    }
                    val recentRoutes = routesStore?.latestRoutes?.take(5).orEmpty()
                    val favorites = routesStore?.favoriteRoutes.orEmpty()
                    if (recentRoutes.isNotEmpty()) {
                        Text("Últimas rutas", style = MaterialTheme.typography.titleLarge)
                        recentRoutes.forEach { route ->
                            ReperaCard(
                                onClick = { runtime.selectRoute(route.id); showRoutes = false },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(Modifier.padding(16.dp)) {
                                    Text(route.title, style = MaterialTheme.typography.titleMedium)
                                    Text("${ReperaNumberFormat.decimal(route.distanceKm)} km · ${route.sportTitle}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                    if (favorites.isNotEmpty()) {
                        Text("Favoritos", style = MaterialTheme.typography.titleLarge)
                        favorites.forEach { route ->
                            ReperaCard(
                                onClick = { runtime.selectRoute(route.id); showRoutes = false },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(Modifier.padding(16.dp)) {
                                    Text(route.title, style = MaterialTheme.typography.titleMedium)
                                    Text("${ReperaNumberFormat.decimal(route.distanceKm)} km · ${route.sportTitle}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                }
            }
        }
        return
    }
    pendingDeleteRoute?.let { route ->
        AlertDialog(onDismissRequest = { pendingDeleteRoute = null },
            title = { Text(stringResource(R.string.live_activity_screen_eliminar_ruta)) }, text = { Text(stringResource(R.string.live_activity_screen_se_borrara_la_ruta_guardada_tus)) },
            confirmButton = { TextButton(onClick = {
                try {
                    routesStore?.remove(route.id)
                    if (state.selectedRouteID == route.id) runtime.selectRoute(null)
                    routesVersion++;pendingDeleteRoute = null
                } catch (_: Exception) { error = "No se pudo eliminar la ruta." }
            }) { Text(stringResource(R.string.action_delete)) } },
            dismissButton = { TextButton(onClick = { pendingDeleteRoute = null }) { Text(stringResource(R.string.action_cancel)) } })
    }
    if (confirmFinish) {
        ReperaConfirmSheet(
            title = "¿Finalizar actividad?",
            message = "Puedes revisar y guardar tus datos al finalizar.",
            confirmTitle = "Finalizar y revisar",
            icon = Icons.Outlined.Flag,
            confirmDestructive = false,
            onConfirm = {
                confirmFinish = false
                runtime.finish()
                LiveActivityService.stop(context)
            },
            onCancel = { confirmFinish = false }
        )
    }
    if (confirmDiscard) {
        ReperaConfirmSheet(
            title = stringResource(R.string.live_activity_screen_descartar_actividad_2),
            message = stringResource(R.string.live_activity_screen_perderas_el_recorrido_y_los_datos),
            confirmTitle = stringResource(R.string.live_activity_screen_descartar_sin_guardar),
            onConfirm = {
                if (runtime.discard()) {
                    LiveActivityService.stop(context)
                    title = ""
                    notes = ""
                    showingMetrics = true
                }
                confirmDiscard = false
            },
            onCancel = { confirmDiscard = false }
        )
    }
    // Cuenta atrás en el botón Iniciar (sustituye el icono play); sin diálogo modal.
    // Idle GPS: auto-centrar como LiveActivityView (.userLocation) al entrar.
    LaunchedEffect(accountId, state.phase, state.sport.usesGPS) {
        if (state.phase == LiveActivityState.Phase.IDLE && state.sport.usesGPS) {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED) {
                capturePosition()
            }
        }
    }
    // Condiciones Open-Meteo (marea/nieve) para Wear + franja Guardar.
    LaunchedEffect(
        state.phase,
        state.sport.id,
        state.points.lastOrNull()?.id,
        state.points.size
    ) {
        if (state.phase != LiveActivityState.Phase.RECORDING &&
            state.phase != LiveActivityState.Phase.PAUSED &&
            state.phase != LiveActivityState.Phase.REVIEW
        ) return@LaunchedEffect
        val force = state.phase == LiveActivityState.Phase.REVIEW
        if (!runtime.shouldRefreshConditions(force)) return@LaunchedEffect
        val point = state.points.lastOrNull() ?: return@LaunchedEffect
        OpenMeteoWeatherClient.fetchConditions(
            point.latitude, point.longitude, state.sport.id
        ).onSuccess { runtime.updateLiveConditions(it) }
    }
    // Sesión en vivo: pager Opciones | Centro | Opuesto (paridad iOS liveSessionPager).
    if (sessionActive && !showRoutes && state.phase != LiveActivityState.Phase.REVIEW) {
        val pageCount = if (state.sport.usesGPS) 3 else 2
        val pagerState = rememberPagerState(
            initialPage = liveSessionPage.coerceIn(0, pageCount - 1),
            pageCount = { pageCount }
        )
        LaunchedEffect(pagerState.currentPage) { liveSessionPage = pagerState.currentPage }
        LaunchedEffect(liveSessionPage, pageCount) {
            val target = liveSessionPage.coerceIn(0, pageCount - 1)
            if (pagerState.currentPage != target) {
                pagerState.scrollToPage(target)
            }
        }
        val centerIsMetrics = showingMetrics || !state.sport.usesGPS
        val pageShowsMap = (pagerState.currentPage == 1 && !centerIsMetrics) ||
            (pagerState.currentPage == 2 && centerIsMetrics)
        val onToggleLiveMap3D: () -> Unit = {
            if (checking3DAccess) Unit
            else if (canNavigate3D) {
                setNavigationMode(!navigationMode)
                followingMap = true
                recenterToken++
            } else {
                checking3DAccess = true
                scope.launch {
                    try {
                        subscriptions?.refreshEntitlementsForFeatureAction()
                        when {
                            subscriptions?.policy?.canUse3DNavigation == true -> {
                                setNavigationMode(true)
                                followingMap = true
                                recenterToken++
                            }
                            else -> show3DAccessVerificationError = true
                        }
                    } catch (_: Exception) {
                        show3DAccessVerificationError = true
                    } finally {
                        checking3DAccess = false
                    }
                }
            }
        }
        Box(
            Modifier
                .fillMaxSize()
                // Mapa como idle (sin statusBars en el root); métricas/opciones sí.
                .then(if (pageShowsMap) Modifier else Modifier.statusBarsPadding())
                .onGloballyPositioned { lockContainer = it.boundsInRoot() }
                .testTag("live_activity_screen")
        ) {
            // Mismo mapa que idle: detrás del pager, no dentro de una página.
            if (pageShowsMap) {
                LiveSessionMapPane(
                    state = state,
                    routes = routes,
                    previewPosition = previewPosition,
                    effectiveNavigationMode = effectiveNavigationMode,
                    canNavigate3D = canNavigate3D,
                    followingMap = followingMap,
                    recenterToken = recenterToken,
                    compassHeading = compassHeading,
                    currentMeasuredHeading = currentMeasuredHeading,
                    lastReliableHeading = lastReliableHeading,
                    nowTick = nowTick,
                    onMapRendered = onMapRendered,
                    onToggle3D = onToggleLiveMap3D,
                    onCameraGesture = {
                        followingMap = false
                        lastUserMapMoveAt = android.os.SystemClock.elapsedRealtime()
                    }
                )
            }
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.fillMaxSize(),
                userScrollEnabled = !touchLocked && !pageShowsMap,
                beyondViewportPageCount = 0
            ) { page ->
                when (page) {
                    0 -> LiveSessionOptionsPane(
                        audioEnabled = runtime.spokenGuidanceEnabled,
                        countdownEnabled = runtime.startCountdownEnabled,
                        showMap = !showingMetrics,
                        hasGPS = state.sport.usesGPS,
                        routeTitle = routes.firstOrNull { it.id == state.selectedRouteID }?.title,
                        onAudio = { runtime.toggleSpokenGuidance() },
                        onCountdown = { runtime.toggleStartCountdown() },
                        onMap = { showingMetrics = !it },
                    )
                    1 -> if (centerIsMetrics) {
                        LiveSessionMetricsPane(
                            state = state,
                            nowTick = nowTick,
                            displayedHeartRateBpm = displayedHeartRateBpm,
                            maxHeartRateBpm = maxHeartRateBpm,
                            includeSplits = state.sport.usesGPS
                        )
                    } else {
                        Box(Modifier.fillMaxSize()) // mapa detrás
                    }
                    else -> if (centerIsMetrics) {
                        Box(Modifier.fillMaxSize()) // mapa detrás
                    } else {
                        LiveSessionMetricsPane(
                            state = state,
                            nowTick = nowTick,
                            displayedHeartRateBpm = displayedHeartRateBpm,
                            maxHeartRateBpm = maxHeartRateBpm,
                            includeSplits = true
                        )
                    }
                }
            }
            // Métricas del mapa encima de Play (fijas); puntos debajo.
            // El mapa captura el swipe del pager: el chrome inferior cambia de página.
            Column(
                Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .padding(bottom = bottomChromePad)
                    .pointerInput(touchLocked, pagerState.currentPage, pageCount) {
                        if (touchLocked) return@pointerInput
                        var horizontalDistance = 0f
                        detectHorizontalDragGestures(
                            onDragStart = { horizontalDistance = 0f },
                            onHorizontalDrag = { change, delta ->
                                horizontalDistance += delta
                                change.consume()
                            },
                            onDragEnd = {
                                val target = when {
                                    horizontalDistance < -70f ->
                                        (pagerState.currentPage + 1).coerceAtMost(pageCount - 1)
                                    horizontalDistance > 70f ->
                                        (pagerState.currentPage - 1).coerceAtLeast(0)
                                    else -> pagerState.currentPage
                                }
                                horizontalDistance = 0f
                                if (target != pagerState.currentPage) {
                                    scope.launch { pagerState.animateScrollToPage(target) }
                                }
                            },
                            onDragCancel = { horizontalDistance = 0f }
                        )
                    }
            ) {
                if (pageShowsMap) {
                    Surface(
                        Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 14.dp)
                            .padding(bottom = 10.dp),
                        shape = RoundedCornerShape(22.dp),
                        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.72f)
                    ) {
                        LiveMapMetricStrip(state = state, nowTick = nowTick)
                    }
                }
                LiveStartToolbar(
                    sportIcon = state.sport.materialIcon,
                    sportTitle = state.sport.title,
                    phase = state.phase,
                    countdown = startCountdown,
                    hasActiveWorkout = hasActiveWorkout,
                    locked = touchLocked,
                    onShowOptions = { scope.launch { pagerState.animateScrollToPage(0) } },
                    onSport = { },
                    onPrimary = {
                        when (state.phase) {
                            LiveActivityState.Phase.RECORDING -> runtime.pause()
                            LiveActivityState.Phase.PAUSED -> { runtime.resume(); startService() }
                            else -> Unit
                        }
                    },
                    onFinish = { confirmFinish = true },
                    onLock = { lockTouch() },
                    onPrimaryPositioned = { lockTarget = it }
                )
                if (!touchLocked) {
                    Row(
                        Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 2.dp),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        repeat(pageCount) { index ->
                            Box(
                                Modifier
                                    .padding(horizontal = 5.dp)
                                    .size(if (index == pagerState.currentPage) 10.dp else 8.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (index == pagerState.currentPage) brandGreen
                                        else MaterialTheme.colorScheme.outlineVariant
                                    )
                            )
                        }
                    }
                }
            }
        }
        if (touchLocked) {
            LiveScreenTouchBlocker(lockTarget, lockContainer, ::unlockTouch)
        }
        return
    }

    // Idle: mapa o métricas según preferencia (sin pager).
    if (state.sport.usesGPS && state.phase != LiveActivityState.Phase.REVIEW && !showingMetrics) {
        val planned = routes.firstOrNull { it.id == state.selectedRouteID }
        // Una captura puntual no se convierte en ubicación viva por quedarse
        // en memoria: caduca aunque el usuario no haya salido de esta pantalla.
        val freshPosition = previewPosition?.takeIf { System.currentTimeMillis()-it.recordedAtEpochMs < 15_000 }
        // Paridad Apple: el banner verde tambien informa en preparacion con la
        // ultima posicion capturada (sin arrancar el GPS de grabacion).
        LaunchedEffect(freshPosition?.recordedAtEpochMs, state.selectedRouteID, state.phase) {
            if (state.phase == LiveActivityState.Phase.IDLE) freshPosition?.let { runtime.previewGuidance(it) }
        }
        BoxWithConstraints(
            Modifier.fillMaxSize().testTag("live_activity_screen")
                .onGloballyPositioned { lockContainer = it.boundsInRoot() }
        ) {
            val mapLandscape=liveMapLandscape(maxWidth.value,maxHeight.value)
            val overlayWidth=liveMapOverlayWidth(maxWidth.value)
            RouteMapView(if (state.points.isNotEmpty()) state.points else planned?.points ?: listOfNotNull(freshPosition),
                isInteractive = true, modifier = Modifier.fillMaxSize(), plannedRoute = state.points.size < 2, waterSport = state.sport.isWaterSport,
                paceMode = AdaptiveRoutePace.modeForSport(state.sport.name),
                controlsOverlay = true,plannedPoints=if(state.points.isNotEmpty()) planned?.points.orEmpty() else emptyList(),
                onMapRendered = onMapRendered,navigationMode=effectiveNavigationMode,
                cameraCenter=if(followingMap) state.points.lastOrNull() ?: freshPosition else null,
                cameraTrace=state.points,
                userPosition=state.points.lastOrNull() ?: freshPosition,
                userHeadingDegrees=currentMeasuredHeading ?: lastReliableHeading ?: compassHeading,
                recenterToken=recenterToken,
                onCameraGesture={
                    followingMap = false
                    lastUserMapMoveAt = android.os.SystemClock.elapsedRealtime()
                })
            // Deporte a la izquierda; 2D/3D a la derecha (paridad iOS mapHeader).
            Row(
                Modifier
                    .align(Alignment.TopCenter)
                    .fillMaxWidth()
                    .statusBarsPadding()
                    .padding(top = 12.dp, start = 16.dp, end = 16.dp)
                    .testTag("live_map_fabs"),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                LiveSessionSportBadge(state.sport.materialIcon, state.sport.title)
                LiveMapCircleFab(
                    icon = if (effectiveNavigationMode) Icons.Outlined.Map else Icons.Outlined.ViewInAr,
                    label = when {
                        effectiveNavigationMode -> "Cambiar a vista 2D"
                        canNavigate3D -> "Cambiar a vista 3D"
                        else -> "Desbloquear navegación 3D con Repera Pro"
                    }
                ) {
                    if (checking3DAccess) {
                        // Evita dobles clics y dos verificaciones simultáneas.
                    } else if (canNavigate3D) {
                        setNavigationMode(!navigationMode)
                        followingMap = true
                        recenterToken++
                    } else {
                        checking3DAccess = true
                        scope.launch {
                            try {
                                subscriptions?.refreshEntitlementsForFeatureAction()
                                when {
                                    subscriptions?.policy?.canUse3DNavigation == true -> {
                                        setNavigationMode(true)
                                        followingMap = true
                                        recenterToken++
                                    }
                                    subscriptions == null ||
                                    subscriptions.snapshot.status ==
                                        dev.repera.domain.monetization.SubscriptionStatus.UNKNOWN ||
                                    subscriptions.snapshot.lastRefreshFailedOffline ||
                                    !subscriptions.snapshot.isConfigured ||
                                    !subscriptions.verificationBackendConfigured -> {
                                        show3DAccessVerificationError = true
                                    }
                                    else -> subscriptions.presentPaywall(
                                        dev.repera.domain.monetization.PaywallContext.GENERIC
                                    )
                                }
                            } catch (_: Exception) {
                                show3DAccessVerificationError = true
                            } finally {
                                checking3DAccess = false
                            }
                        }
                    }
                }
            }
            if (state.selectedRouteID != null && state.phase != LiveActivityState.Phase.REVIEW) {
                // Paridad iOS navigationDirectionsBanner: icono+distancia | instrucción.
                val cue = runtime.upcomingCue
                val instruction = cue?.instruction
                    ?: runtime.upcomingTurn
                    ?: if (state.phase == LiveActivityState.Phase.IDLE) "Ruta cargada"
                    else "Sigue el recorrido"
                val direction = when {
                    cue?.offRoute == true -> "!"
                    instruction.contains("derecha", true) -> "↱"
                    instruction.contains("izquierda", true) -> "↰"
                    instruction.contains("sentido", true) || instruction.contains("giro", true) -> "↶"
                    else -> "↑"
                }
                Row(
                    Modifier.align(Alignment.TopStart).statusBarsPadding()
                        .padding(top = 12.dp, start = 14.dp, end = 80.dp)
                        .fillMaxWidth()
                        .background(brandGreen, RoundedCornerShape(18.dp))
                        .padding(horizontal = 12.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.width(76.dp)
                    ) {
                        Text(
                            direction,
                            style = MaterialTheme.typography.displaySmall,
                            color = Color.Black,
                            fontWeight = FontWeight.Bold
                        )
                        cue?.distanceMeters?.let { meters ->
                            Text(
                                if (meters >= 1000) "%.1f km".format(java.util.Locale.US, meters / 1000.0)
                                else "$meters m",
                                style = MaterialTheme.typography.titleMedium,
                                color = Color.Black,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                    Column(Modifier.weight(1f)) {
                        Text(
                            instruction,
                            style = MaterialTheme.typography.titleLarge,
                            color = Color.Black,
                            fontWeight = FontWeight.Bold,
                            maxLines = 2
                        )
                        if (cue?.offRoute == true) {
                            Text(
                                stringResource(R.string.live_activity_screen_revisa_el_mapa),
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.Black
                            )
                        }
                    }
                }
            }
            (error ?: runtime.lastError)?.let {
                Text(
                    it,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .statusBarsPadding()
                        .padding(16.dp)
                )
            }
            if (runtime.recoveryBlocked) {
                TextButton(
                    onClick = { confirmDiscard = true },
                    modifier = Modifier.align(Alignment.Center)
                ) { Text(stringResource(R.string.live_activity_screen_descartar_recuperacion_danada)) }
            }
            // Controles sueltos (sin recuadro); strip de métricas sí lleva glass.
            Column(
                Modifier
                    .align(
                        if (mapLandscape && state.phase != LiveActivityState.Phase.IDLE)
                            Alignment.BottomStart else Alignment.BottomCenter
                    )
                    .padding(start = 12.dp, end = 12.dp, top = 12.dp, bottom = bottomChromePad)
                    .then(
                        if (mapLandscape)
                            Modifier.width(
                                if (state.phase == LiveActivityState.Phase.IDLE) 570.dp else overlayWidth.dp
                            )
                        else Modifier
                    )
                    .pointerInput(touchLocked) {
                        if (!touchLocked) {
                            var horizontalDistance = 0f
                            detectHorizontalDragGestures(
                                onDragStart = { horizontalDistance = 0f },
                                onHorizontalDrag = { change, delta ->
                                    horizontalDistance += delta
                                    change.consume()
                                },
                                onDragEnd = {
                                    if (horizontalDistance > 70f) showingMetrics = true
                                    horizontalDistance = 0f
                                },
                                onDragCancel = { horizontalDistance = 0f }
                            )
                        }
                    }
                    .testTag("live_idle_panel")
            ) {
                if (state.phase != LiveActivityState.Phase.IDLE) {
                    Surface(
                        shape = RoundedCornerShape(22.dp),
                        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.72f),
                        tonalElevation = 0.dp,
                        shadowElevation = 1.dp,
                        border = BorderStroke(
                            1.dp,
                            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)
                        ),
                        modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
                    ) {
                        LiveMapMetricStrip(state = state, nowTick = nowTick)
                    }
                }
                LiveStartToolbar(
                    sportIcon = state.sport.materialIcon,
                    sportTitle = state.sport.title,
                    phase = state.phase,
                    countdown = startCountdown,
                    hasActiveWorkout = hasActiveWorkout,
                    locked = touchLocked,
                    onShowOptions = { showStartOptions = true },
                    onSport = { showSportPicker = true },
                    onPrimary = {
                        when (state.phase) {
                            LiveActivityState.Phase.RECORDING -> runtime.pause()
                            LiveActivityState.Phase.PAUSED -> { runtime.resume(); startService() }
                            LiveActivityState.Phase.IDLE -> {
                                if (hasActiveWorkout) onOpenWorkout()
                                else if (startCountdown > 0) cancelStartCountdown()
                                else if (ContextCompat.checkSelfPermission(
                                        context, Manifest.permission.ACCESS_FINE_LOCATION
                                    ) != PackageManager.PERMISSION_GRANTED &&
                                    ContextCompat.checkSelfPermission(
                                        context, Manifest.permission.ACCESS_COARSE_LOCATION
                                    ) != PackageManager.PERMISSION_GRANTED
                                ) permissions.launch(arrayOf(
                                    Manifest.permission.ACCESS_FINE_LOCATION,
                                    Manifest.permission.ACCESS_COARSE_LOCATION
                                ))
                                else beginStartCountdown()
                            }
                            else -> Unit
                        }
                    },
                    onFinish = { confirmFinish = true },
                    onLock = { lockTouch() },
                    onPrimaryPositioned = { lockTarget = it }
                )
            }
            if (touchLocked) {
                LiveScreenTouchBlocker(lockTarget, lockContainer, ::unlockTouch)
            }
        }
        return
    }
    // Métricas GPS (LiveActivityView.metricsView): tiles con Spacers, no lista scroll.
    if (state.sport.usesGPS && state.phase != LiveActivityState.Phase.REVIEW &&
        showingMetrics && !showRoutes
    ) {
        val durationSec = state.durationSeconds(nowTick)
        val durationText = LiveActivityClock.format(durationSec)
        val average = state.averageSpeedKmh(nowTick)
        val paceOrSpeed = when {
            average == null || average <= 0.1 ->
                if (state.sport.displaysSpeed) "—" else "—:—"
            state.sport.displaysSpeed -> ReperaNumberFormat.decimal(average)
            else -> {
                val secs = (3600.0 / average).toInt()
                if (secs >= 3600) "—:—" else "%d:%02d".format(java.util.Locale.ROOT, secs / 60, secs % 60)
            }
        }
        val paceLabel = if (state.sport.displaysSpeed)
            "Velocidad media (km/h)" else "Ritmo medio (min/km)"
        val km = state.distanceMeters / 1000.0
        Box(
            Modifier.fillMaxSize()
                .onGloballyPositioned { lockContainer = it.boundsInRoot() }
        ) {
        Column(
            Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .testTag("live_activity_screen")
        ) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 14.dp)
                    .heightIn(min = 54.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Start
            ) {
                LiveSessionSportBadge(state.sport.materialIcon, state.sport.title)
            }
            Spacer(Modifier.weight(1f, fill = true).heightIn(min = 16.dp))
            Text(
                durationText,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                style = MaterialTheme.typography.displayLarge.copy(
                    fontWeight = FontWeight.Bold,
                    fontSize = 68.sp,
                    letterSpacing = 0.sp
                ),
                textAlign = TextAlign.Center,
                maxLines = 1
            )
            Text(
                stringResource(R.string.live_activity_screen_duracion),
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            // Idle: Spacers proporcionales. En vivo el tramo entra y Distancia sube.
            AnimatedVisibility(
                visible = state.phase != LiveActivityState.Phase.IDLE,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                LiveKilometerSplitSummary(
                    state = state,
                    nowTick = nowTick,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            Spacer(Modifier.weight(1f, fill = true).heightIn(min = 14.dp))
            Text(
                paceOrSpeed,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                style = MaterialTheme.typography.displayLarge.copy(
                    fontWeight = FontWeight.Bold,
                    fontSize = 78.sp,
                    letterSpacing = 0.sp
                ),
                textAlign = TextAlign.Center,
                maxLines = 1
            )
            Text(
                paceLabel,
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.weight(1f, fill = true).heightIn(min = 14.dp))
            Text(
                ReperaNumberFormat.decimal(km),
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                style = MaterialTheme.typography.displayMedium.copy(
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 55.sp,
                    letterSpacing = 0.sp
                ),
                textAlign = TextAlign.Center,
                maxLines = 1
            )
            Text(
                stringResource(R.string.live_activity_screen_distancia_km),
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            AnimatedVisibility(
                visible = state.phase == LiveActivityState.Phase.RECORDING ||
                    state.phase == LiveActivityState.Phase.PAUSED,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                LiveHeartRateZoneBar(
                    bpm = displayedHeartRateBpm,
                    modifier = Modifier.padding(horizontal = 28.dp, vertical = 8.dp),
                    estimatedMaxBpm = maxHeartRateBpm.toDouble()
                )
            }
            if (state.sport.tracksElevation && state.hasElevationSamples) {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 28.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        "+%.0f m".format(dev.repera.domain.ReperaNumberFormat.displayLocale, state.elevationGainMeters),
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        "−%.0f m".format(dev.repera.domain.ReperaNumberFormat.displayLocale, state.elevationLossMeters),
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Spacer(Modifier.weight(1f, fill = true).heightIn(min = 12.dp))
            // Hueco para toolbar flotante (fuera del flujo / no scroll).
            Spacer(Modifier.height(bottomChromePad + 120.dp))
            (error ?: runtime.lastError)?.let {
                Text(it, color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp))
            }
        }
        LiveStartToolbar(
            sportIcon = state.sport.materialIcon,
            sportTitle = state.sport.title,
            phase = state.phase,
            countdown = startCountdown,
            hasActiveWorkout = hasActiveWorkout,
            locked = touchLocked,
            onShowOptions = { showStartOptions = true },
            onSport = { showSportPicker = true },
            onPrimary = {
                when (state.phase) {
                    LiveActivityState.Phase.RECORDING -> runtime.pause()
                    LiveActivityState.Phase.PAUSED -> { runtime.resume(); startService() }
                    LiveActivityState.Phase.IDLE -> {
                        if (hasActiveWorkout) onOpenWorkout()
                        else if (startCountdown > 0) cancelStartCountdown()
                        else if (ContextCompat.checkSelfPermission(
                                context, Manifest.permission.ACCESS_FINE_LOCATION
                            ) != PackageManager.PERMISSION_GRANTED &&
                            ContextCompat.checkSelfPermission(
                                context, Manifest.permission.ACCESS_COARSE_LOCATION
                            ) != PackageManager.PERMISSION_GRANTED
                        ) permissions.launch(arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        ))
                        else beginStartCountdown()
                    }
                    else -> Unit
                }
            },
            onFinish = { confirmFinish = true },
            onLock = { lockTouch() },
            onPrimaryPositioned = { lockTarget = it },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(bottom = bottomChromePad)
        )
        if (touchLocked) LiveScreenTouchBlocker(lockTarget, lockContainer, ::unlockTouch)
        }
        return
    }
    // REVIEW: resumen estilo Fitness (mapa + métricas + guardar), sin el formulario genérico.
    if (state.phase == LiveActivityState.Phase.REVIEW) {
        val saveReview: () -> Unit = save@{
            if (savingActivity) return@save
            val now = System.currentTimeMillis()
            val snapshot = state.snapshot(now)
            if (snapshot == null) {
                error = "No se pudo preparar la actividad para guardarla. Sigue disponible: vuelve a intentarlo o descártala."
                return@save
            }
            savingActivity = true
            scope.launch(kotlinx.coroutines.NonCancellable) { try {
                val savedDay = state.startedMillis ?: now
                val finishedMillis = state.finishedMillis ?: now
                val duration = state.durationSeconds(now)
                val conditions = runtime.liveConditions
                val sessionId = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                    WorkoutRepository(context, accountId).saveLiveActivity(
                        snapshot,
                        finishedMillis,
                        duration,
                        title,
                        notes,
                        activityConditions = conditions,
                        locationPin = runtime.startLocationPin,
                        wearTotalEnergyKcal = runtime.currentWearTotalEnergyKcal(),
                        wearAverageHeartRateBpm = runtime.currentWearAverageHeartRateBpm()
                    )
                }
                if (runtime.discard()) {
                    LiveActivityService.stop(context)
                    title = ""
                    notes = ""
                    showingMetrics = false
                    onSavedDay(savedDay)
                    onSaved(sessionId)
                } else {
                    error = "La actividad se guardó, pero no se pudo limpiar el punto de recuperación."
                }
            } catch (cancelled: kotlinx.coroutines.CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                error = "No se pudo guardar. La actividad sigue disponible para reintentar."
            } finally {
                savingActivity = false
            } }
        }
        LiveActivityReviewContent(
            state = state,
            title = title,
            onTitleChange = { title = it },
            notes = notes,
            onNotesChange = { notes = it },
            previewHealth = previewHealth,
            wearTotalEnergyKcal = runtime.currentWearTotalEnergyKcal(),
            wearAverageHeartRateBpm = runtime.currentWearAverageHeartRateBpm(),
            routes = routes,
            nowTick = nowTick,
            error = error ?: runtime.lastError,
            onMapRendered = onMapRendered,
            activityConditions = runtime.liveConditions,
            onSave = saveReview,
            onDiscard = { confirmDiscard = true },
            recoveryBlocked = runtime.recoveryBlocked
        )
        return
    }
    // Sin GPS / rutas: métricas scrolleables; toolbar flotante fijo encima del menú.
    Box(Modifier.fillMaxSize().onGloballyPositioned { lockContainer = it.boundsInRoot() }) {
    Column(
        Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
            .padding(bottom = bottomChromePad + 120.dp)
            .testTag("live_activity_screen"),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        ReperaPageHeader(title = stringResource(R.string.tab_start))
        Text(state.sport.title,style=MaterialTheme.typography.titleLarge)
        if (state.phase == LiveActivityState.Phase.IDLE) {
            Text(state.sport.metricDescription,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        } else {
            Text(LiveActivityClock.format(state.durationSeconds(nowTick)),
                style = MaterialTheme.typography.displayLarge)
            if (displayedHeartRateBpm != null) {
                LiveHeartRateZoneBar(
                    bpm = displayedHeartRateBpm,
                    estimatedMaxBpm = maxHeartRateBpm.toDouble())
            }
            runtime.upcomingTurn?.let {
                Text(it, style = MaterialTheme.typography.titleMedium)
            }
            runtime.latestKilometerReport?.let { Text(it) }
        }
        (error ?: runtime.lastError)?.let {Text(it,color=MaterialTheme.colorScheme.error)}
        if(runtime.recoveryBlocked) TextButton(onClick={confirmDiscard=true}) {Text(stringResource(R.string.live_activity_screen_descartar_recuperacion_danada))}
    }
    LiveStartToolbar(
        sportIcon = state.sport.materialIcon,
        sportTitle = state.sport.title,
        phase = state.phase,
        countdown = startCountdown,
        hasActiveWorkout = hasActiveWorkout,
        locked = touchLocked,
        onShowOptions = { showStartOptions = true },
        onSport = { showSportPicker = true },
        onPrimary = {
            when (state.phase) {
                LiveActivityState.Phase.RECORDING -> runtime.pause()
                LiveActivityState.Phase.PAUSED -> { runtime.resume(); startService() }
                LiveActivityState.Phase.IDLE -> {
                    if (hasActiveWorkout) onOpenWorkout()
                    else if (startCountdown > 0) cancelStartCountdown()
                    else if (ContextCompat.checkSelfPermission(
                            context, Manifest.permission.ACCESS_FINE_LOCATION
                        ) != PackageManager.PERMISSION_GRANTED &&
                        ContextCompat.checkSelfPermission(
                            context, Manifest.permission.ACCESS_COARSE_LOCATION
                        ) != PackageManager.PERMISSION_GRANTED
                    ) permissions.launch(arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                    ))
                    else beginStartCountdown()
                }
                else -> Unit
            }
        },
        onFinish = { confirmFinish = true },
        onLock = { lockTouch() },
        onPrimaryPositioned = { lockTarget = it },
        modifier = Modifier
            .align(Alignment.BottomCenter)
            .fillMaxWidth()
            .padding(bottom = bottomChromePad)
    )
    if (touchLocked) LiveScreenTouchBlocker(lockTarget, lockContainer, ::unlockTouch)
    }
}

/** Opciones idle: modal inferior (paridad sheet iOS), no panel inline bajo Play. */
@Composable
private fun LiveIdleOptionsSheet(
    audioEnabled: Boolean,
    countdownEnabled: Boolean,
    showMap: Boolean,
    hasGPS: Boolean,
    onClose: () -> Unit,
    onAudio: () -> Unit,
    onCountdown: () -> Unit,
    onMap: (Boolean) -> Unit,
    onRoute: () -> Unit
) {
    Column(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(bottom = 28.dp)
            .testTag("live_start_options"),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "Opciones",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f)
            )
            ReperaToolbarGlassIconButton(
                icon = Icons.Outlined.Close,
                contentDescription = "Cerrar",
                onClick = onClose
            )
        }
        LiveSportOptionSwitchRow(
            icon = Icons.Outlined.VolumeUp,
            label = "Audio",
            checked = audioEnabled,
            minHeight = 56.dp,
            titleStyle = MaterialTheme.typography.titleMedium,
            onCheckedChange = { onAudio() }
        )
        LiveSportOptionSwitchRow(
            icon = Icons.Outlined.Map,
            label = "Mapa",
            checked = hasGPS && showMap,
            enabled = hasGPS,
            minHeight = 56.dp,
            titleStyle = MaterialTheme.typography.titleMedium,
            onCheckedChange = onMap
        )
        LiveSportOptionSwitchRow(
            icon = Icons.Outlined.Timer,
            label = "Cuenta atrás",
            checked = countdownEnabled,
            minHeight = 56.dp,
            titleStyle = MaterialTheme.typography.titleMedium,
            onCheckedChange = { onCountdown() }
        )
        TextButton(
            onClick = onRoute,
            enabled = hasGPS,
            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp).testTag("live_load_route")
        ) {
            Icon(Icons.Outlined.Route, null)
            Spacer(Modifier.width(12.dp))
            Text("Cargar ruta", style = MaterialTheme.typography.titleMedium)
        }
    }
}

/**
 * No tapa los datos ni detiene GPS. Solo intercepta los gestos de la sesión
 * y superpone un candado en la misma posición del control original.
 * Mantener pulsado un segundo desbloquea; la acción accesible permite TalkBack.
 */
@Composable
private fun LiveSessionOptionsPane(
    audioEnabled: Boolean,
    countdownEnabled: Boolean,
    showMap: Boolean,
    hasGPS: Boolean,
    routeTitle: String?,
    onAudio: () -> Unit,
    onCountdown: () -> Unit,
    onMap: (Boolean) -> Unit
) {
    // Controles grandes: pensados para usarse en movimiento, con poca precisión.
    Column(
        Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        Text("Opciones", style = MaterialTheme.typography.headlineMedium)
        LiveSportOptionSwitchRow(
            icon = Icons.Outlined.VolumeUp,
            label = "Audio",
            checked = audioEnabled,
            onCheckedChange = { onAudio() }
        )
        LiveSportOptionSwitchRow(
            icon = Icons.Outlined.Map,
            label = "Mapa",
            checked = hasGPS && showMap,
            enabled = hasGPS,
            onCheckedChange = onMap
        )
        LiveSportOptionSwitchRow(
            icon = Icons.Outlined.Timer,
            label = "Cuenta atrás",
            checked = countdownEnabled,
            onCheckedChange = { onCountdown() }
        )
        Text(
            routeTitle ?: "Sin ruta cargada",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun LiveSportOptionSwitchRow(
    icon: ImageVector,
    label: String,
    checked: Boolean,
    enabled: Boolean = true,
    minHeight: Dp = 72.dp,
    titleStyle: androidx.compose.ui.text.TextStyle = MaterialTheme.typography.titleLarge,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        Modifier.fillMaxWidth().heightIn(min = minHeight),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, modifier = Modifier.size(if (minHeight >= 72.dp) 28.dp else 24.dp))
        Spacer(Modifier.width(if (minHeight >= 72.dp) 14.dp else 12.dp))
        Text(
            label,
            style = titleStyle,
            modifier = Modifier.weight(1f)
        )
        Switch(checked = checked, enabled = enabled, onCheckedChange = onCheckedChange)
    }
}

@Composable
private fun LiveSessionMetricsPane(
    state: LiveActivityState,
    nowTick: Long,
    displayedHeartRateBpm: Int?,
    maxHeartRateBpm: Int,
    includeSplits: Boolean
) {
    val durationText = LiveActivityClock.format(state.durationSeconds(nowTick))
    val average = state.averageSpeedKmh(nowTick)
    val paceOrSpeed = when {
        average == null || average <= 0.1 ->
            if (state.sport.displaysSpeed) "—" else "—:—"
        state.sport.displaysSpeed -> ReperaNumberFormat.decimal(average)
        else -> {
            val secs = (3600.0 / average).toInt()
            if (secs >= 3600) "—:—" else "%d:%02d".format(java.util.Locale.ROOT, secs / 60, secs % 60)
        }
    }
    val paceLabel = if (state.sport.displaysSpeed)
        "Velocidad media (km/h)" else "Ritmo medio (min/km)"
    val km = state.distanceMeters / 1000.0
    val scroll = rememberScrollState()
    // Página 1 = un viewport (Parciales no asoma); página 2 al scrollear.
    BoxWithConstraints(
        Modifier
            .fillMaxSize()
            .statusBarsPadding()
    ) {
        val pageHeight = maxHeight
        Column(Modifier.fillMaxSize().verticalScroll(scroll)) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .height(pageHeight)
                    .padding(bottom = 140.dp)
            ) {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 14.dp)
                        .heightIn(min = 54.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Start
                ) {
                    // Mismo badge que mapa: siempre a la izquierda.
                    LiveSessionSportBadge(state.sport.materialIcon, state.sport.title)
                }
                Spacer(Modifier.weight(1f, fill = true).heightIn(min = 16.dp))
                Text(
                    durationText,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                    style = MaterialTheme.typography.displayLarge.copy(
                        fontWeight = FontWeight.Bold, fontSize = 68.sp, letterSpacing = 0.sp
                    ),
                    textAlign = TextAlign.Center,
                    maxLines = 1
                )
                Text(
                    stringResource(R.string.live_activity_screen_duracion),
                    modifier = Modifier.fillMaxWidth(),
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
                LiveKilometerSplitSummary(
                    state = state,
                    nowTick = nowTick,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 12.dp)
                )
                Spacer(Modifier.weight(1f, fill = true).heightIn(min = 14.dp))
                Text(
                    paceOrSpeed,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                    style = MaterialTheme.typography.displayLarge.copy(
                        fontWeight = FontWeight.Bold, fontSize = 78.sp, letterSpacing = 0.sp
                    ),
                    textAlign = TextAlign.Center,
                    maxLines = 1
                )
                Text(
                    paceLabel,
                    modifier = Modifier.fillMaxWidth(),
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
                Spacer(Modifier.weight(1f, fill = true).heightIn(min = 14.dp))
                Text(
                    ReperaNumberFormat.decimal(km),
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                    style = MaterialTheme.typography.displayMedium.copy(
                        fontWeight = FontWeight.SemiBold, fontSize = 55.sp, letterSpacing = 0.sp
                    ),
                    textAlign = TextAlign.Center,
                    maxLines = 1
                )
                Text(
                    stringResource(R.string.live_activity_screen_distancia_km),
                    modifier = Modifier.fillMaxWidth(),
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
                LiveHeartRateZoneBar(
                    bpm = displayedHeartRateBpm,
                    modifier = Modifier.padding(horizontal = 28.dp, vertical = 8.dp),
                    estimatedMaxBpm = maxHeartRateBpm.toDouble()
                )
            }
            if (includeSplits) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .heightIn(min = pageHeight)
                        .padding(bottom = 140.dp)
                ) {
                    Text(
                        "Parciales",
                        style = MaterialTheme.typography.headlineSmall,
                        modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp)
                    )
                    Row(Modifier.fillMaxWidth().padding(horizontal = 24.dp)) {
                        Text("Kilómetro", modifier = Modifier.weight(1f),
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text("Ritmo", modifier = Modifier.weight(1f), textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text("Variación", modifier = Modifier.weight(1f), textAlign = TextAlign.End,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    HorizontalDivider(
                        Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
                        color = MaterialTheme.colorScheme.outlineVariant
                    )
                    if (state.splitsSeconds.isEmpty()) {
                        ReperaEmptyState(
                            title = "Aún no hay parciales",
                            subtitle = "El primer parcial aparecerá al completar un kilómetro."
                        )
                    } else {
                        state.splitsSeconds.forEachIndexed { index, seconds ->
                            val pace = seconds.roundToInt().coerceAtLeast(0)
                            val previous = state.splitsSeconds.getOrNull(index - 1)
                            val delta = previous?.let { (seconds - it).roundToInt() }
                            val variation = when {
                                delta == null -> "—"
                                delta == 0 -> "±0:00"
                                else -> "${if (delta < 0) "−" else "+"}${"%d:%02d".format(
                                    kotlin.math.abs(delta) / 60, kotlin.math.abs(delta) % 60)}"
                            }
                            Row(Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 16.dp)) {
                                Text("${index + 1}", modifier = Modifier.weight(1f))
                                Text(
                                    "%d:%02d".format(pace / 60, pace % 60),
                                    modifier = Modifier.weight(1f),
                                    textAlign = TextAlign.Center
                                )
                                Text(variation, modifier = Modifier.weight(1f), textAlign = TextAlign.End)
                            }
                            HorizontalDivider(
                                Modifier.padding(horizontal = 24.dp),
                                color = MaterialTheme.colorScheme.outlineVariant
                            )
                        }
                    }
                    Spacer(Modifier.height(24.dp))
                }
            }
        }
    }
}

@Composable
private fun LiveSessionMapPane(
    state: LiveActivityState,
    routes: List<LiveSavedRoute>,
    previewPosition: dev.repera.domain.WorkoutRoutePoint?,
    effectiveNavigationMode: Boolean,
    canNavigate3D: Boolean,
    followingMap: Boolean,
    recenterToken: Int,
    compassHeading: Double?,
    currentMeasuredHeading: Double?,
    lastReliableHeading: Double?,
    nowTick: Long,
    onMapRendered: (() -> Unit)?,
    onToggle3D: () -> Unit,
    onCameraGesture: () -> Unit
) {
    val planned = routes.firstOrNull { it.id == state.selectedRouteID }
    val freshPosition = previewPosition?.takeIf {
        System.currentTimeMillis() - it.recordedAtEpochMs < 15_000
    }
    Box(Modifier.fillMaxSize()) {
        RouteMapView(
            if (state.points.isNotEmpty()) state.points else planned?.points ?: listOfNotNull(freshPosition),
            isInteractive = true,
            modifier = Modifier.fillMaxSize(),
            plannedRoute = state.points.size < 2,
            waterSport = state.sport.isWaterSport,
            paceMode = AdaptiveRoutePace.modeForSport(state.sport.name),
            controlsOverlay = true,
            plannedPoints = if (state.points.isNotEmpty()) planned?.points.orEmpty() else emptyList(),
            onMapRendered = onMapRendered,
            navigationMode = effectiveNavigationMode,
            cameraCenter = if (followingMap) state.points.lastOrNull() ?: freshPosition else null,
            cameraTrace = state.points,
            userPosition = state.points.lastOrNull() ?: freshPosition,
            userHeadingDegrees = currentMeasuredHeading ?: lastReliableHeading ?: compassHeading,
            recenterToken = recenterToken,
            onCameraGesture = onCameraGesture
        )
        Row(
            Modifier
                .align(Alignment.TopCenter)
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(top = 12.dp, start = 16.dp, end = 16.dp),
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            LiveSessionSportBadge(state.sport.materialIcon, state.sport.title)
            LiveMapCircleFab(
                icon = if (effectiveNavigationMode) Icons.Outlined.Map else Icons.Outlined.ViewInAr,
                label = when {
                    effectiveNavigationMode -> "Cambiar a vista 2D"
                    canNavigate3D -> "Cambiar a vista 3D"
                    else -> "Desbloquear navegación 3D con Repera Pro"
                },
                onClick = onToggle3D
            )
        }
        // Strip de métricas: chrome fijo del pager (encima de Play), no aquí.
    }
}

@Composable
private fun LiveSessionSportBadge(icon: ImageVector, title: String) {
    Surface(
        shape = RoundedCornerShape(999.dp),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.72f),
        border = BorderStroke(
            0.7.dp,
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)
        ),
        modifier = Modifier.heightIn(min = 44.dp)
    ) {
        Row(
            Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(icon, null, tint = brandGreen, modifier = Modifier.size(22.dp))
            Text(title, style = MaterialTheme.typography.titleSmall, maxLines = 1)
        }
    }
}

@Composable
private fun LiveScreenTouchBlocker(
    target: Rect?,
    container: Rect?,
    onUnlock: () -> Unit
) {
    Box(
        Modifier.fillMaxSize()
            .pointerInput(Unit) {
                awaitPointerEventScope {
                    while (true) {
                        awaitPointerEvent(PointerEventPass.Initial).changes.forEach { it.consume() }
                    }
                }
            }
            .testTag("live_touch_blocked")
    )
    // Solo hit-target transparente: el candado visible ya está en Play (sin parpadeo).
    if (target != null && container != null) {
        Box(
            Modifier
                .offset {
                    IntOffset(
                        (target.left - container.left).roundToInt(),
                        (target.top - container.top).roundToInt()
                    )
                }
                .size(94.dp)
                .clip(CircleShape)
                .pointerInput(Unit) {
                    detectTapGestures(onPress = {
                        // Solo mientras el dedo sigue apoyado al cumplirse 1 s.
                        val released = withTimeoutOrNull(1_000L) { tryAwaitRelease() }
                        if (released == null) onUnlock()
                    })
                }
                .semantics {
                    contentDescription = "Pantalla bloqueada. Mantén pulsado un segundo para desbloquear"
                    onClick(label = "Desbloquear pantalla") { onUnlock(); true }
                }
                .testTag("live_touch_unlock")
        )
    }
}

/** Aviso sin GPS: debajo de los tiles, con icono de mapa. */
@Composable
private fun LiveReviewMapUnavailableCard(
    hasDistance: Boolean,
    modifier: Modifier = Modifier
) {
    ReperaCard(modifier = modifier.testTag("live_review_map_missing")) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Box(
                Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(brandGreen.copy(alpha = 0.14f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Outlined.Map,
                    contentDescription = null,
                    tint = brandGreen,
                    modifier = Modifier.size(24.dp)
                )
            }
            Column(
                Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    stringResource(R.string.live_activity_screen_recorrido_no_disponible),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    if (hasDistance)
                        "La distancia y los parciales se conservan, pero no hay puntos GPS para dibujar el mapa."
                    else
                        "No se registraron puntos GPS en esta actividad.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/** Resumen al finalizar: mapa hero + métricas + guardar (paridad Fitness / iOS review). */
@Composable
private fun LiveActivityReviewContent(
    state: LiveActivityState,
    title: String,
    onTitleChange: (String) -> Unit,
    notes: String,
    onNotesChange: (String) -> Unit,
    previewHealth: dev.repera.domain.SessionCardioSample?,
    wearTotalEnergyKcal: Double?,
    wearAverageHeartRateBpm: Double?,
    routes: List<LiveSavedRoute>,
    nowTick: Long,
    error: String?,
    onMapRendered: (() -> Unit)?,
    activityConditions: dev.repera.domain.ActivityConditionsSnapshot?,
    onSave: () -> Unit,
    onDiscard: () -> Unit,
    recoveryBlocked: Boolean
) {
    val chosenRoutePoints = routes.firstOrNull { it.id == state.selectedRouteID }?.points.orEmpty()
    val previewRecorded = state.points.size >= 2
    val previewPoints = if (previewRecorded) state.points else chosenRoutePoints
    val average = state.averageSpeedKmh(nowTick)
    val paceOrSpeed = when {
        average == null || average <= 0.1 ->
            if (state.sport.displaysSpeed) "—" else "—:—"
        state.sport.displaysSpeed -> ReperaNumberFormat.decimal(average)
        else -> {
            val secs = (3600.0 / average).toInt()
            if (secs >= 3600) "—:—" else "%d:%02d".format(java.util.Locale.ROOT, secs / 60, secs % 60)
        }
    }
    Column(
        Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .testTag("live_activity_screen"),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        ReperaPageHeader(title = stringResource(R.string.live_activity_screen_guardar_entreno))
        if (state.sport.usesGPS && previewPoints.isNotEmpty()) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(MaterialTheme.colorScheme.surface)
                    .testTag("live_review_map_card")
            ) {
                RouteMapTapTarget(
                    label = stringResource(R.string.live_activity_screen_abrir_recorrido_a_pantalla_completa),
                    modifier = Modifier.fillMaxWidth().height(280.dp)
                ) { interactive, mapModifier ->
                    RouteMapView(
                        previewPoints,
                        isInteractive = interactive,
                        modifier = mapModifier,
                        waterSport = state.sport.isWaterSport,
                        paceMode = AdaptiveRoutePace.modeForSport(state.sport.name),
                        plannedRoute = !previewRecorded,
                        plannedPoints = if (previewRecorded) chosenRoutePoints else emptyList(),
                        controlsOverlay = true,
                        cameraCenter = previewPoints.lastOrNull(),
                        userPosition = previewPoints.lastOrNull(),
                        onMapRendered = onMapRendered
                    )
                }
                val weatherPoint = previewPoints.firstOrNull()
                val weatherEpoch = state.startedMillis
                if (weatherPoint != null && weatherEpoch != null) {
                    RouteWeatherStrip(
                        latitude = weatherPoint.latitude,
                        longitude = weatherPoint.longitude,
                        workoutEpochMs = weatherEpoch,
                        modifier = Modifier.testTag("live_review_weather_under_map"),
                        liveSportId = state.sport.id,
                        persistedConditions = activityConditions
                    )
                }
            }
        }
        // Fecha fuera del bloque de tiles (paridad iOS).
        state.startedMillis?.let { started ->
            val zoned = java.time.Instant.ofEpochMilli(started)
                .atZone(java.time.ZoneId.systemDefault())
            Text(
                zoned.format(
                    java.time.format.DateTimeFormatter.ofPattern(
                        "EEEE, d 'de' MMMM 'de' yyyy, H:mm",
                        java.util.Locale("es", "ES")
                    )
                ),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier
                    .padding(bottom = 2.dp)
                    .testTag("live_review_started_subtitle")
            )
        }
        // Tres tiles por tipo (paridad SessionSummaryTilesBuilder iOS; altura fija).
        val durationSecs = state.durationSeconds(nowTick)
        val durationLabel = if (durationSecs >= 60) {
            "${(durationSecs / 60.0).roundToInt()}′"
        } else {
            LiveSportHistory.formatDuration(durationSecs)
        }
        val reviewSpecs = SessionSummaryTilesBuilder.tiles(
            durationLabel = durationLabel,
            sport = state.sport,
            kcal = previewHealth?.activeEnergyKcal?.takeIf { it.isFinite() && it > 0 },
            distanceMeters = state.distanceMeters.takeIf { it > 0 },
            paceOrSpeedLabel = if (state.sport.usesGPS) paceOrSpeed else null,
            averageHeartRateBpm = wearAverageHeartRateBpm ?: previewHealth?.averageHeartRateBpm
        )
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            reviewSpecs.forEach { spec ->
                WorkoutSummaryTile(
                    spec.title,
                    spec.value,
                    spec.icon,
                    Modifier.weight(1f),
                    iconTint = spec.tint,
                    compact = false
                )
            }
        }
        // Wear Health Services reports CALORIES_TOTAL, not active kcal.
        // Show the wrist's measured total separately from verified Health
        // Connect active energy, rather than silently relabeling it as active.
        if ((wearTotalEnergyKcal ?: 0.0) > 0 || (wearAverageHeartRateBpm ?: 0.0) > 0) {
            ReperaCard(Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    wearTotalEnergyKcal?.takeIf { it.isFinite() && it > 0 }?.let { total ->
                        Text("Calorías totales del reloj · ${total.toInt()} kcal",
                            style = MaterialTheme.typography.bodyMedium)
                    }
                    wearAverageHeartRateBpm?.takeIf { it.isFinite() && it in 25.0..250.0 }?.let { bpm ->
                        Text("FC media del reloj · ${bpm.toInt()} lpm",
                            style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
        }
        // Métricas (parciales / elevación) sin título «Entreno», como iOS.
        if (state.splitsSeconds.isNotEmpty() ||
            (state.sport.tracksElevation && state.hasElevationSamples)
        ) {
            ReperaCard(Modifier.fillMaxWidth()) {
                Column(
                    Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (state.sport.tracksElevation && state.hasElevationSamples) {
                        Text(
                            "+%.0f m de ascenso · −%.0f m de descenso".format(dev.repera.domain.ReperaNumberFormat.displayLocale,
                                state.elevationGainMeters,
                                state.elevationLossMeters
                            ),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    if (state.splitsSeconds.isNotEmpty()) {
                        LiveKilometerSplitsSection(
                            state.splitsSeconds,
                            state.sport.displaysSpeed,
                            routePoints = if (previewRecorded) state.points else emptyList()
                        )
                    }
                }
            }
        }
        if (state.sport.usesGPS && previewPoints.isEmpty()) {
            LiveReviewMapUnavailableCard(
                hasDistance = state.distanceMeters > 0,
                modifier = Modifier.fillMaxWidth()
            )
        }
        ReperaSectionTitle("Detalles de la actividad")
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(
                Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                ReperaMetaTextField(
                    caption = "Nombre",
                    value = title,
                    onValueChange = onTitleChange
                )
                ReperaMetaTextField(
                    caption = "Notas (opcional)",
                    value = notes,
                    onValueChange = onNotesChange,
                    singleLine = false
                )
                state.selectedRouteID?.let { id ->
                    Text(
                        "Ruta: ${routes.firstOrNull { it.id == id }?.title ?: "Elegida"}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        Column(
            Modifier.fillMaxWidth().padding(vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Button(
                onClick = onSave,
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 52.dp)
                    .testTag("live_save"),
                colors = ButtonDefaults.buttonColors(
                    containerColor = brandGreen,
                    contentColor = Color.Black
                ),
                shape = RoundedCornerShape(999.dp)
            ) {
                Text(
                    stringResource(R.string.live_activity_screen_guardar),
                    fontWeight = FontWeight.Bold
                )
            }
            TextButton(
                onClick = onDiscard,
                modifier = Modifier.fillMaxWidth().heightIn(min = 42.dp)
            ) {
                Text(
                    stringResource(R.string.live_activity_screen_descartar_actividad),
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        if (recoveryBlocked) {
            TextButton(onClick = onDiscard) { Text(stringResource(R.string.live_activity_screen_descartar_recuperacion_danada)) }
        }
        Spacer(Modifier.height(24.dp))
    }
}

/** FAB circular opaco del mapa (LiveActivityView.mapCircleButton). R7: touch 48 / círculo 44 / icono 24. */
@Composable
private fun LiveMapCircleFab(icon: ImageVector, label: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .semantics { contentDescription = label },
        contentAlignment = Alignment.Center
    ) {
        Surface(
            onClick = onClick,
            shape = CircleShape,
            color = MaterialTheme.colorScheme.surface,
            shadowElevation = 2.dp,
            border = BorderStroke(0.7.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.75f)),
            modifier = Modifier.size(44.dp)
        ) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.size(24.dp))
            }
        }
    }
}

/** Pausa / reanudar / finalizar estilo Apple Watch sobre el mapa. */
@Composable
private fun LiveMapSessionFab(
    icon: ImageVector,
    label: String,
    background: Color,
    foreground: Color,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .semantics { contentDescription = label },
        contentAlignment = Alignment.Center
    ) {
        Surface(
            onClick = onClick,
            shape = CircleShape,
            color = background,
            shadowElevation = 2.dp,
            modifier = Modifier.size(44.dp)
        ) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = foreground, modifier = Modifier.size(22.dp))
            }
        }
    }
}

/** Parcial del km actual bajo Duración (paridad iOS kilometerSplitSummary). */
@Composable
private fun LiveKilometerSplitSummary(
    state: LiveActivityState,
    nowTick: Long,
    modifier: Modifier = Modifier
) {
    val split = state.currentSplitSeconds(nowTick)
    val kmMetric = when {
        state.activeKilometerMeters < 1 -> if (state.sport.displaysSpeed) "— km/h" else "—:— min/km"
        state.sport.displaysSpeed && split > 0 ->
            "${ReperaNumberFormat.decimal(state.activeKilometerMeters / split * 3.6)} km/h"
        split > 0 ->
            "${LiveSportHistory.formatDuration(split * 1000 / state.activeKilometerMeters)} min/km"
        else -> if (state.sport.displaysSpeed) "— km/h" else "—:— min/km"
    }
    Column(modifier, verticalArrangement = Arrangement.spacedBy(7.dp)) {
        Row(
            Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                "Km ${state.activeKilometer}",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                "${state.activeKilometerMeters.toInt()} m",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.weight(1f))
            Text(
                kmMetric,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1
            )
        }
        LinearProgressIndicator(
            progress = { (state.activeKilometerMeters / 1000.0).toFloat().coerceIn(0f, 1f) },
            modifier = Modifier.fillMaxWidth().height(4.dp).clip(RoundedCornerShape(2.dp)),
            color = brandGreen,
            trackColor = MaterialTheme.colorScheme.surfaceVariant
        )
    }
}

/** Panel compacto fijo: no admite expansión de métricas. */
@Composable
private fun LiveMapMetricStrip(state: LiveActivityState, nowTick: Long) {
    val durationSec = state.durationSeconds(nowTick)
    val durationText = LiveActivityClock.format(durationSec)
    val average = state.averageSpeedKmh(nowTick)
    val paceOrSpeed = when {
        average == null || average <= 0.1 ->
            if (state.sport.displaysSpeed) "—" else "—:—"
        state.sport.displaysSpeed -> ReperaNumberFormat.decimal(average)
        else -> {
            val secs = (3600.0 / average).toInt()
            if (secs >= 3600) "—:—" else "%d:%02d".format(java.util.Locale.ROOT, secs / 60, secs % 60)
        }
    }
    val paceLabel = if (state.sport.displaysSpeed) "Veloc. media" else "Ritmo medio"
    Column(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(5.dp)
        ) {
            LiveMapSmallMetric("Duración", durationText, Modifier.weight(1f), prominent = true)
            LiveMapSmallMetric(paceLabel, paceOrSpeed, Modifier.weight(1f))
            LiveMapSmallMetric(
                "Distancia (km)",
                ReperaNumberFormat.decimal(state.distanceMeters / 1000),
                Modifier.weight(1f)
            )
        }
        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
        LiveKilometerSplitSummary(
            state = state,
            nowTick = nowTick,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp)
        )

    }
}

@Composable
private fun LiveMapSmallMetric(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    prominent: Boolean = false
) {
    Column(
        modifier.padding(horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Text(
            value,
            style = if (prominent) MaterialTheme.typography.titleLarge else MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            maxLines = 1,
            textAlign = TextAlign.Center
        )
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            textAlign = TextAlign.Center
        )
    }
}

/** Acción del panel inferior idle: círculo 58/70 + caption (LiveActivityView.selectionCircle). */
@Composable
private fun RowScope.LiveIdleSelectionAction(
    icon: ImageVector,
    label: String,
    filledGreen: Boolean,
    tag: String,
    onClick: () -> Unit,
    countdown: Int? = null,
    size: Dp = 58.dp
) {
    Column(
        Modifier
            .weight(1f)
            .testTag(tag)
            .clickable(onClick = onClick)
            .semantics { contentDescription = label },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(7.dp)
    ) {
        Box(
            Modifier
                .size(size)
                .shadow(if (filledGreen) 0.dp else 1.dp, CircleShape)
                .clip(CircleShape)
                .background(if (filledGreen) brandGreen else MaterialTheme.colorScheme.surface)
                .then(
                    if (!filledGreen)
                        Modifier.border(
                            1.dp,
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.10f),
                            CircleShape
                        )
                    else Modifier
                ),
            contentAlignment = Alignment.Center
        ) {
            if (countdown != null) {
                Text(
                    "$countdown",
                    style = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Bold),
                    color = Color.Black,
                    modifier = Modifier.testTag("live_start_countdown")
                )
            } else {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = if (filledGreen) Color.Black else brandGreen,
                    modifier = Modifier.size(if (filledGreen) 28.dp else 25.dp)
                )
            }
        }
        Text(
            label,
            style = MaterialTheme.typography.labelSmall.copy(
                fontWeight = if (filledGreen) FontWeight.Bold else FontWeight.Medium,
                fontSize = 11.sp
            ),
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center
        )
    }
}

/** Pitidos/vibración de la cuenta atrás 3-2-1 (paridad RestFeedback.tick iOS). */
private object LiveStartFeedback {
    fun tick(context: android.content.Context, remaining: Int, sound: Boolean) {
        if (remaining !in 1..3) return
        if (sound) {
            runCatching {
                val tg = android.media.ToneGenerator(android.media.AudioManager.STREAM_ALARM, 85)
                tg.startTone(android.media.ToneGenerator.TONE_PROP_BEEP, 120)
            }
        }
        runCatching {
            val vibrator = context.getSystemService(android.os.Vibrator::class.java)
            vibrator?.vibrate(
                android.os.VibrationEffect.createOneShot(80, android.os.VibrationEffect.DEFAULT_AMPLITUDE)
            )
        }
    }

    fun complete(context: android.content.Context, sound: Boolean) {
        if (sound) {
            runCatching {
                val tg = android.media.ToneGenerator(android.media.AudioManager.STREAM_ALARM, 85)
                tg.startTone(android.media.ToneGenerator.TONE_PROP_BEEP, 400)
            }
        }
        runCatching {
            val vibrator = context.getSystemService(android.os.Vibrator::class.java)
            vibrator?.vibrate(
                android.os.VibrationEffect.createOneShot(250, android.os.VibrationEffect.DEFAULT_AMPLITUDE)
            )
        }
    }
}

/** Reloj Comenzar: MM:SS bajo 1 h; H:MM:SS con hora sin cero a la izquierda. */
internal object LiveActivityClock {
    fun format(seconds: Double): String = format(seconds.toInt())
    fun format(seconds: Long): String = format(seconds.toInt())
    fun format(seconds: Int): String {
        val total = maxOf(0, seconds)
        return if (total >= 3600) {
            "%d:%02d:%02d".format(java.util.Locale.ROOT, total / 3600, (total / 60) % 60, total % 60)
        } else {
            "%02d:%02d".format(java.util.Locale.ROOT, (total / 60) % 60, total % 60)
        }
    }
}
