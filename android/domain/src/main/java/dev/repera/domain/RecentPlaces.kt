package dev.repera.domain

/** Lugares recientes del buscador de sitios (RecentPlacesStore iOS,
 *  PlaceSearchSheet.swift): máximo 5, más reciente primero, sin duplicados
 *  por identificador del proveedor ni por proximidad de coordenadas. */
object RecentPlaces {
    const val LIMIT = 5

    /** Sugerencia de lugar habitual basada sólo en GPS disponible al abrir el
     * selector, sin rastreo en segundo plano ni adivinar la ubicación. */
    fun nearbyNamed(
        current: List<WorkoutLocationPin>,
        latitude: Double,
        longitude: Double,
        maxMeters: Double = 50.0
    ): WorkoutLocationPin? {
        if (!latitude.isFinite() || !longitude.isFinite()) return null
        val latRad = Math.toRadians(latitude)
        return current
            .filter { !it.name.isNullOrBlank() }
            .mapNotNull { place ->
                val dLat = Math.toRadians(place.latitude - latitude)
                val dLon = Math.toRadians(place.longitude - longitude)
                val a = kotlin.math.sin(dLat / 2).let { it * it } +
                    kotlin.math.cos(latRad) * kotlin.math.cos(Math.toRadians(place.latitude)) *
                    kotlin.math.sin(dLon / 2).let { it * it }
                val distance = 2.0 * 6371000.0 * kotlin.math.asin(
                    kotlin.math.sqrt(a.coerceIn(0.0, 1.0))
                )
                if (distance <= maxMeters) place to distance else null
            }.minByOrNull { it.second }?.first
    }

    /** iOS isSamePlace: mismo mapItemIdentifier (si ambos lo tienen) o
     *  coordenadas a < 0.0001° (~11 m). */
    fun isSamePlace(a: WorkoutLocationPin, b: WorkoutLocationPin): Boolean {
        val ida = a.mapItemIdentifier
        val idb = b.mapItemIdentifier
        if (!ida.isNullOrEmpty() && !idb.isNullOrEmpty() && ida == idb) return true
        return kotlin.math.abs(a.latitude - b.latitude) < 0.0001 &&
            kotlin.math.abs(a.longitude - b.longitude) < 0.0001
    }

    /** remember(pin) iOS: quita duplicados del mismo sitio, inserta al frente
     *  y recorta al límite. */
    fun remember(current: List<WorkoutLocationPin>, pin: WorkoutLocationPin): List<WorkoutLocationPin> {
        val next = current.filter { !isSamePlace(it, pin) }.toMutableList()
        next.add(0, pin)
        return next.take(LIMIT)
    }
}
