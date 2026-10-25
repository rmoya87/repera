package dev.repera.mobile

import android.content.Context
import dev.repera.domain.LiveActivityState
import dev.repera.domain.LiveSport
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.File
import java.security.MessageDigest
import java.util.UUID

/** Dueño de una actividad por cuenta: pantalla y FGS comparten esta instancia.
 * Restaurar no inicia sensores. Cambiar cuenta detiene el proveedor anterior.
 * No escribe Salud ni publica actividad fuera del dispositivo. */
internal class LiveActivityRuntime private constructor(context: Context, val accountID: String) {
    private val app = context.applicationContext
    val state = LiveActivityState()
    private val folder = File(app.filesDir,"users/" + MessageDigest.getInstance("SHA-256")
        .digest(accountID.toByteArray()).joinToString("") { "%02x".format(it) })
    private val store = LiveActivitySnapshotStore(File(folder,"live_activity.json"))
    private var lastSaveMillis = 0L
    private val voice = LiveSpokenGuidance(app)
    private val voicePrefs = app.getSharedPreferences("repera.live.guidance", Context.MODE_PRIVATE)
    var spokenGuidanceEnabled = voicePrefs.getBoolean("enabled", true); private set
    var upcomingTurn: String? = null; private set
    var latestKilometerReport: String? = null; private set
    private var guidance: dev.repera.domain.LiveRouteGuidance? = null
    fun toggleSpokenGuidance() {
        spokenGuidanceEnabled = !spokenGuidanceEnabled
        voicePrefs.edit().putBoolean("enabled", spokenGuidanceEnabled).apply()
        if (!spokenGuidanceEnabled) voice.stop()
        publish()
    }
    private fun prepareRoute() {
        val route = state.selectedRouteID?.let { id ->
            runCatching { LiveRoutesStore(app, accountID).routes.firstOrNull { it.id == id } }.getOrNull()
        }
        guidance = route?.let { dev.repera.domain.LiveRouteGuidance(it.points, state.sport) }
        upcomingTurn = null
    }
    var lastError: String? = null; private set
    private val revisions = MutableStateFlow(0L)
    val updates = revisions.asStateFlow()
    private val location = LiveLocationSource(app) { update ->
        val splitCount = state.splitsSeconds.size
        if (state.receive(update.sessionID,update.point,update.distanceMeters)) {
            if (state.splitsSeconds.size > splitCount) {
                val km = state.splitsSeconds.size
                val seconds = state.splitsSeconds.last()
                latestKilometerReport = "Km $km · " + if (state.sport.displaysSpeed)
                    "%.1f km/h".format(3600 / seconds) else
                    dev.repera.domain.LiveSportHistory.formatDuration(seconds) + " min/km"
                val spoken = spokenGuidanceEnabled && voice.speak("Has completado el kilómetro $km. " +
                    if (state.sport.displaysSpeed) "Tu velocidad media ha sido de %.1f kilómetros por hora.".format(3600 / seconds)
                    else "Lo has hecho en ${seconds.toInt() / 60} minutos y ${seconds.toInt() % 60} segundos.")
                if (!spoken) notifyGuidance("Kilómetro $km completado", latestKilometerReport.orEmpty())
            }
            guidance?.update(update.point)?.let { cue ->
                upcomingTurn = cue.display
                cue.speech?.let {
                    val spoken = spokenGuidanceEnabled && voice.speak(it)
                    if (!spoken) notifyGuidance("Giro orientativo del GPX", cue.display)
                }
            }
            checkpoint();publish()
        }
    }
    init {
        try { store.read()?.let { state.restore(it);prepareRoute() } }
        catch (_: Exception) { lastError="No se pudo restaurar la actividad. El archivo original se conserva." }
    }
    private fun notifyGuidance(title: String, text: String) {
        // Solo alternativa en segundo plano y si se concedió notificación;
        // con pantalla activa el texto de la UI ya es la alternativa visual.
        val importance = android.app.ActivityManager.RunningAppProcessInfo()
        android.app.ActivityManager.getMyMemoryState(importance)
        if (importance.importance <= android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) return
        if (android.os.Build.VERSION.SDK_INT >= 33 &&
            androidx.core.content.ContextCompat.checkSelfPermission(app, android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) return
        val manager = app.getSystemService(android.app.NotificationManager::class.java)
        manager.createNotificationChannel(android.app.NotificationChannel("repera.live.guidance", "Guía deportiva", android.app.NotificationManager.IMPORTANCE_DEFAULT))
        val notification = androidx.core.app.NotificationCompat.Builder(app, "repera.live.guidance")
            .setSmallIcon(R.drawable.ic_timer).setContentTitle(title).setContentText(text)
            .setAutoCancel(true).build()
        runCatching { manager.notify(4204, notification) }
    }
    fun choose(sport: LiveSport) { state.choose(sport);publish() }
    fun selectRoute(id: String?) { state.selectRoute(id);prepareRoute();publish() }
    fun start() {
        if (state.phase != LiveActivityState.Phase.IDLE) return
        state.start(System.currentTimeMillis(),UUID.randomUUID().toString());prepareRoute();startGPS();checkpoint(true);publish()
    }
    fun pause() {
        if (state.phase != LiveActivityState.Phase.RECORDING) return
        state.pause(System.currentTimeMillis());voice.stop();location.stop(state.gpsSessionID,false);checkpoint(true);publish()
    }
    fun resume() {
        if (state.phase != LiveActivityState.Phase.PAUSED) return
        state.resume(System.currentTimeMillis());startGPS();checkpoint(true);publish()
    }
    fun finish() {
        state.finish(System.currentTimeMillis());voice.stop();location.stop(state.gpsSessionID);checkpoint(true);publish()
    }
    fun discard(): Boolean {
        // Primero retirar el checkpoint. Si falla no afirmar descarte ni
        // perder la actividad que sigue recuperable en disco.
        try { store.clear() } catch (_: Exception) {
            lastError="No se pudo descartar la actividad guardada.";publish();return false
        }
        voice.stop();location.stop(state.gpsSessionID);state.discard();guidance=null;upcomingTurn=null;latestKilometerReport=null;lastError=null;publish();return true
    }
    fun checkpoint(force: Boolean = false) {
        val now=System.currentTimeMillis()
        if (!force && now-lastSaveMillis<10_000) return
        val snapshot=state.snapshot(now) ?: return
        try { store.write(snapshot);lastSaveMillis=now }
        catch (_: Exception) { lastError="No se pudo guardar el punto de recuperación. Comprueba el almacenamiento." }
    }
    private fun startGPS() {
        if (!state.sport.usesGPS) return
        location.start(state.gpsSessionID,state.sport,state.points,state.distanceMeters)
        lastError=location.lastError
    }
    fun stopForAccountChange() {
        if (state.phase == LiveActivityState.Phase.RECORDING) pause()
        location.stop(state.gpsSessionID,false);checkpoint(true)
    }
    fun publish() { revisions.value += 1 }
    companion object {
        private var current: LiveActivityRuntime? = null
        @Synchronized fun forAccount(context: Context, accountID: String): LiveActivityRuntime {
            require(accountID.isNotBlank())
            current?.takeIf { it.accountID==accountID }?.let { return it }
            current?.stopForAccountChange();current?.voice?.close()
            return LiveActivityRuntime(context,accountID).also { current=it }
        }
        @Synchronized fun stopAll() { current?.stopForAccountChange();current?.voice?.close();current=null }
    }
}
