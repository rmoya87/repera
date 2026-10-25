package dev.repera.mobile

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Looper
import androidx.core.content.ContextCompat
import dev.repera.domain.LiveGPSOdometer
import dev.repera.domain.LiveSport
import dev.repera.domain.WorkoutRoutePoint

/** Proveedor de muestras del recorder En vivo. No solicita permisos, no
 * escribe Salud y no arranca en el constructor. El FGS será su dueño. */
internal class LiveLocationSource(private val context: Context,
    private val onUpdate: (LiveGPSOdometer.Update) -> Unit) {
    private val manager get() = context.getSystemService(LocationManager::class.java)
    private val odometer = LiveGPSOdometer()
    var lastError: String? = null; private set
    private val listener = LocationListener { location -> accept(location) }
    val isAuthorized get() = ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    fun start(sessionID: String, sport: LiveSport, points: List<WorkoutRoutePoint>, meters: Double): Boolean {
        if (!isAuthorized) { lastError="GPS no autorizado. Seguimos registrando el tiempo.";return false }
        val mgr=manager ?: run { lastError="GPS no disponible. Seguimos registrando el tiempo.";return false }
        if (!odometer.start(sessionID,System.currentTimeMillis(),sport,points,meters)) {
            lastError="Otro entrenamiento ya está utilizando el GPS.";return false
        }
        try {
            val enabled = mgr.getProviders(true)
            val provider = listOf(LocationManager.FUSED_PROVIDER,LocationManager.GPS_PROVIDER,LocationManager.NETWORK_PROVIDER)
                .firstOrNull { it in enabled } ?: error("Sin proveedor de ubicación activo")
            mgr.requestLocationUpdates(provider,1000L,if (sport.isCycling) 5f else 3f,listener,Looper.getMainLooper())
            lastError=null;return true
        } catch (e: SecurityException) {
            odometer.stop(sessionID,false);lastError="GPS no autorizado. Seguimos registrando el tiempo.";return false
        } catch (e: IllegalStateException) {
            odometer.stop(sessionID,false);lastError="Activa la ubicación para registrar el recorrido. Seguimos registrando el tiempo.";return false
        } catch (e: IllegalArgumentException) {
            odometer.stop(sessionID,false);lastError="Proveedor GPS no disponible. Seguimos registrando el tiempo.";return false
        }
    }
    fun stop(sessionID: String, clear: Boolean = true) {
        if (odometer.ownerSessionID != sessionID) return
        manager?.removeUpdates(listener);odometer.stop(sessionID,clear)
    }
    internal var receivedFixCount = 0; private set
    internal var lastFixAgeMillis: Long? = null; private set
    private fun accept(location: Location) {
        receivedFixCount++
        lastFixAgeMillis = System.currentTimeMillis()-location.time
        if (!location.hasAccuracy()) return
        val fix=LiveGPSOdometer.Fix(location.latitude,location.longitude,location.time,
            location.accuracy.toDouble(),
            if (location.hasVerticalAccuracy()) location.verticalAccuracyMeters.toDouble() else null,
            if (location.hasAltitude()) location.altitude else null,
            if (location.hasSpeed()) location.speed.toDouble() else null)
        odometer.accept(fix,System.currentTimeMillis())?.let(onUpdate)
    }
}
