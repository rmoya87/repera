package dev.repera.domain

/** Apple HealthKitStore.attachRecordedRouteIfNeeded (435f6992): filtrado puro
 *  de los puntos GPS grabados por Repera antes de exportarlos a la salud del
 *  sistema. Solo coordenadas validas dentro de la ventana del entreno (±60 s);
 *  se conserva el orden de grabacion; con menos de 2 puntos no hay ruta
 *  exportable. La ruta local NUNCA se pierde si la salud deniega el permiso. */
object RouteHealthExport {
    const val WINDOW_SLACK_MS = 60_000L
    const val MIN_POINTS = 2

    fun exportablePoints(
        points: List<WorkoutRoutePoint>,
        startEpochMs: Long,
        endEpochMs: Long
    ): List<WorkoutRoutePoint> {
        val lo = startEpochMs - WINDOW_SLACK_MS
        val hi = endEpochMs + WINDOW_SLACK_MS
        val filtered = points.filter { p ->
            p.latitude in -90.0..90.0 && p.longitude in -180.0..180.0 &&
                p.recordedAtEpochMs in lo..hi
        }
        return if (filtered.size >= MIN_POINTS) filtered else emptyList()
    }
}
