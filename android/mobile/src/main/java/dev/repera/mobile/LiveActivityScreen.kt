package dev.repera.mobile

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.Map
import androidx.compose.material.icons.outlined.MyLocation
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.Timeline
import androidx.compose.material.icons.outlined.ViewInAr
import androidx.compose.material.icons.outlined.VolumeOff
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material.icons.outlined.Whatshot
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
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
import dev.repera.domain.LiveSportHistory
import dev.repera.domain.AdaptiveRoutePace
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Primer wiring ejecutable: no estima kcal/pulso ni escribe Salud.
 * Rutas, voz y revisión visual se completan por separado, no se ocultan. */
@Composable
internal fun LiveActivityScreen(accountId: String, onSaved: (sessionId: String) -> Unit,
    onOpenTools: () -> Unit, onOpenCenter: (() -> Unit)? = null,
    hasActiveWorkout: Boolean = false, onOpenWorkout: () -> Unit = {},
    onMapRendered: (() -> Unit)? = null,
    onSavedDay: (Long) -> Unit = {},
    initialSportId: String? = null,
    onInitialSportConsumed: () -> Unit = {}) {
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
            title = { Text("No se pudo comprobar Pro") },
            text = { Text("No se ha podido verificar tu suscripción. Comprueba el acceso en Ajustes o restaura tus compras.") },
            confirmButton = {
                TextButton(onClick = { show3DAccessVerificationError = false }) { Text("Aceptar") }
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

    if(accountId.isBlank()) { Text("Inicia sesión para guardar actividades.");return }
    // Altura real del chrome (menú + Continuar). Sin sumar navigationBars otra vez:
    // tabChromeInset ya incluye nav bars medidos en el host.
    val tabChromeInset = LocalReperaTabBarInset.current
    val bottomChromePad = tabChromeInset.takeIf { it > 0.dp } ?: 96.dp
    val runtime=remember(accountId) { LiveActivityRuntime.forAccount(context,accountId) }
    val revision by runtime.updates.collectAsState()
    // Leer antes de cualquier retorno (también canvas GPS): los campos de
    // recorder son puros, la señal Flow invalida todas las ramas de UI.
    @Suppress("UNUSED_VARIABLE") val observedRevision = revision
    val state=runtime.state
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
    LaunchedEffect(initialSportId, state.phase) {
        val sportId = initialSportId ?: return@LaunchedEffect
        if (state.phase != LiveActivityState.Phase.IDLE) {
            onInitialSportConsumed(); return@LaunchedEffect
        }
        LiveSport.byId(sportId)?.let { runtime.choose(it) }
        onInitialSportConsumed()
    }
    LaunchedEffect(state.phase) {
        while (state.phase == dev.repera.domain.LiveActivityState.Phase.RECORDING) {
            kotlinx.coroutines.delay(1000L); nowTick = System.currentTimeMillis()
        }
    }
    val routesStore = remember(accountId) { runCatching { LiveRoutesStore(context, accountId) }.getOrNull() }
    var routesVersion by remember { mutableStateOf(0) }
    var showRoutes by remember { mutableStateOf(false) }
    var pendingDeleteRoute by remember { mutableStateOf<LiveSavedRoute?>(null) }
    LaunchedEffect(routesStore) {
        if (routesStore != null) {
            try {
                val overview = StateOverview.fromBytes(LocalSnapshotStore(context, accountId).read())
                val candidates = overview?.liveSportSessions.orEmpty().mapNotNull { session ->
                    val routeID = session.liveRouteID ?: return@mapNotNull null
                    val detail = overview?.completeHistory?.firstOrNull { it.id == session.id } ?: return@mapNotNull null
                    if (detail.routePoints.size < 2) return@mapNotNull null
                    LiveSavedRoute(id = routeID, title = detail.title, points = detail.routePoints,
                        sportID = session.sportID, createdAtMillis = session.startedEpochMillis ?: Long.MIN_VALUE)
                }
                routesStore.recoverFromSessions(candidates);routesVersion++
            } catch (_: Exception) { /* Keep prior routes; no destructive recovery. */ }
        }
    }
    val routes = remember(routesStore, routesVersion) { routesStore?.recentRoutes(runCatching {
        val bytes = LocalSnapshotStore(context, accountId).read()
        bytes?.let { LiveSportSnapshot.sessions(org.json.JSONObject(String(it))) }.orEmpty()
    }.getOrDefault(emptyList())).orEmpty() }
    var title by remember(accountId) { mutableStateOf("") }
    var notes by remember(accountId) { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var confirmDiscard by remember { mutableStateOf(false) }
    var showSportPicker by remember { mutableStateOf(false) }
    var sportQuery by remember {mutableStateOf("")}
    var showingMetrics by remember(accountId) {
        mutableStateOf(mapPrefs.getBoolean("preferredDisplay.metrics", false))
    }
    LaunchedEffect(showingMetrics) {
        mapPrefs.edit().putBoolean("preferredDisplay.metrics", showingMetrics).apply()
    }
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
    /** Los tres pitidos son los del temporizador; el GPS empieza DESPUÉS. */
    fun beginStartCountdown() {
        if (currentActiveWorkout) { currentOpenWorkout(); return }
        if (runtime.recoveryBlocked) { error = runtime.lastError; return }
        if (startCountdown > 0 || state.phase != LiveActivityState.Phase.IDLE) return
        startCountdownToken++
        startCountdown = 3
        LiveStartFeedback.tick(context, 3, sound = runtime.spokenGuidanceEnabled)
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
    val permissions=rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        beginStartCountdown()
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
                        "Elegir actividad",
                        style = MaterialTheme.typography.titleLarge,
                        modifier = Modifier.weight(1f)
                    )
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.Close,
                        contentDescription = "Cerrar",
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
                                onClick = { runtime.choose(sport); showSportPicker = false },
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
                    placeholder = "Buscar actividad",
                    modifier = Modifier
                        .padding(top = 8.dp)
                        .testTag("sport_picker_search")
                )
            }
        }
    }
    if (showRoutes) {
        @OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
        ReperaModalBottomSheet(onDismissRequest = {
            showRoutes = false
            recenterToken++
        }) {
            Column(
                Modifier.fillMaxWidth().heightIn(max = 560.dp)
                    .verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // R8 P2: un solo título (RouteLibraryHeader ya dice «Mis rutas»).
                RouteLibraryHeader { showRoutes = false }
                if (routes.isEmpty()) {
                    ReperaEmptyState(
                        title = "Todavía no hay rutas",
                        subtitle = "Graba un recorrido o importa un GPX para empezar."
                    )
                }
                TextButton(onClick = {
                    importGPX.launch(arrayOf(
                        "application/gpx+xml", "application/xml", "text/xml",
                        "application/octet-stream"
                    ))
                }) { Text("Importar archivo GPX") }
                val recentRoutes = routesStore?.latestRoutes?.take(5).orEmpty()
                val favoriteRoutes = routesStore?.favoriteRoutes.orEmpty()
                if (recentRoutes.isNotEmpty()) {
                    Text("Últimas rutas", style = MaterialTheme.typography.titleSmall)
                    recentRoutes.forEach { route ->
                        ReperaCard(
                            onClick = { runtime.selectRoute(route.id); showRoutes = false },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                Modifier.padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Text(route.title, style = MaterialTheme.typography.titleSmall)
                                Text(
                                    "${ReperaNumberFormat.decimal(route.distanceKm)} km · ${route.sportTitle}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
                if (favoriteRoutes.isNotEmpty()) {
                    Text("Favoritos", style = MaterialTheme.typography.titleSmall)
                    favoriteRoutes.forEach { route ->
                        ReperaCard(
                            onClick = { runtime.selectRoute(route.id); showRoutes = false },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                Modifier.padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Text(route.title, style = MaterialTheme.typography.titleSmall)
                                Text(
                                    "${ReperaNumberFormat.decimal(route.distanceKm)} km · ${route.sportTitle}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    pendingDeleteRoute?.let { route ->
        AlertDialog(onDismissRequest = { pendingDeleteRoute = null },
            title = { Text("¿Eliminar ruta?") }, text = { Text("Se borrará la ruta guardada. Tus actividades realizadas se conservan.") },
            confirmButton = { TextButton(onClick = {
                try {
                    routesStore?.remove(route.id)
                    if (state.selectedRouteID == route.id) runtime.selectRoute(null)
                    routesVersion++;pendingDeleteRoute = null
                } catch (_: Exception) { error = "No se pudo eliminar la ruta." }
            }) { Text("Eliminar") } },
            dismissButton = { TextButton(onClick = { pendingDeleteRoute = null }) { Text("Cancelar") } })
    }
    if (confirmDiscard) {
        ReperaConfirmSheet(
            title = "¿Descartar actividad?",
            message = "Perderás el recorrido y los datos que no hayas guardado.",
            confirmTitle = "Descartar sin guardar",
            onConfirm = {
                if (runtime.discard()) {
                    LiveActivityService.stop(context)
                    title = ""
                    notes = ""
                    showingMetrics = false
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
    // El mapa permanece compuesto con la hoja de rutas encima (no se desmonta).
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
        BoxWithConstraints(Modifier.fillMaxSize().testTag("live_activity_screen")) {
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
            // FABs a la derecha (LiveActivityView.mapHeader): pausa/fin + mapa/métricas/voz.
            Column(
                Modifier
                    .align(Alignment.TopEnd)
                    .statusBarsPadding()
                    .padding(top = 12.dp, end = 16.dp)
                    .testTag("live_map_fabs"),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                horizontalAlignment = Alignment.End
            ) {
                if (state.phase == LiveActivityState.Phase.RECORDING) {
                    LiveMapSessionFab(
                        Icons.Filled.Pause, "Pausar grabación",
                        background = Color(0xFFFFD60A), foreground = Color.Black
                    ) { runtime.pause() }
                } else if (state.phase == LiveActivityState.Phase.PAUSED) {
                    LiveMapSessionFab(
                        Icons.Filled.PlayArrow, "Reanudar grabación",
                        background = brandGreen, foreground = Color.Black
                    ) { runtime.resume(); startService() }
                    LiveMapSessionFab(
                        Icons.Outlined.Flag, "Finalizar y guardar",
                        background = Color.Black, foreground = Color.White
                    ) {
                        runtime.finish(); LiveActivityService.stop(context)
                    }
                }
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
                if (!followingMap && (state.points.isNotEmpty() || freshPosition != null)) {
                    LiveMapCircleFab(Icons.Outlined.MyLocation, "Centrar en mi posición") {
                        followingMap = true; recenterToken++
                    }
                }
                LiveMapCircleFab(Icons.Outlined.BarChart, "Ver métricas") { showingMetrics = true }
                LiveMapCircleFab(
                    if (runtime.spokenGuidanceEnabled) Icons.Outlined.VolumeUp else Icons.Outlined.VolumeOff,
                    if (runtime.spokenGuidanceEnabled) "Desactivar avisos por voz" else "Activar avisos por voz"
                ) {
                    runtime.toggleSpokenGuidance()
                    if (!runtime.spokenGuidanceEnabled && android.os.Build.VERSION.SDK_INT >= 33)
                        notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
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
                        .background(Color(0xFF30D158), RoundedCornerShape(18.dp))
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
                                "Revisa el mapa",
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
                ) { Text("Descartar recuperación dañada") }
            }
            // Hueco = altura medida del chrome (menú ± Continuar); sin sumar navBars otra vez.
            Surface(
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
                    .testTag("live_idle_panel"),
                shape = RoundedCornerShape(28.dp),
                color = MaterialTheme.colorScheme.surface.copy(alpha = 0.92f),
                tonalElevation = 0.dp,
                // R7: sombra suave sobre mapa (evitar bandas/halos fuertes).
                shadowElevation = 1.dp,
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f))
            ) {
                if (state.phase == LiveActivityState.Phase.IDLE) {
                    // bottomControls iOS: deporte | Iniciar | Cargar ruta (círculos).
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceEvenly,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        LiveIdleSelectionAction(
                            icon = state.sport.materialIcon,
                            label = state.sport.title,
                            filledGreen = false,
                            tag = "live_sport_picker",
                            onClick = { showSportPicker = true }
                        )
                        LiveIdleSelectionAction(
                            icon = Icons.Filled.PlayArrow,
                            label = when {
                                hasActiveWorkout -> "Continuar"
                                startCountdown > 0 -> "Cancelar"
                                else -> "Iniciar"
                            },
                            filledGreen = true,
                            countdown = startCountdown.takeIf { it > 0 },
                            size = 70.dp,
                            tag = "live_start",
                            onClick = {
                                if (hasActiveWorkout) onOpenWorkout()
                                else if (startCountdown > 0) cancelStartCountdown()
                                else if (ContextCompat.checkSelfPermission(
                                        context, Manifest.permission.ACCESS_FINE_LOCATION
                                    ) != PackageManager.PERMISSION_GRANTED
                                ) {
                                    permissions.launch(
                                        arrayOf(
                                            Manifest.permission.ACCESS_FINE_LOCATION,
                                            Manifest.permission.ACCESS_COARSE_LOCATION
                                        )
                                    )
                                } else beginStartCountdown()
                            }
                        )
                        LiveIdleSelectionAction(
                            icon = Icons.Outlined.Timeline,
                            label = if (state.selectedRouteID == null) "Cargar ruta" else "Ruta elegida",
                            filledGreen = false,
                            tag = "live_load_route",
                            onClick = { showRoutes = true }
                        )
                    }
                } else {
                    LiveMapMetricStrip(state = state, nowTick = nowTick)
                }
            }
        }
        return
    }
    // Métricas GPS (LiveActivityView.metricsView): tiles con Spacers, no lista scroll.
    if (state.sport.usesGPS && state.phase != LiveActivityState.Phase.REVIEW &&
        showingMetrics && !showRoutes
    ) {
        val durationSec = state.durationSeconds(nowTick)
        val durationText = run {
            val total = maxOf(0, durationSec.toInt())
            "%02d:%02d:%02d".format(total / 3600, (total / 60) % 60, total % 60)
        }
        val average = state.averageSpeedKmh(nowTick)
        val paceOrSpeed = when {
            average == null || average <= 0.1 ->
                if (state.sport.displaysSpeed) "—" else "—:—"
            state.sport.displaysSpeed -> ReperaNumberFormat.decimal(average)
            else -> {
                val secs = (3600.0 / average).toInt()
                if (secs >= 3600) "—:—" else "%d:%02d".format(secs / 60, secs % 60)
            }
        }
        val paceLabel = if (state.sport.displaysSpeed)
            "Velocidad media (km/h)" else "Ritmo medio (min/km)"
        val km = state.distanceMeters / 1000.0
        Column(
            Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .padding(bottom = bottomChromePad)
                .testTag("live_activity_screen")
        ) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 14.dp)
                    .heightIn(min = 54.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(
                    state.sport.materialIcon,
                    contentDescription = null,
                    tint = brandGreen,
                    modifier = Modifier.size(28.dp)
                )
                Text(
                    state.sport.title,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                // Paridad iOS metricsTrailingActions: Audio · Mapa · Pausa | Finalizar+Play.
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    LiveMapCircleFab(
                        if (runtime.spokenGuidanceEnabled) Icons.Outlined.VolumeUp
                        else Icons.Outlined.VolumeOff,
                        if (runtime.spokenGuidanceEnabled) "Desactivar avisos por voz"
                        else "Activar avisos por voz"
                    ) {
                        runtime.toggleSpokenGuidance()
                        if (!runtime.spokenGuidanceEnabled && android.os.Build.VERSION.SDK_INT >= 33)
                            notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
                    }
                    LiveMapCircleFab(Icons.Outlined.Map, "Ver mapa") {
                        showingMetrics = false
                    }
                    if (state.phase == LiveActivityState.Phase.RECORDING) {
                        LiveMapSessionFab(
                            Icons.Filled.Pause, "Pausar grabación",
                            background = Color(0xFFFFD60A), foreground = Color.Black,
                            onClick = { runtime.pause() }
                        )
                    } else if (state.phase == LiveActivityState.Phase.PAUSED) {
                        LiveMapSessionFab(
                            Icons.Outlined.Flag, "Finalizar y guardar",
                            background = Color.Black, foreground = Color.White,
                            onClick = {
                                runtime.finish(); LiveActivityService.stop(context)
                            }
                        )
                        LiveMapSessionFab(
                            Icons.Filled.PlayArrow, "Reanudar grabación",
                            background = brandGreen, foreground = Color.Black,
                            onClick = { runtime.resume(); startService() }
                        )
                    }
                }
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
                "Duración",
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            if (state.phase != LiveActivityState.Phase.IDLE) {
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
                "Distancia (km)",
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            if (state.sport.tracksElevation && state.hasElevationSamples) {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 28.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        "+%.0f m".format(state.elevationGainMeters),
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        "−%.0f m".format(state.elevationLossMeters),
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Spacer(Modifier.weight(1f, fill = true).heightIn(min = 12.dp))
            if (state.phase == LiveActivityState.Phase.IDLE) {
                Surface(
                    Modifier
                        .fillMaxWidth()
                        .padding(start = 12.dp, end = 12.dp, top = 12.dp, bottom = 8.dp)
                        .testTag("live_idle_panel"),
                    shape = RoundedCornerShape(28.dp),
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.92f),
                    tonalElevation = 0.dp,
                    shadowElevation = 1.dp,
                    border = BorderStroke(
                        1.dp,
                        MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)
                    )
                ) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceEvenly,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        LiveIdleSelectionAction(
                            icon = state.sport.materialIcon,
                            label = state.sport.title,
                            filledGreen = false,
                            tag = "live_sport_picker",
                            onClick = { showSportPicker = true }
                        )
                        LiveIdleSelectionAction(
                            icon = Icons.Filled.PlayArrow,
                            label = when {
                                hasActiveWorkout -> "Continuar"
                                startCountdown > 0 -> "Cancelar"
                                else -> "Iniciar"
                            },
                            filledGreen = true,
                            countdown = startCountdown.takeIf { it > 0 },
                            size = 70.dp,
                            tag = "live_start",
                            onClick = {
                                if (hasActiveWorkout) onOpenWorkout()
                                else if (startCountdown > 0) cancelStartCountdown()
                                else if (ContextCompat.checkSelfPermission(
                                        context, Manifest.permission.ACCESS_FINE_LOCATION
                                    ) != PackageManager.PERMISSION_GRANTED
                                ) {
                                    permissions.launch(
                                        arrayOf(
                                            Manifest.permission.ACCESS_FINE_LOCATION,
                                            Manifest.permission.ACCESS_COARSE_LOCATION
                                        )
                                    )
                                } else beginStartCountdown()
                            }
                        )
                        LiveIdleSelectionAction(
                            icon = Icons.Outlined.Timeline,
                            label = if (state.selectedRouteID == null) "Cargar ruta" else "Ruta elegida",
                            filledGreen = false,
                            tag = "live_load_route",
                            onClick = { showRoutes = true }
                        )
                    }
                }
            } else {
                (error ?: runtime.lastError)?.let {
                    Text(
                        it,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
                // El Column ya reserva bottomChromePad frente al menú.
                Spacer(Modifier.height(8.dp))
            }
        }
        return
    }
    // REVIEW: resumen estilo Fitness (mapa + métricas + guardar), sin el formulario genérico.
    if (state.phase == LiveActivityState.Phase.REVIEW) {
        LiveActivityReviewContent(
            state = state,
            title = title,
            onTitleChange = { title = it },
            notes = notes,
            onNotesChange = { notes = it },
            previewHealth = previewHealth,
            routes = routes,
            nowTick = nowTick,
            error = error ?: runtime.lastError,
            onMapRendered = onMapRendered,
            onSave = {
                try {
                    val now = System.currentTimeMillis()
                    val savedDay = state.startedMillis ?: now
                    val sessionId = WorkoutRepository(context, accountId).saveLiveActivity(
                        state.snapshot(now)!!,
                        state.finishedMillis ?: now,
                        state.durationSeconds(now),
                        title,
                        notes
                    )
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
                } catch (_: Exception) {
                    error = "No se pudo guardar. La actividad sigue disponible para reintentar."
                }
            },
            onDiscard = { confirmDiscard = true },
            recoveryBlocked = runtime.recoveryBlocked
        )
        return
    }
    // Sin GPS / rutas: formulario bajo status bar (mapa usa fillMaxSize a sangre).
    Column(
        Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
            .padding(bottom = bottomChromePad)
            .testTag("live_activity_screen"),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        ReperaPageHeader(title = "Comenzar")
        Text(state.sport.title,style=MaterialTheme.typography.titleLarge)
        if(state.sport.usesGPS)
            TextButton(onClick={showingMetrics=false;showRoutes=false}) {Text("Ver mapa")}
        if(state.phase==LiveActivityState.Phase.IDLE) {
            OutlinedButton(onClick = { showSportPicker = true }, modifier = Modifier.testTag("live_sport_picker")) {
                Text("Elegir actividad: ${state.sport.title}")
            }
            Text(state.sport.metricDescription)
            TextButton(onClick = {
                runtime.toggleSpokenGuidance()
                if (!runtime.spokenGuidanceEnabled && android.os.Build.VERSION.SDK_INT >= 33)
                    notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
            }) {
                Text(if (runtime.spokenGuidanceEnabled) "Desactivar avisos por voz" else "Activar avisos por voz")
            }
            if (state.sport.usesGPS) {
                TextButton(onClick = { showRoutes = true }) { Text("Mis rutas") }
                state.selectedRouteID?.let { selected ->
                    Text("Ruta: ${routes.firstOrNull { it.id == selected }?.title ?: "No disponible"}")
                    TextButton(onClick = { runtime.selectRoute(null) }) { Text("Sin ruta planificada") }
                }
            }
            Button(onClick={
                if (hasActiveWorkout) onOpenWorkout()
                else if (startCountdown > 0) cancelStartCountdown()
                else if(state.sport.usesGPS && ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_FINE_LOCATION)!=PackageManager.PERMISSION_GRANTED)
                    permissions.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION))
                else beginStartCountdown()
            },modifier=Modifier.testTag("live_start")) {
                Text(when {
                    hasActiveWorkout -> "Continuar entrenamiento"
                    startCountdown > 0 -> "Cancelar ($startCountdown)"
                    else -> "Empezar actividad"
                })
            }
        } else {
            Text(LiveSportHistory.formatDuration(state.durationSeconds(nowTick)),style=MaterialTheme.typography.displayMedium)
            if(state.sport.usesGPS) {
                Text("${ReperaNumberFormat.decimal(state.distanceMeters/1000)} km",style=MaterialTheme.typography.headlineSmall)
                val now = System.currentTimeMillis()
                if (state.sport.displaysSpeed) {
                    state.averageSpeedKmh(now)?.let { Text("${ReperaNumberFormat.decimal(it)} km/h de media") }
                    state.currentSpeedMps?.let { Text("${ReperaNumberFormat.decimal(it * 3.6)} km/h") }
                } else {
                    val speed = state.currentSpeedMps
                    if (speed != null && speed > 0.5) Text("${LiveSportHistory.formatDuration(1000 / speed)} min/km")
                    else Text("Ritmo sin datos")
                }
                if (state.sport.tracksElevation && state.hasElevationSamples)
                    Text("+%.0f m / -%.0f m".format(state.elevationGainMeters, state.elevationLossMeters))
                if (state.activeKilometerMeters >= 40) {
                    val split = state.currentSplitSeconds(now)
                    val current = if (state.sport.displaysSpeed && split > 0)
                        "${ReperaNumberFormat.decimal(state.activeKilometerMeters / split * 3.6)} km/h"
                    else "${LiveSportHistory.formatDuration(split * 1000 / state.activeKilometerMeters)} min/km"
                    Text("Km ${state.activeKilometer} · $current")
                }
                LiveKilometerSplitsSection(state.splitsSeconds, state.sport.displaysSpeed)
                TextButton(onClick = { runtime.toggleSpokenGuidance() }) {
                    Text(
                        if (runtime.spokenGuidanceEnabled) "Desactivar avisos por voz"
                        else "Activar avisos por voz"
                    )
                }
            }
            runtime.upcomingTurn?.let { Text(it, style = MaterialTheme.typography.titleMedium) }
            runtime.latestKilometerReport?.let { Text(it) }
            when(state.phase) {
                LiveActivityState.Phase.RECORDING -> Button(onClick={runtime.pause()},modifier=Modifier.testTag("live_pause")) {Text("Pausar")}
                LiveActivityState.Phase.PAUSED -> {
                    Text("En pausa")
                    Button(onClick={runtime.resume();startService()},modifier=Modifier.testTag("live_resume")) {Text("Reanudar")}
                }
                else -> {}
            }
            Button(
                onClick = { runtime.finish(); LiveActivityService.stop(context) },
                modifier = Modifier.testTag("live_finish")
            ) { Text("Finalizar") }
            TextButton(onClick = { confirmDiscard = true }) { Text("Descartar") }
            LiveKilometerSplitsSection(state.splitsSeconds, state.sport.displaysSpeed)
        }
        (error ?: runtime.lastError)?.let {Text(it,color=MaterialTheme.colorScheme.error)}
        if(runtime.recoveryBlocked) TextButton(onClick={confirmDiscard=true}) {Text("Descartar recuperación dañada")}
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
                    "Recorrido no disponible",
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
    routes: List<LiveSavedRoute>,
    nowTick: Long,
    error: String?,
    onMapRendered: (() -> Unit)?,
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
            if (secs >= 3600) "—:—" else "%d:%02d".format(secs / 60, secs % 60)
        }
    }
    val energyText = previewHealth?.activeEnergyKcal?.takeIf { it.isFinite() && it > 0 }
        ?.let { "%.0f kcal".format(it) } ?: "—"
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
        ReperaPageHeader(title = "Guardar entreno")
        if (state.sport.usesGPS && previewPoints.isNotEmpty()) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(MaterialTheme.colorScheme.surface)
                    .testTag("live_review_map_card")
            ) {
                RouteMapTapTarget(
                    label = "Abrir recorrido a pantalla completa",
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
                        modifier = Modifier.testTag("live_review_weather_under_map")
                    )
                }
            }
        }
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
                modifier = Modifier.testTag("live_review_started_subtitle")
            )
        }
        // Una sola fila: tiempo · distancia · ritmo · energía (paridad pedida).
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            WorkoutSummaryTile(
                "Tiempo",
                LiveSportHistory.formatDuration(state.durationSeconds(nowTick)),
                Icons.Outlined.AccessTime,
                Modifier.weight(1f),
                iconTint = Color(0xFF0A84FF),
                compact = true
            )
            if (state.sport.usesGPS) {
                WorkoutSummaryTile(
                    "Distancia",
                    ReperaNumberFormat.decimal(state.distanceMeters / 1000) + " km",
                    Icons.Outlined.Route,
                    Modifier.weight(1f),
                    iconTint = brandGreen,
                    compact = true
                )
                WorkoutSummaryTile(
                    if (state.sport.displaysSpeed) "Veloc." else "Ritmo",
                    paceOrSpeed,
                    Icons.Outlined.AccessTime,
                    Modifier.weight(1f),
                    iconTint = Color(0xFF0A84FF),
                    compact = true
                )
            }
            WorkoutSummaryTile(
                "Energía",
                energyText,
                Icons.Outlined.Whatshot,
                Modifier.weight(1f),
                iconTint = Color(0xFFFF9F0A),
                compact = true
            )
        }
        if (state.sport.usesGPS && previewPoints.isEmpty()) {
            LiveReviewMapUnavailableCard(
                hasDistance = state.distanceMeters > 0,
                modifier = Modifier.fillMaxWidth()
            )
        }
        if (state.sport.tracksElevation && state.hasElevationSamples) {
            Text(
                "+%.0f m de ascenso · −%.0f m de descenso".format(
                    state.elevationGainMeters,
                    state.elevationLossMeters
                ),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        if (state.splitsSeconds.isNotEmpty()) {
            ReperaSectionTitle("Entreno")
            ReperaCard(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp)) {
                    LiveKilometerSplitsSection(
                        state.splitsSeconds,
                        state.sport.displaysSpeed,
                        routePoints = if (previewRecorded) state.points else emptyList()
                    )
                }
            }
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
        Button(
            onClick = onSave,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .testTag("live_save"),
            colors = ButtonDefaults.buttonColors(
                containerColor = brandGreen,
                contentColor = Color.Black
            ),
            shape = RoundedCornerShape(999.dp)
        ) {
            Text("Guardar", fontWeight = FontWeight.Bold)
        }
        TextButton(
            onClick = onDiscard,
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
        ) {
            Text("Descartar actividad", color = Color(0xFFFF453A))
        }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        if (recoveryBlocked) {
            TextButton(onClick = onDiscard) { Text("Descartar recuperación dañada") }
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

/** Panel activo: duración, ritmo/velocidad, distancia + parcial del km (paridad mapMetricStrip iOS). */
@Composable
private fun LiveMapMetricStrip(state: LiveActivityState, nowTick: Long) {
    val durationSec = state.durationSeconds(nowTick)
    val durationText = run {
        val total = maxOf(0, durationSec.toInt())
        "%02d:%02d:%02d".format(total / 3600, (total / 60) % 60, total % 60)
    }
    val average = state.averageSpeedKmh(nowTick)
    val paceOrSpeed = when {
        average == null || average <= 0.1 ->
            if (state.sport.displaysSpeed) "—" else "—:—"
        state.sport.displaysSpeed -> ReperaNumberFormat.decimal(average)
        else -> {
            val secs = (3600.0 / average).toInt()
            if (secs >= 3600) "—:—" else "%d:%02d".format(secs / 60, secs % 60)
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
        if (state.sport.tracksElevation && state.hasElevationSamples) {
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 10.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    "+${state.elevationGainMeters.toInt()} m ascenso",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    "−${state.elevationLossMeters.toInt()} m descenso",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
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
