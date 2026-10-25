package dev.repera.mobile

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import dev.repera.domain.LiveActivityState
import dev.repera.domain.LiveSport
import dev.repera.domain.LiveSportHistory
import kotlinx.coroutines.delay

/** Primer wiring ejecutable: no estima kcal/pulso ni escribe Salud.
 * Rutas, voz y revisión visual se completan por separado, no se ocultan. */
@Composable
internal fun LiveActivityScreen(accountId: String, onSaved: () -> Unit,
    onOpenTools: () -> Unit, onOpenCenter: (() -> Unit)? = null,
    hasActiveWorkout: Boolean = false, onOpenWorkout: () -> Unit = {}) {
    val context=LocalContext.current
    if(accountId.isBlank()) { Text("Inicia sesión para guardar actividades.");return }
    val runtime=remember(accountId) { LiveActivityRuntime.forAccount(context,accountId) }
    val revision by runtime.updates.collectAsState()
    val state=runtime.state
    val routesStore = remember(accountId) { runCatching { LiveRoutesStore(context, accountId) }.getOrNull() }
    var routesVersion by remember { mutableStateOf(0) }
    var showRoutes by remember { mutableStateOf(false) }
    var pendingDeleteRoute by remember { mutableStateOf<LiveSavedRoute?>(null) }
    var routeListMode by remember { mutableStateOf("Últimas 5") }
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
    var title by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var confirmDiscard by remember { mutableStateOf(false) }
    var showSportPicker by remember { mutableStateOf(false) }
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
    val currentActiveWorkout by rememberUpdatedState(hasActiveWorkout)
    val currentOpenWorkout by rememberUpdatedState(onOpenWorkout)
    fun start() {
        // También comprobar tras volver del diálogo de permiso, no solo
        // antes: puede haberse reactivado un entreno clásico mientras tanto.
        if (currentActiveWorkout) { currentOpenWorkout();return }
        runtime.start();startService()
    }
    val notificationPermission=rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {}
    val permissions=rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { start() }
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
        androidx.compose.ui.window.Dialog(onDismissRequest = { showSportPicker = false }) {
            Surface(shape = MaterialTheme.shapes.large) {
                Column(Modifier.fillMaxWidth().heightIn(max = 560.dp).verticalScroll(rememberScrollState()).padding(16.dp)) {
                    Text("Elegir actividad", style = MaterialTheme.typography.titleLarge)
                    LiveSport.groups.forEach { group ->
                        Text(group, style = MaterialTheme.typography.titleSmall, modifier = Modifier.padding(top = 12.dp))
                        LiveSport.entries.filter { it.group == group }.forEach { sport ->
                            TextButton(onClick = { runtime.choose(sport);showSportPicker = false },
                                modifier = Modifier.fillMaxWidth().testTag("choose_sport_${sport.id}")) {
                                Text((if (state.sport == sport) "✓ " else "") + sport.title)
                            }
                        }
                    }
                    TextButton(onClick = { showSportPicker = false }) { Text("Cerrar") }
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
    if(confirmDiscard) AlertDialog(onDismissRequest={confirmDiscard=false},
        title={Text("¿Descartar actividad?")},text={Text("No se guardará esta actividad.")},
        confirmButton={TextButton(onClick={ if(runtime.discard()) LiveActivityService.stop(context);confirmDiscard=false }) {Text("Descartar")}},
        dismissButton={TextButton(onClick={confirmDiscard=false}) {Text("Cancelar")}})
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)
        .testTag("live_activity_screen"),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        // Lectura de revision asegura recomposición del estado puro compartido.
        @Suppress("UNUSED_VARIABLE") val version=revision
        Text("Comenzar",style=MaterialTheme.typography.headlineMedium)
        Text(state.sport.title,style=MaterialTheme.typography.titleLarge)
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
                Text(if (runtime.spokenGuidanceEnabled) "Guía hablada activada" else "Guía hablada desactivada")
            }
            if (state.sport.usesGPS) {
                TextButton(onClick = { showRoutes = !showRoutes }) { Text("Biblioteca de rutas") }
                state.selectedRouteID?.let { selected ->
                    Text("Ruta: ${routes.firstOrNull { it.id == selected }?.title ?: "No disponible"}")
                    TextButton(onClick = { runtime.selectRoute(null) }) { Text("Sin ruta planificada") }
                }
                if (showRoutes) {
                    Button(onClick = { importGPX.launch(arrayOf("application/gpx+xml", "application/xml", "text/xml", "application/octet-stream")) }) { Text("Importar GPX") }
                    if (routes.isEmpty()) Text("Sin rutas guardadas")
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf("Últimas 5", "Favoritas", "Todas").forEach { mode ->
                            FilterChip(selected = routeListMode == mode, onClick = { routeListMode = mode }, label = { Text(mode) })
                        }
                    }
                    val visibleRoutes = when (routeListMode) {
                        "Últimas 5" -> routes.take(5)
                        "Favoritas" -> routes.filter { it.isFavorite }
                        else -> routes
                    }
                    visibleRoutes.forEach { route ->
                        var edit by remember(route.id) { mutableStateOf(false) }
                        var routeTitle by remember(route.id, routesVersion) { mutableStateOf(route.title) }
                        var routeSport by remember(route.id, routesVersion) { mutableStateOf(route.sportID) }
                        Card(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text(route.title, style = MaterialTheme.typography.titleSmall)
                                Text("%.2f km · %s".format(route.distanceKm, route.sportTitle))
                                if (route.points.size >= 2) RouteMapView(route.points, isInteractive = false,
                                    modifier = Modifier.fillMaxWidth().height(110.dp))
                                Row {
                                    TextButton(onClick = { runtime.selectRoute(route.id); showRoutes = false }) { Text("Elegir") }
                                    TextButton(onClick = {
                                        try { routesStore?.setFavorite(route.id, !route.isFavorite); routesVersion++ }
                                        catch (_: Exception) { error = "No se pudo cambiar el favorito." }
                                    }) { Text(if (route.isFavorite) "★ Favorita" else "☆ Favorita") }
                                    TextButton(onClick = { edit = !edit }) { Text("Editar") }
                                    TextButton(onClick = { pendingDeleteRoute = route }) { Text("Eliminar") }
                                }
                                if (edit) {
                                    OutlinedTextField(routeTitle, { routeTitle = it }, label = { Text("Nombre de la ruta") })
                                    Text("Deporte: ${routeSport?.let(LiveSport::byId)?.title ?: "Sin deporte"}")
                                    FlowRow(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                        listOf<LiveSport?>(null).plus(LiveSport.entries.filter { it.usesGPS }).forEach { option ->
                                            FilterChip(selected = routeSport == option?.id,
                                                onClick = { routeSport = option?.id }, label = { Text(option?.title ?: "Sin deporte") })
                                        }
                                    }
                                    TextButton(onClick = {
                                        try { routesStore?.update(route.id, routeTitle, routeSport); routesVersion++;edit = false }
                                        catch (_: Exception) { error = "La ruta necesita un nombre y almacenamiento disponible." }
                                    }) { Text("Guardar ruta") }
                                }
                            }
                        }
                    }
                }
            }
            Button(onClick={
                if (hasActiveWorkout) onOpenWorkout()
                else if(state.sport.usesGPS && ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_FINE_LOCATION)!=PackageManager.PERMISSION_GRANTED)
                    permissions.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION))
                else start()
            },modifier=Modifier.testTag("live_start")) {Text(if (hasActiveWorkout) "Continuar entrenamiento" else "Empezar actividad")}
            TextButton(onClick=onOpenTools) {Text("Crear entrenamiento")}
            onOpenCenter?.let {TextButton(onClick=it) {Text("Center")}}
        } else {
            Text(LiveSportHistory.formatDuration(state.durationSeconds(System.currentTimeMillis())),style=MaterialTheme.typography.displayMedium)
            if(state.sport.usesGPS) {
                Text("%.2f km".format(state.distanceMeters/1000),style=MaterialTheme.typography.headlineSmall)
                val now = System.currentTimeMillis()
                if (state.sport.displaysSpeed) {
                    state.averageSpeedKmh(now)?.let { Text("%.1f km/h de media".format(it)) }
                    state.currentSpeedMps?.let { Text("%.1f km/h".format(it * 3.6)) }
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
                        "%.1f km/h".format(state.activeKilometerMeters / split * 3.6)
                    else "${LiveSportHistory.formatDuration(split * 1000 / state.activeKilometerMeters)} min/km"
                    Text("Km ${state.activeKilometer} · $current")
                }
                if(state.points.size>=2) RouteMapView(state.points,isInteractive=false,modifier=Modifier.fillMaxWidth().height(220.dp))
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
            if(state.phase!=LiveActivityState.Phase.REVIEW) Button(onClick={runtime.finish();LiveActivityService.stop(context)},modifier=Modifier.testTag("live_finish")) {Text("Finalizar")}
            else {
                previewHealth?.let { sample ->
                    val heart = sample.averageHeartRateBpm?.takeIf { it.isFinite() && it > 0 }
                    val energy = sample.activeEnergyKcal?.takeIf { it.isFinite() && it > 0 }
                    if (heart != null || energy != null) {
                        Text("Health Connect · datos medidos", style = MaterialTheme.typography.titleMedium)
                        heart?.let { Text("Pulso medio: %.0f lpm".format(it)) }
                        energy?.let { Text("Energía activa: %.0f kcal".format(it)) }
                    }
                }
                OutlinedTextField(title,{title=it},label={Text("Nombre de la actividad")},modifier=Modifier.fillMaxWidth())
                OutlinedTextField(notes,{notes=it},label={Text("Notas")},modifier=Modifier.fillMaxWidth())
                Button(onClick={
                    try {
                        val now=System.currentTimeMillis()
                        WorkoutRepository(context,accountId).saveLiveActivity(state.snapshot(now)!!,
                            state.finishedMillis ?: now,state.durationSeconds(now),title,notes)
                        if (runtime.discard()) { LiveActivityService.stop(context);onSaved() }
                        else error="La actividad se guardó, pero no se pudo limpiar el punto de recuperación."
                    } catch (_: Exception) {error="No se pudo guardar. La actividad sigue disponible para reintentar."}
                },modifier=Modifier.testTag("live_save")) {Text("Guardar actividad")}
            }
            TextButton(onClick={confirmDiscard=true}) {Text("Descartar")}
            LiveKilometerSplitsSection(state.splitsSeconds, state.sport.displaysSpeed)
        }
        (error ?: runtime.lastError)?.let {Text(it,color=MaterialTheme.colorScheme.error)}
    }
}
