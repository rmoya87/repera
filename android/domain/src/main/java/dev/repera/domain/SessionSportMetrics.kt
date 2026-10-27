package dev.repera.domain

/** Métricas de deporte del detalle de sesión (Apple SessionSportMetricTile / LiveSportHistoryView, live main).
 *  Totales de la actividad completa: distancia y tiempo ACTIVO medidos, no solo los km cerrados. */
object SessionSportMetrics {
    data class Tiles(val averageSpeedKmh: Double?, val maxSpeedKmh: Double?, val averagePace: String?, val distanceKm: Double?)

    fun decimal(value: Double): String = ReperaNumberFormat.decimal(value)

    fun averageSpeedKmh(activeSeconds: Double?, meters: Double?): Double? {
        if (activeSeconds == null || activeSeconds <= 0 || meters == null || meters <= 0) return null
        return meters / activeSeconds * 3.6
    }

    /** Velocidad máxima registrada; si no, el máximo de las muestras GPS válidas (finitas, > 0, <= 50 m/s). */
    fun maxSpeedKmh(recordedKmh: Double?, points: List<WorkoutRoutePoint>): Double? {
        if (recordedKmh != null && recordedKmh > 0) return recordedKmh
        return points.mapNotNull { it.speedMps }.filter { it.isFinite() && it > 0 && it <= 50 }.maxOrNull()?.let { it * 3.6 }
    }

    /** "m:ss" por kilómetro. */
    fun averagePace(activeSeconds: Double?, meters: Double?): String? {
        if (activeSeconds == null || activeSeconds <= 0 || meters == null || meters <= 0) return null
        val perKm = Math.round(activeSeconds / (meters / 1000)).toInt()
        return "%d:%02d".format(perKm / 60, perKm % 60)
    }

    /** Apple hasGPSMetrics: movimiento exterior (deporte con GPS, o ruta >= 2 puntos si no hay deporte) con distancia, ruta o parciales. */
    fun showsGpsTiles(sport: LiveSport?, meters: Double?, points: List<WorkoutRoutePoint>, hasSplits: Boolean): Boolean {
        val outdoor = sport?.usesGPS ?: (points.size >= 2)
        return outdoor && ((meters ?: 0.0) > 0 || points.size >= 2 || hasSplits)
    }

    fun tiles(sport: LiveSport?, activeSeconds: Double?, meters: Double?, recordedMaxKmh: Double?, points: List<WorkoutRoutePoint>): Tiles =
        Tiles(averageSpeedKmh(activeSeconds, meters), maxSpeedKmh(recordedMaxKmh, points), averagePace(activeSeconds, meters),
            meters?.takeIf { it > 0 }?.let { it / 1000 })

    /** Ciclismo y deportes de velocidad priorizan distancia frente a un ritmo por kilómetro poco representativo. */
    fun showsDistanceInsteadOfPace(sport: LiveSport?): Boolean = sport?.let { it.isCycling || it.displaysSpeed } == true

    data class Range(val min: Int, val avg: Int, val max: Int)

    /** Apple miniStat Mín/Media/Máx (redondeado). Null sin datos. La media es la de la serie aportada, no un promedio medido por Salud. */
    fun range(values: List<Double>): Range? {
        val v = values.filter { it.isFinite() }
        if (v.isEmpty()) return null
        return Range(Math.round(v.min()).toInt(), Math.round(v.average()).toInt(), Math.round(v.max()).toInt())
    }

    fun heartRange(bpm: List<Int>): Range? = range(bpm.filter { it > 0 }.map { it.toDouble() })

    fun altitudeRange(points: List<WorkoutRoutePoint>): Range? = range(points.mapNotNull { it.altitudeMeters })

    data class SplitRow(val kilometer: Int, val time: String, val rateOrSpeed: String, val bpm: String)

    private fun clock(seconds: Double): String { val t = Math.round(seconds).toInt(); return "%d:%02d".format(t / 60, t % 60) }

    /** Apple displayedSplits: se descartan parciales no finitos o <= 0; columnas KM, Tiempo, Ritmo (o km/h) y FC ("—" si falta). */
    fun splitRows(seconds: List<Double>, speed: Boolean, bpmByKm: Map<Int, Double>): List<SplitRow> =
        seconds.mapIndexedNotNull { i, s ->
            if (!s.isFinite() || s <= 0) null else SplitRow(i + 1, clock(s),
                if (speed) ReperaNumberFormat.decimal(3600 / maxOf(1.0, s)) else clock(s) + "/km",
                bpmByKm[i + 1]?.let { "${Math.round(it).toInt()} LPM" } ?: "—")
        }
}
