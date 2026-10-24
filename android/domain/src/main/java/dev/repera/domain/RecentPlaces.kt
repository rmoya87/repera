package dev.repera.domain

/** Lugares recientes del buscador de sitios (RecentPlacesStore iOS,
 *  PlaceSearchSheet.swift): máximo 5, más reciente primero, sin duplicados
 *  por identificador del proveedor ni por proximidad de coordenadas. */
object RecentPlaces {
    const val LIMIT = 5

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
