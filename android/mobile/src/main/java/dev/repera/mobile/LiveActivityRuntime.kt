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
    var lastError: String? = null; private set
    private val revisions = MutableStateFlow(0L)
    val updates = revisions.asStateFlow()
    private val location = LiveLocationSource(app) { update ->
        if (state.receive(update.sessionID,update.point,update.distanceMeters)) {
            checkpoint();publish()
        }
    }
    init {
        try { store.read()?.let { state.restore(it) } }
        catch (_: Exception) { lastError="No se pudo restaurar la actividad. El archivo original se conserva." }
    }
    fun choose(sport: LiveSport) { state.choose(sport);publish() }
    fun selectRoute(id: String?) { state.selectRoute(id);publish() }
    fun start() {
        if (state.phase != LiveActivityState.Phase.IDLE) return
        state.start(System.currentTimeMillis(),UUID.randomUUID().toString());startGPS();checkpoint(true);publish()
    }
    fun pause() {
        if (state.phase != LiveActivityState.Phase.RECORDING) return
        state.pause(System.currentTimeMillis());location.stop(state.gpsSessionID,false);checkpoint(true);publish()
    }
    fun resume() {
        if (state.phase != LiveActivityState.Phase.PAUSED) return
        state.resume(System.currentTimeMillis());startGPS();checkpoint(true);publish()
    }
    fun finish() {
        state.finish(System.currentTimeMillis());location.stop(state.gpsSessionID);checkpoint(true);publish()
    }
    fun discard(): Boolean {
        // Primero retirar el checkpoint. Si falla no afirmar descarte ni
        // perder la actividad que sigue recuperable en disco.
        try { store.clear() } catch (_: Exception) {
            lastError="No se pudo descartar la actividad guardada.";publish();return false
        }
        location.stop(state.gpsSessionID);state.discard();lastError=null;publish();return true
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
            current?.stopForAccountChange()
            return LiveActivityRuntime(context,accountID).also { current=it }
        }
        @Synchronized fun stopAll() { current?.stopForAccountChange();current=null }
    }
}
