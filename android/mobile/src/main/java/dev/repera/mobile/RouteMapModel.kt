package dev.repera.mobile

import dev.repera.domain.WorkoutRoutePoint

/**
 * Modelo puro del mapa de ruta (paridad HealthWorkoutRouteMap iOS,
 * HistoryView.swift): segmentos coloreados por velocidad (verde lento →
 * amarillo → rojo rápido), cámara = centro de bounds con margen 1.5× y span
 * mínimo 0.008°, puntos de inicio/fin. Sin dependencias Android: testable en
 * JVM y reutilizable por el mapa real y por el degradado en Canvas.
 */
internal object RouteMapModel {

    data class Segment(val a: WorkoutRoutePoint, val b: WorkoutRoutePoint, val argb: Long)
    data class Camera(val centerLat: Double, val centerLon: Double,
                      val spanLat: Double, val spanLon: Double)

    fun segments(points: List<WorkoutRoutePoint>): List<Segment> {
        if (points.size < 2) return emptyList()
        val speeds = points.mapNotNull { it.speedMps }.filter { it >= 0 }
        val minS = speeds.minOrNull() ?: 0.0
        val maxS = maxOf(speeds.maxOrNull() ?: 1.0, minS + 0.1)
        return (0 until points.size - 1).map { i ->
            val a = points[i]; val b = points[i + 1]
            val speed = a.speedMps ?: b.speedMps ?: minS
            Segment(a, b, speedColor(speed, minS, maxS))
        }
    }

    fun camera(points: List<WorkoutRoutePoint>): Camera? {
        if (points.isEmpty()) return null
        val minLat = points.minOf { it.latitude }; val maxLat = points.maxOf { it.latitude }
        val minLon = points.minOf { it.longitude }; val maxLon = points.maxOf { it.longitude }
        return Camera(
            centerLat = (minLat + maxLat) / 2,
            centerLon = (minLon + maxLon) / 2,
            spanLat = maxOf((maxLat - minLat) * 1.5, 0.008),
            spanLon = maxOf((maxLon - minLon) * 1.5, 0.008))
    }

    /** Verde (lento) → amarillo → rojo (rápido), mismo gradiente que iOS. */
    fun speedColor(speed: Double, minSpeed: Double, maxSpeed: Double): Long {
        val span = maxOf(maxSpeed - minSpeed, 0.1)
        val t = ((speed - minSpeed) / span).coerceIn(0.0, 1.0)
        val (r, g, b) = if (t < 0.5) {
            val u = t * 2
            Triple(0.2 + 0.8 * u, 0.82, 0.2 * (1 - u))
        } else {
            val u = (t - 0.5) * 2
            Triple(1.0, 0.82 * (1 - u) + 0.27 * u, 0.23 * u)
        }
        fun c(v: Double): Long = (v.coerceIn(0.0, 1.0) * 255).toLong()
        return 0xFF000000L or (c(r) shl 16) or (c(g) shl 8) or c(b)
    }
}
