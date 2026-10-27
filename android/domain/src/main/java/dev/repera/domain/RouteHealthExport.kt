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

    /** Salida para Health Connect (ExerciseRoute): aplica la ventana Apple
     *  (±60 s) y ADEMAS las restricciones que exige el propio registro HC,
     *  verificadas contra el bytecode de connect-client 1.1.0:
     *  - "route can not be out of parent time range": cada punto dentro de
     *    [start, end] EXACTOS de la sesion (el slack ±60 s de Apple no es
     *    aceptado por HC y haria fallar el insert en runtime).
     *  - Timestamps monotonos crecientes sin duplicados (GPS puede repetir
     *    instante): ordenados por tiempo, el primer punto de cada instante.
     *  - Al menos MIN_POINTS tras el recorte; si no, no hay ruta exportable. */
    fun healthConnectRoutePoints(
        points: List<WorkoutRoutePoint>,
        startEpochMs: Long,
        endEpochMs: Long
    ): List<WorkoutRoutePoint> {
        val within = exportablePoints(points, startEpochMs, endEpochMs)
            .filter { it.recordedAtEpochMs in startEpochMs..endEpochMs }
            .sortedBy { it.recordedAtEpochMs }
            .distinctBy { it.recordedAtEpochMs }
        return if (within.size >= MIN_POINTS) within else emptyList()
    }
}
