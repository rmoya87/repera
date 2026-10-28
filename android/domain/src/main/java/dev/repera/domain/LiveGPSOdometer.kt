package dev.repera.domain

import kotlin.math.max
import kotlin.math.min

/** Validador único del GPS, port accept(WorkoutGPSFix) Apple 5890215d.
 * Pausas, saltos y huecos abren segmento sin fabricar metros intermedios. */
class LiveGPSOdometer {
    data class Fix(val latitude: Double, val longitude: Double, val timestampMillis: Long,
        val accuracy: Double, val verticalAccuracy: Double? = null, val altitude: Double? = null,
        val speedMps: Double? = null)
    data class Update(val sessionID: String, val point: WorkoutRoutePoint, val distanceMeters: Double,
        /** Inferencia solo para recuperación de cierres inesperados (ca3c0383). */
        val bridgedPoints: List<WorkoutRoutePoint> = emptyList(),
        val bridgedDistanceMeters: Double = 0.0)
    var ownerSessionID: String? = null; private set
    var distanceMeters = 0.0; private set
    var points: List<WorkoutRoutePoint> = emptyList(); private set
    private var segmentStartMillis: Long? = null
    private var previous: Fix? = null
    private var speedLimit = 12.0
    private var interruptedAnchor: WorkoutRoutePoint? = null
    private var recoveryMaximumSpeedMps = 2.8

    fun start(sessionID: String, nowMillis: Long, sport: LiveSport,
        existingPoints: List<WorkoutRoutePoint> = emptyList(), existingDistanceMeters: Double = 0.0,
        bridgeInterruptedGap: Boolean = false, recoveryMaximumSpeedMps: Double = 2.8): Boolean {
        if (ownerSessionID != null && ownerSessionID != sessionID) return false
        ownerSessionID = sessionID; speedLimit = max(1.0,sport.maxGPSMetersPerSecond)
        if (segmentStartMillis == null) {
            points = existingPoints.toList(); distanceMeters = max(0.0,existingDistanceMeters)
            // Exclusivo para cierres imprevistos, nunca al pausar manualmente.
            interruptedAnchor = if (bridgeInterruptedGap) points.lastOrNull() else null
            this.recoveryMaximumSpeedMps = recoveryMaximumSpeedMps
            previous = null; segmentStartMillis = nowMillis
        }
        return true
    }
    fun stop(sessionID: String, clear: Boolean = true): Boolean {
        if (ownerSessionID != sessionID) return false
        ownerSessionID = null; segmentStartMillis = null; previous = null; interruptedAnchor = null
        if (clear) { points = emptyList(); distanceMeters = 0.0 }
        return true
    }
    fun accept(fix: Fix, nowMillis: Long): Update? {
        val id = ownerSessionID ?: return null
        val began = segmentStartMillis ?: return null
        if (fix.timestampMillis > nowMillis + 10_000 || fix.timestampMillis < began - 3_000 ||
            fix.accuracy !in 0.0..35.0 || fix.latitude !in -90.0..90.0 || fix.longitude !in -180.0..180.0) return null
        var delta = 0.0
        previous?.let { old ->
            val seconds = (fix.timestampMillis - old.timestampMillis) / 1000.0
            if (seconds <= 0) return null
            val meters = LiveGPXTurnDetection.distance(
                WorkoutRoutePoint(0,old.latitude,old.longitude,old.timestampMillis),
                WorkoutRoutePoint(1,fix.latitude,fix.longitude,fix.timestampMillis))
            if (seconds <= 30 && meters / seconds <= speedLimit) {
                val jitter = max(3.0,min(7.0,max(fix.accuracy,old.accuracy)*0.4))
                if (meters < jitter) return null
                delta = meters
            }
        }
        // Primer GPS real tras relanzar: infiere solo un intervalo plausible.
        // Las posiciones estimadas no se introducen en Salud.
        var bridged: List<WorkoutRoutePoint> = emptyList()
        var bridgedMeters = 0.0
        interruptedAnchor?.let { anchor ->
            interruptedAnchor = null
            val next = WorkoutRoutePoint(0,fix.latitude,fix.longitude,fix.timestampMillis)
            InterruptedRouteEstimator.bridge(anchor,next,recoveryMaximumSpeedMps)?.let { estimate ->
                bridged = estimate.points.mapIndexed { index, item -> item.copy(id = points.size + index) }
                bridgedMeters = estimate.distanceMeters
                points = points + bridged
            }
        }
        distanceMeters += delta + bridgedMeters
        val validVertical = fix.verticalAccuracy?.takeIf { it in 0.0..50.0 }
        val p = WorkoutRoutePoint(points.size,fix.latitude,fix.longitude,fix.timestampMillis,
            fix.speedMps?.takeIf { it.isFinite() && it >= 0 },
            fix.altitude?.takeIf { validVertical != null && it.isFinite() },fix.accuracy,validVertical)
        previous = fix; points = points + p
        return Update(id,p,distanceMeters,bridged,bridgedMeters)
    }
}
