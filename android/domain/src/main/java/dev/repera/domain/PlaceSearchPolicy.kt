package dev.repera.domain

/** Política de búsqueda de lugares en Android.
 *
 *  DECISIÓN (25/10, registrada en CAPABILITY_INVENTORY #1): el proveedor es
 *  android.location.Geocoder (plataforma): sin API key, sin facturación y sin
 *  condiciones de uso propias. iOS usa MKLocalSearchCompleter (autocompletado
 *  por tecla de Apple Maps, gratis en iOS). Geocoder no es una API de
 *  autocompletado y puede estar limitado por tasa según el backend del
 *  dispositivo, así que la búsqueda se dispara con pausa de tecleo
 *  (DEBOUNCE_MS) y mínimo de caracteres, no por tecla — diferencia de
 *  fidelidad documentada por restricción de plataforma, no por descuido.
 *  Nominatim público queda descartado (su política no admite asumir
 *  autocompletado en producción) y Google Places por requerir facturación
 *  (solo si el usuario lo pide explícitamente). */
object PlaceSearchPolicy {
    const val MIN_QUERY_CHARS = 3
    const val DEBOUNCE_MS = 800L
    const val MAX_RESULTS = 5

    /** ¿Lanza búsqueda este texto? (trim, mínimo de caracteres). */
    fun shouldSearch(query: String): Boolean = query.trim().length >= MIN_QUERY_CHARS
}
