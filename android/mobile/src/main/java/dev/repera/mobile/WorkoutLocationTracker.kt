package dev.repera.mobile

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Looper
import androidx.core.content.ContextCompat
import dev.repera.domain.WorkoutLocationLogic
import dev.repera.domain.WorkoutLocationPin
import dev.repera.domain.WorkoutRoutePoint
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

/**
 * Captura pin al empezar y, si el entreno parece outdoor, una ruta GPS
 * downsampleada. Port 1:1 de WorkoutLocationTracker.swift (iOS) sobre
 * LocationManager (sin dependencia nueva de Google Play Services).
 *
 * El permiso lo pide la UI (la Activity registra el launcher); el tracker
 * solo consulta estado, como en iOS donde requestWhenInUse lo dispara el paso
 * de onboarding / el Play.
 */
class WorkoutLocationTracker(private val context: Context) {

    private val manager: LocationManager?
        get() = context.getSystemService(LocationManager::class.java)

    var lastErrorMessage: String? = null
        private set

    val isAuthorized: Boolean
        get() = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED

    private val routeBuffer = mutableListOf<WorkoutRoutePoint>()
    private var trackingSessionID: String? = null
    private var lastAccepted: Location? = null
    private var pointCounter = 0

    private var pinContinuation: ((WorkoutLocationPin?) -> Unit)? = null

    private val listener = LocationListener { location -> onLocation(location) }

    /** Heurística outdoor (delegación en la lógica de dominio, paridad iOS). */
    fun shouldTrackRoute(title: String, exerciseNames: List<String>): Boolean =
        WorkoutLocationLogic.shouldTrackRoute(title, exerciseNames)

    /** Pin de inicio con timeout suave de 4s: sin fix no bloqueamos el Play
     *  (misma política que iOS). Null si no autorizado o sin fix a tiempo. */
    suspend fun capturePin(): WorkoutLocationPin? {
        if (!isAuthorized) return null
        val mgr = manager ?: return null
        return withTimeoutOrNull(4_000) {
            suspendCancellableCoroutine { cont ->
                var resumed = false
                lateinit var pinListener: LocationListener
                val finish: (WorkoutLocationPin?) -> Unit = { pin ->
                    if (!resumed) {
                        resumed = true
                        pinContinuation = null
                        runCatching { mgr.removeUpdates(pinListener) }
                        if (cont.isActive) cont.resume(pin)
                    }
                }
                pinListener = LocationListener { location ->
                    val age = System.currentTimeMillis() - location.time
                    finish(if (age in 0..15_000 && location.hasAccuracy()) location.toPin() else null)
                }
                pinContinuation = finish
                try {
                    mgr.requestSingleUpdate(LocationManager.FUSED_PROVIDER,pinListener,Looper.getMainLooper())
                } catch (error: SecurityException) {
                    lastErrorMessage = error.localizedMessage;finish(null)
                } catch (error: IllegalArgumentException) {
                    lastErrorMessage = "Proveedor GPS no disponible";finish(null)
                }
                cont.invokeOnCancellation { finish(null) }
            }
        }
    }

    fun startRouteTracking(sessionID: String) {
        if (!isAuthorized) return
        stopRouteTracking()
        trackingSessionID = sessionID
        routeBuffer.clear()
        pointCounter = 0
        lastAccepted = null
        try {
            manager?.requestLocationUpdates(
                LocationManager.FUSED_PROVIDER,
                /* minTimeMs = */ 1_000L,
                WorkoutLocationLogic.MIN_DISTANCE_METERS,
                listener,
                Looper.getMainLooper()
            )
        } catch (error: SecurityException) {
            lastErrorMessage = error.localizedMessage
            trackingSessionID = null
        }
    }

    /** Detiene la captura y devuelve la ruta downsampleada (máx. 400 puntos). */
    fun stopRouteTracking(): List<WorkoutRoutePoint> {
        manager?.removeUpdates(listener)
        trackingSessionID = null
        pinContinuation?.invoke(null)
        pinContinuation = null
        val points = WorkoutLocationLogic.downsample(routeBuffer.toList())
        routeBuffer.clear()
        lastAccepted = null
        return points
    }

    private fun onLocation(location: Location) {
        pinContinuation?.let { finish ->
            pinContinuation = null
            finish(location.toPin())
        }
        if (trackingSessionID == null) return
        val last = lastAccepted
        if (last != null && location.distanceTo(last) < WorkoutLocationLogic.MIN_DISTANCE_METERS) {
            return
        }
        lastAccepted = location
        routeBuffer += WorkoutRoutePoint(
            id = pointCounter,
            latitude = location.latitude,
            longitude = location.longitude,
            recordedAtEpochMs = location.time,
            speedMps = if (location.hasSpeed() && location.speed >= 0) location.speed.toDouble() else null,
            // Misma regla que iOS: altitud solo con precisión vertical 0-50 m.
            altitudeMeters = if (location.hasVerticalAccuracy() &&
                location.verticalAccuracyMeters in 0f..50f
            ) location.altitude else null,
            horizontalAccuracyMeters = if (location.hasAccuracy()) location.accuracy.toDouble() else null,
            verticalAccuracyMeters = if (location.hasVerticalAccuracy()) location.verticalAccuracyMeters.toDouble() else null
        )
        pointCounter += 1
    }

    private fun Location.toPin() = WorkoutLocationPin(
        latitude = latitude,
        longitude = longitude,
        recordedAtEpochMs = time
    )
}
