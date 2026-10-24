package dev.repera.domain

import java.text.Normalizer

/** Pin de ubicación de un entreno (gimnasio / punto de inicio).
 *  Port 1:1 de WorkoutLocationPin (Models.swift iOS). */
data class WorkoutLocationPin(
    val latitude: Double,
    val longitude: Double,
    val recordedAtEpochMs: Long,
    /** Nombre del sitio si se eligió a mano (búsqueda de lugares). */
    val name: String? = null,
    /** Identificador del proveedor de mapas para reconstruir el marcador. */
    val mapItemIdentifier: String? = null,
    /** Categoría de punto de interés del proveedor de mapas. */
    val pointOfInterestCategory: String? = null
)

/** Punto de ruta GPS grabado por Repera (outdoor). Port de WorkoutRoutePoint. */
data class WorkoutRoutePoint(
    val id: Int,
    val latitude: Double,
    val longitude: Double,
    val recordedAtEpochMs: Long,
    /** m/s (≥ 0). Null si no se pudo estimar. */
    val speedMps: Double? = null,
    /** Altitud GPS validada (precisión vertical 0-50 m), metros sobre el mar. */
    val altitudeMeters: Double? = null
)

/** Lógica pura del tracker de ubicación (port WorkoutLocationTracker iOS). */
object WorkoutLocationLogic {

    const val MIN_DISTANCE_METERS = 8f
    const val MAX_ROUTE_POINTS = 400

    /** Heurística: carrera / bici / caminata / outdoor en título o nombres de
     *  ejercicio. Plegado diacrítico 1:1 con `folding(.diacriticInsensitive)`. */
    fun shouldTrackRoute(title: String, exerciseNames: List<String>): Boolean {
        val blob = Normalizer.normalize(
            (listOf(title) + exerciseNames).joinToString(" ").lowercase(),
            Normalizer.Form.NFD
        ).replace(Regex("\\p{M}+"), "")
        val keywords = listOf(
            "correr", "carrera", "running", "run",
            "bici", "ciclismo", "cycling", "bike",
            "caminar", "caminata", "walking", "hike", "hiking",
            "trail", "outdoor", "remo outdoor", "ski", "skate"
        )
        return keywords.any { blob.contains(it) }
    }

    /** Downsample uniforme conservando extremos (port de downsample iOS):
     *  con más de maxCount puntos, selecciona maxCount equiespaciados y
     *  renumera ids 0..maxCount-1. */
    fun downsample(points: List<WorkoutRoutePoint>, maxCount: Int = MAX_ROUTE_POINTS): List<WorkoutRoutePoint> {
        if (points.size <= maxCount || maxCount <= 2) return points
        val step = (points.size - 1).toDouble() / (maxCount - 1)
        return (0 until maxCount).map { i ->
            val idx = minOf(points.size - 1, kotlin.math.round(i * step).toInt())
            points[idx].copy(id = i)
        }
    }
}
