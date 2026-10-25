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
    onOpenTools: () -> Unit, onOpenCenter: (() -> Unit)? = null) {
    val context=LocalContext.current
    if(accountId.isBlank()) { Text("Inicia sesión para guardar actividades.");return }
    val runtime=remember(accountId) { LiveActivityRuntime.forAccount(context,accountId) }
    val revision by runtime.updates.collectAsState()
    val state=runtime.state
    var title by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var confirmDiscard by remember { mutableStateOf(false) }
    fun startService() {
        try { LiveActivityService.startFromVisibleUI(context,accountId) }
        catch (_: Exception) { runtime.pause();error="No se pudo mantener el registro en segundo plano. La actividad queda en pausa." }
    }
    fun start() { runtime.start();startService() }
    val permissions=rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { start() }
    LaunchedEffect(runtime) {
        while(true) { delay(1000);runtime.publish() }
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
            LiveSport.groups.forEach { group ->
                Text(group,style=MaterialTheme.typography.titleSmall)
                FlowRow(horizontalArrangement=Arrangement.spacedBy(6.dp)) {
                    LiveSport.entries.filter { it.group==group }.forEach { sport ->
                        FilterChip(selected=state.sport==sport,onClick={runtime.choose(sport)},label={Text(sport.title)})
                    }
                }
            }
            Text(state.sport.metricDescription)
            Button(onClick={
                if(state.sport.usesGPS && ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_FINE_LOCATION)!=PackageManager.PERMISSION_GRANTED)
                    permissions.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION))
                else start()
            },modifier=Modifier.testTag("live_start")) {Text("Empezar actividad")}
            TextButton(onClick=onOpenTools) {Text("Crear entrenamiento")}
            onOpenCenter?.let {TextButton(onClick=it) {Text("Center")}}
        } else {
            Text(LiveSportHistory.formatDuration(state.durationSeconds(System.currentTimeMillis())),style=MaterialTheme.typography.displayMedium)
            if(state.sport.usesGPS) {
                Text("%.2f km".format(state.distanceMeters/1000),style=MaterialTheme.typography.headlineSmall)
                state.averageSpeedKmh(System.currentTimeMillis())?.let {Text("%.1f km/h de media".format(it))}
                if(state.points.size>=2) RouteMapView(state.points,isInteractive=false,modifier=Modifier.fillMaxWidth().height(220.dp))
            }
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
            LiveKilometerSplitsSection(state.splitsSeconds)
        }
        (error ?: runtime.lastError)?.let {Text(it,color=MaterialTheme.colorScheme.error)}
    }
}
