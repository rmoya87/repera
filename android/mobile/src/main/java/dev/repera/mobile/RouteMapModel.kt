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

    data class Segment(val a: WorkoutRoutePoint, val b: WorkoutRoutePoint, val argb: Long,
                       val estimated: Boolean = false)
    data class Camera(val centerLat: Double, val centerLon: Double,
                      val spanLat: Double, val spanLon: Double)

    fun segments(points: List<WorkoutRoutePoint>, water: Boolean = false): List<Segment> {
        if (points.size < 2) return emptyList()
        val speeds = (0 until points.lastIndex).map { i ->
            val a = points[i];val b = points[i+1]
            val seconds = (b.recordedAtEpochMs-a.recordedAtEpochMs)/1000.0
            if (seconds <= 0 || seconds > 30) null
            else {
                val geometric = dev.repera.domain.LiveGPXTurnDetection.distance(a,b)/seconds
                if (!geometric.isFinite() || geometric > 25) null
                else (b.speedMps ?: a.speedMps)?.takeIf { it.isFinite() && it in 0.2..25.0 }
                    ?: geometric.takeIf { it >= 0.2 }
            }
        }
        val valid = speeds.filterNotNull()
        val minS = valid.minOrNull() ?: 0.0
        val maxS = maxOf(valid.maxOrNull() ?: 1.0,minS+0.1)
        return speeds.mapIndexedNotNull { i,speed ->
            // Trazo estimado tras un cierre: discontinuo y rotulado, nunca
            // presentado como medicion GPS (Apple 303453ff/9f62c49a).
            val est = points[i].isEstimated == true || points[i+1].isEstimated == true
            speed?.let { Segment(points[i],points[i+1],speedColor(it,minS,maxS,water),est) }
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

    /** Apple HistoryView.speedColor (live main): four stops, slow to fast; the slow stop is greener for water sports. */
    fun speedColor(speed: Double, minSpeed: Double, maxSpeed: Double, water: Boolean = false): Long {
        val t = ((speed - minSpeed) / maxOf(maxSpeed - minSpeed, 0.1)).coerceIn(0.0, 1.0)
        val stops = listOf(
            if (water) Triple(0.10, 0.84, 0.42) else Triple(0.15, 0.88, 0.30),
            Triple(1.00, 0.87, 0.10), Triple(1.00, 0.48, 0.06), Triple(0.96, 0.18, 0.13))
        val scaled = t * 3
        val index = minOf(2, scaled.toInt())
        val amount = scaled - index
        val a = stops[index]; val bb = stops[index + 1]
        val r = a.first + (bb.first - a.first) * amount
        val g = a.second + (bb.second - a.second) * amount
        val b = a.third + (bb.third - a.third) * amount
        fun c(v: Double): Long = (v.coerceIn(0.0, 1.0) * 255).toLong()
        return 0xFF000000L or (c(r) shl 16) or (c(g) shl 8) or c(b)
    }
}
