package dev.repera.wear

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * Seguimiento GPS continuo en Comenzar outdoor watch-owned (paridad
 * WatchSessionHub + HKWorkoutRoute). No se usa en indoor ni companion
 * (el teléfono es dueño del GPS).
 */
internal class WearRouteTracker(private val context: Context) {
    private val manager = context.getSystemService(LocationManager::class.java)
    private val points = mutableListOf<JSONObject>()
    private var listening = false
    private var last: Location? = null

    private val listener = object : LocationListener {
        override fun onLocationChanged(location: Location) = accept(location)
        @Deprecated("Deprecated in Java")
        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit
        override fun onProviderEnabled(provider: String) = Unit
        override fun onProviderDisabled(provider: String) = Unit
    }

    fun start() {
        if (listening) return
        if (!hasPermission()) return
        val provider = preferredProvider() ?: return
        listening = true
        runCatching {
            manager?.requestLocationUpdates(
                provider, 2_000L, 5f, listener, Looper.getMainLooper()
            )
        }.onFailure { listening = false }
    }

    fun stop(): List<JSONObject> {
        if (listening) {
            runCatching { manager?.removeUpdates(listener) }
            listening = false
        }
        val copy = points.toList()
        points.clear()
        last = null
        return copy
    }

    fun snapshot(): JSONArray = JSONArray(points)

    private fun accept(location: Location) {
        if (!location.hasAccuracy() || location.accuracy !in 0f..<50f) return
        if (location.latitude !in -90.0..90.0 || location.longitude !in -180.0..180.0) return
        val previous = last
        if (previous != null) {
            val delta = location.distanceTo(previous)
            if (delta <= 0f || delta >= 80f) return
        }
        last = location
        val point = JSONObject()
            .put("latitude", location.latitude)
            .put("longitude", location.longitude)
            .put("recordedAtEpochMs", location.time.takeIf { it > 0 } ?: System.currentTimeMillis())
            .put("horizontalAccuracyMeters", location.accuracy.toDouble())
        if (location.hasAltitude()) point.put("altitudeMeters", location.altitude)
        if (location.hasSpeed() && location.speed >= 0f) {
            point.put("speedMps", location.speed.toDouble())
        }
        points.add(point)
        if (points.size > 4_000) points.removeAt(0)
    }

    companion object {
        /** Metres from verified GPS fixes, not a route title or time estimate.
         * Skip gaps caused by pause, missing accuracy and GPS teleportation.
         * Only used when native Health Services did not yield distance. */
        fun measuredDistanceMeters(routePoints: JSONArray): Double {
            var last: JSONObject? = null
            var total = 0.0
            val buffer = FloatArray(1)
            for (index in 0 until routePoints.length()) {
                val point = routePoints.optJSONObject(index) ?: continue
                val lat = point.optDouble("latitude", Double.NaN)
                val lon = point.optDouble("longitude", Double.NaN)
                val accuracy = point.optDouble("horizontalAccuracyMeters", Double.NaN)
                val timestamp = point.optLong("recordedAtEpochMs", 0L)
                if (!lat.isFinite() || lat !in -90.0..90.0 ||
                    !lon.isFinite() || lon !in -180.0..180.0 ||
                    !accuracy.isFinite() || accuracy !in 0.0..50.0 ||
                    timestamp <= 0L) continue
                val prev = last
                if (prev != null) {
                    val deltaMs = timestamp - prev.optLong("recordedAtEpochMs")
                    if (deltaMs in 0L..90_000L) {
                        Location.distanceBetween(
                            prev.getDouble("latitude"), prev.getDouble("longitude"),
                            lat, lon, buffer
                        )
                        val meters = buffer[0].toDouble()
                        if (meters.isFinite() && meters in 0.0..80.0) total += meters
                    }
                }
                last = point
            }
            return total
        }
    }

    private fun hasPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private fun preferredProvider(): String? {
        val mgr = manager ?: return null
        return listOf(
            LocationManager.FUSED_PROVIDER,
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER
        ).firstOrNull { runCatching { mgr.isProviderEnabled(it) }.getOrDefault(false) }
    }
}
