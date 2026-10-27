package dev.repera.domain

import kotlin.math.asin
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/** Recuperación prudente de un hueco GPS tras un cierre imprevisto. Solo
 *  interpolación EN LÍNEA RECTA, nunca un recorrido real ni una medida Salud.
 *  Port 1:1 de InterruptedRouteEstimator (iOS, commit ca3c0383). */
object InterruptedRouteEstimator {

    data class Estimate(
        val points: List<WorkoutRoutePoint>,
        val distanceMeters: Double,
        val missingSeconds: Double
    )

    const val MAXIMUM_GAP_SECONDS: Double = 30.0 * 60.0

    fun bridge(
        last: WorkoutRoutePoint,
        first: WorkoutRoutePoint,
        maximumSpeedMps: Double
    ): Estimate? {
        val seconds = (first.recordedAtEpochMs - last.recordedAtEpochMs) / 1000.0
        if (seconds <= 30 || seconds > MAXIMUM_GAP_SECONDS) return null
        if (!last.latitude.isFinite() || !last.longitude.isFinite() ||
            !first.latitude.isFinite() || !first.longitude.isFinite()
        ) return null
        if (last.latitude !in -90.0..90.0 || first.latitude !in -90.0..90.0) return null
        if (last.longitude !in -180.0..180.0 || first.longitude !in -180.0..180.0) return null
        if (!maximumSpeedMps.isFinite() || maximumSpeedMps <= 0) return null

        val lat1 = last.latitude * Math.PI / 180
        val lat2 = first.latitude * Math.PI / 180
        val latDiff = (first.latitude - last.latitude) * Math.PI / 180
        val lonDiff = (first.longitude - last.longitude) * Math.PI / 180
        val half = sin(latDiff / 2).pow(2) +
            cos(lat1) * cos(lat2) * sin(lonDiff / 2).pow(2)
        val meters = 6_371_000.0 * 2 * asin(min(1.0, sqrt(max(0.0, half))))
        if (!meters.isFinite() || meters < 5 || meters / seconds > maximumSpeedMps) return null

        // Equiespaciados en el tiempo. Solo internos; extremos son lecturas reales.
        val intervals = max(2, min(120, ceil(seconds / 15).toInt()))
        val speed = meters / seconds
        val points = (1 until intervals).map { index ->
            val fraction = index.toDouble() / intervals
            WorkoutRoutePoint(
                id = 0,
                latitude = last.latitude + (first.latitude - last.latitude) * fraction,
                longitude = last.longitude + (first.longitude - last.longitude) * fraction,
                recordedAtEpochMs = last.recordedAtEpochMs + (seconds * 1000.0 * fraction).toLong(),
                speedMps = speed,
                isEstimated = true
            )
        }
        return Estimate(points = points, distanceMeters = meters, missingSeconds = seconds)
    }
}
