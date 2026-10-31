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
    private var lastWearPublishMillis = 0L
    private var lastWearPhase: LiveActivityState.Phase? = null
    private val voice = LiveSpokenGuidance(app)
    private val voicePrefs = app.getSharedPreferences("repera.live.guidance", Context.MODE_PRIVATE)
    var spokenGuidanceEnabled = voicePrefs.getBoolean("enabled", true); private set
    var upcomingTurn: String? = null; private set
    var upcomingCue: dev.repera.domain.LiveRouteGuidance.Cue? = null; private set
    var latestKilometerReport: String? = null; private set
    /** Condiciones Open-Meteo (marea/nieve) para Wear + Guardar. */
    var liveConditions: dev.repera.domain.ActivityConditionsSnapshot? = null; private set
    private var lastConditionsFetchMillis = 0L
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
        upcomingCue = null
    }
    var recoveryBlocked: Boolean = false; private set
    var lastError: String? = null; private set
    private val revisions = MutableStateFlow(0L)
    val updates = revisions.asStateFlow()
    private val location = LiveLocationSource(app) { update ->
        val splitCount = state.splitsSeconds.size
        if (state.receive(update.sessionID,update.point,update.distanceMeters,update.bridgedPoints,update.bridgedDistanceMeters)) {
            if (state.splitsSeconds.size > splitCount) {
                val km = state.splitsSeconds.size
                val seconds = state.splitsSeconds.last()
                val cumulative = state.durationSeconds(System.currentTimeMillis())
                val speed = dev.repera.domain.ReperaNumberFormat.decimal(3600 / seconds)
                val average = if (cumulative > 0) dev.repera.domain.ReperaNumberFormat.decimal(km * 3600.0 / cumulative) else "—"
                latestKilometerReport = "Km $km · " +
                    dev.repera.domain.LiveSportHistory.formatDuration(seconds) +
                    " · $speed km/h · Media $average km/h"
                // Apple (live main): el kilómetro se encola aunque suene un giro y NUNCA se sustituye por una notificación.
                if (spokenGuidanceEnabled) {
                    val elapsed = state.durationSeconds(System.currentTimeMillis())
                    val phrase = dev.repera.domain.KilometerVoiceAnnouncement.message(
                        km, seconds, elapsed)
                        ?: dev.repera.domain.LiveSpokenPhrases.kilometer(
                            km, seconds, state.sport.displaysSpeed)
                    voice.speak(phrase, queue = true)
                }
                // El bloqueo muestra el resultado aunque haya música/voz;
                // esta notificación es silenciosa y depende del permiso del sistema.
                notifyGuidance("Kilómetro $km completado", latestKilometerReport.orEmpty(), km)
            }
            guidance?.update(update.point)?.let { cue ->
                upcomingTurn = cue.display
                upcomingCue = cue
                cue.speech?.let {
                    if (spokenGuidanceEnabled) {
                        val delivered = voice.speak(it, queue = true)
                        if (!delivered) notifyGuidance("Giro orientativo del GPX", cue.display)
                    } else notifyGuidance("Giro orientativo del GPX", cue.display)
                }
            }
            checkpoint();publish()
        }
    }
    init {
        LiveSport.byId(voicePrefs.getString("lastSport", "running").orEmpty())?.let { state.choose(it) }
        try { store.read()?.let { state.restore(it,System.currentTimeMillis());prepareRoute() } }
        catch (_: Exception) { recoveryBlocked=true;lastError="No se pudo restaurar la actividad. El archivo original se conserva. Descártalo explícitamente antes de iniciar otro." }
    }
    private fun notifyGuidance(title: String, text: String, kilometer: Int? = null) {
        // Solo alternativa en segundo plano y si se concedió notificación;
        // con pantalla activa el texto de la UI ya es la alternativa visual.
        val importance = android.app.ActivityManager.RunningAppProcessInfo()
        android.app.ActivityManager.getMyMemoryState(importance)
        if (importance.importance <= android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) return
        if (android.os.Build.VERSION.SDK_INT >= 33 &&
            androidx.core.content.ContextCompat.checkSelfPermission(app, android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) return
        val manager = app.getSystemService(android.app.NotificationManager::class.java)
        val channel = android.app.NotificationChannel(
            "repera.live.guidance.silent.v2", "Parciales de entrenamiento",
            android.app.NotificationManager.IMPORTANCE_DEFAULT)
        channel.setSound(null, null)
        manager.createNotificationChannel(channel)
        val notification = androidx.core.app.NotificationCompat.Builder(app, channel.id)
            .setSmallIcon(R.drawable.ic_timer).setContentTitle(title).setContentText(text)
            .setAutoCancel(true).build()
        runCatching { manager.notify(kilometer?.let { 5000 + it } ?: 4204, notification) }
    }
    fun choose(sport: LiveSport) {
        if (state.phase != LiveActivityState.Phase.IDLE) return
        state.choose(sport);voicePrefs.edit().putString("lastSport",sport.id).apply();publish()
    }
    fun selectRoute(id: String?) { state.selectRoute(id);prepareRoute();publish() }
    /** Letrero de navegacion antes de Iniciar con la ultima posicion capturada
     * (paridad banner idle Apple): no consume avisos hablados ni arranca GPS. */
    fun previewGuidance(point: dev.repera.domain.WorkoutRoutePoint) {
        if (state.phase != LiveActivityState.Phase.IDLE) return
        guidance?.update(point, announce = false)?.let { cue ->
            upcomingTurn = cue.display
            upcomingCue = cue
            publish()
        }
    }
    fun start() {
        if (recoveryBlocked || state.phase != LiveActivityState.Phase.IDLE) return
        latestKilometerReport=null
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
    fun updateLiveConditions(snap: dev.repera.domain.ActivityConditionsSnapshot?) {
        liveConditions = snap
        lastConditionsFetchMillis = System.currentTimeMillis()
        lastWearPublishMillis = 0L
        publish()
    }
    /** True si toca refrescar Open-Meteo (~12 min, o forzado / sin snapshot). */
    fun shouldRefreshConditions(force: Boolean): Boolean {
        val family = dev.repera.domain.ActivityConditionsSnapshot.familyForLiveSportId(state.sport.id)
        if (family == dev.repera.domain.ActivityConditionsFamily.NONE) return false
        if (force || liveConditions == null) return true
        return System.currentTimeMillis() - lastConditionsFetchMillis >= 12 * 60_000L
    }
    fun discard(): Boolean {
        // Primero retirar el checkpoint. Si falla no afirmar descarte ni
        // perder la actividad que sigue recuperable en disco.
        try { store.clear() } catch (_: Exception) {
            lastError="No se pudo descartar la actividad guardada.";publish();return false
        }
        voice.stop();location.stop(state.gpsSessionID);state.discard();recoveryBlocked=false;guidance=null;upcomingTurn=null;upcomingCue=null;latestKilometerReport=null;liveConditions=null;lastConditionsFetchMillis=0L;lastError=null;publish();return true
    }
    fun checkpoint(force: Boolean = false) {
        val now=System.currentTimeMillis()
        if (!force && now-lastSaveMillis<10_000) return
        val snapshot=state.snapshot(now) ?: return
        try { store.write(snapshot);lastSaveMillis=now }
        catch (_: Exception) { lastError="No se pudo guardar el punto de recuperación. Comprueba el almacenamiento." }
    }
    private fun startGPS(bridgingInterruption: Boolean = false) {
        if (!state.sport.usesGPS) return
        location.start(state.gpsSessionID,state.sport,state.points,state.distanceMeters,
            bridgingInterruption,state.sport.recoveryMaximumSpeedMps)
        lastError=location.lastError
    }

    /** Tras relanzar el proceso, restaurar el sensor sin pulsar Iniciar.
     *  (resumeInterruptedRecordingIfNeeded Apple, ca3c0383) */
    fun resumeInterruptedRecordingIfNeeded() {
        if (!state.needsInterruptedGPSRecovery || state.phase != LiveActivityState.Phase.RECORDING) return
        state.clearInterruptedRecovery()
        startGPS(bridgingInterruption = true);checkpoint(true);publish()
    }
    fun stopForAccountChange() {
        if (state.phase == LiveActivityState.Phase.RECORDING) pause()
        location.stop(state.gpsSessionID,false);checkpoint(true)
    }
    fun publish() {
        revisions.value += 1
        val now = System.currentTimeMillis()
        if (state.phase != lastWearPhase || now - lastWearPublishMillis >= 5_000) {
            lastWearPhase = state.phase
            lastWearPublishMillis = now
            WearActiveSessionBridge.publishLive(app, this)
        }
    }
    companion object {
        private var current: LiveActivityRuntime? = null
        @Synchronized fun forAccount(context: Context, accountID: String): LiveActivityRuntime {
            require(accountID.isNotBlank())
            current?.takeIf { it.accountID==accountID }?.let { return it }
            current?.stopForAccountChange();current?.voice?.close()
            return LiveActivityRuntime(context,accountID).also { current=it }
        }
        @Synchronized fun hasPendingActivity(context: Context, accountID: String): Boolean {
            current?.takeIf { it.accountID == accountID }?.let { return it.recoveryBlocked || it.state.phase != LiveActivityState.Phase.IDLE }
            val folder = File(context.filesDir,"users/" + MessageDigest.getInstance("SHA-256")
                .digest(accountID.toByteArray()).joinToString("") { "%02x".format(it) })
            // Sin crear TTS/proveedor ni cambiar la cuenta activa desde IO.
            return try { LiveActivitySnapshotStore(File(folder,"live_activity.json")).read() != null }
                catch (_: Exception) { true } // checkpoint dañado: no pisarlo con otro entreno.
        }
        @Synchronized fun stopAll() { current?.stopForAccountChange();current?.voice?.close();current=null }
        /** Apple f6f13169: checkpoint durable forzado al suspenderse la app;
         *  nunca perder los ultimos fixes por el throttling de 10s. */
        @Synchronized fun checkpointForBackground() { current?.checkpoint(true) }
    }
}
