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
        var speeds: List<Double?> = (0 until points.lastIndex).map { i ->
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
        // Suavizado minimo (Apple b74ad790 makeRun): vecinos ±1 con peso 2 al
        // tramo central; un promedio de 5 muestras borraba los contrastes en
        // recorridos cortos.
        val smoothed = speeds.indices.map { i ->
            val lower = maxOf(0, i - 1);val upper = minOf(speeds.size - 1, i + 1)
            var total = 0.0;var weightSum = 0.0
            for (n in lower..upper) speeds[n]?.let { leg ->
                val w = if (n == i) 2.0 else 1.0;total += leg * w;weightSum += w }
            if (weightSum > 0.0) total / weightSum else null
        }
        // Escala relativa a ESTE entrenamiento (Apple b74ad790): recorte de
        // percentiles 5/95 con >=20 muestras para que un salto GPS aislado no
        // pinte toda la ruta del mismo verde; la escala ignora tramos estimados.
        fun estimatedPair(i: Int) = points[i].isEstimated == true || points[i + 1].isEstimated == true
        val real = smoothed.filterIndexed { i, v -> v != null && !estimatedPair(i) }.filterNotNull()
        val pool = (if (real.isNotEmpty()) real else smoothed.filterNotNull())
            .filter { it.isFinite() && it >= 0 }.sorted()
        if (pool.isEmpty()) return emptyList()
        val absMin = pool.first();val absMax = pool.last()
        var minS = absMin;var maxS = maxOf(absMax, absMin + 0.1)
        if (pool.size >= 20) {
            val lower = pool[(pool.size - 1) * 5 / 100]
            val upper = pool[(pool.size - 1) * 95 / 100]
            if (upper - lower >= 0.12) { minS = lower;maxS = upper }
        }
        speeds = smoothed
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

    /** Apple HistoryView.speedColor (live main, b74ad790): four stops, slow to
     *  fast; the slow stop is greener for water sports. La curva pow(t, 0.72)
     *  da presencia a amarillo/naranja incluso en rutas cuyos ritmos se
     *  concentran cerca del minimo, sin cambiar los datos registrados. */
    fun speedColor(speed: Double, minSpeed: Double, maxSpeed: Double, water: Boolean = false): Long {
        val normalized = ((speed - minSpeed) / maxOf(maxSpeed - minSpeed, 0.1)).coerceIn(0.0, 1.0)
        val t = Math.pow(normalized, 0.72)
        val stops = listOf(
            if (water) Triple(0.00, 1.00, 0.45) else Triple(0.00, 1.00, 0.25),
            Triple(1.00, 0.98, 0.00), Triple(1.00, 0.43, 0.00), Triple(1.00, 0.07, 0.15))
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
