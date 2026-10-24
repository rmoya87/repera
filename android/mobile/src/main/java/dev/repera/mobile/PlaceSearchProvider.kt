package dev.repera.mobile

import android.content.Context
import android.location.Geocoder
import android.os.Build
import dev.repera.domain.PlaceSearchPolicy
import dev.repera.domain.WorkoutLocationPin
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/** Resultado de búsqueda de lugares para el pin de gym. */
data class PlaceSearchResult(
    val name: String,
    val latitude: Double,
    val longitude: Double,
    /** Identificador estable del proveedor para reconstruir el marcador
     *  (mapItemIdentifier iOS). Geocoder no ofrece id de POI: se usa una
     *  clave derivada nombre+coordenadas redondeadas. */
    val providerId: String,
    val featureName: String? = null,
    val addressLine: String? = null
) {
    fun toPin(): WorkoutLocationPin = WorkoutLocationPin(
        latitude = latitude,
        longitude = longitude,
        recordedAtEpochMs = 0L,
        name = name,
        mapItemIdentifier = providerId
    )
}

interface PlaceSearchProvider {
    /** Busca por nombre/dirección con sesgo de región (como setRegion iOS).
     *  Devuelve lista vacía si no hay resultados o el backend no está
     *  disponible; nunca lanza por ausencia de servicio. */
    suspend fun search(
        query: String,
        biasMinLat: Double? = null,
        biasMinLon: Double? = null,
        biasMaxLat: Double? = null,
        biasMaxLon: Double? = null
    ): List<PlaceSearchResult>
}

/** Proveedor de plataforma (android.location.Geocoder): sin API key, sin
 *  facturación, sin condiciones propias. No es autocompletado por tecla:
 *  la UI aplica PlaceSearchPolicy.DEBOUNCE_MS/MIN_QUERY_CHARS. La resolución
 *  de POIs por nombre depende del backend de geocodificación del dispositivo
 *  (Play services en la mayoría): si un dispositivo no resuelve nombres, la
 *  colocación manual del pin sigue disponible (browse map, como iOS). */
class GeocoderPlaceSearchProvider(private val context: Context) : PlaceSearchProvider {

    override suspend fun search(
        query: String,
        biasMinLat: Double?, biasMinLon: Double?,
        biasMaxLat: Double?, biasMaxLon: Double?
    ): List<PlaceSearchResult> {
        if (!PlaceSearchPolicy.shouldSearch(query)) return emptyList()
        val geocoder = Geocoder(context)
        if (!Geocoder.isPresent()) return emptyList()
        val addresses = if (Build.VERSION.SDK_INT >= 33) {
            suspendCancellableCoroutine<List<android.location.Address>> { cont ->
                val listener = object : Geocoder.GeocodeListener {
                    override fun onGeocode(results: MutableList<android.location.Address>) {
                        cont.resume(results)
                    }
                    override fun onError(errorMessage: String?) {
                        cont.resume(emptyList())
                    }
                }
                if (biasMinLat != null && biasMinLon != null && biasMaxLat != null && biasMaxLon != null) {
                    geocoder.getFromLocationName(query, PlaceSearchPolicy.MAX_RESULTS,
                        biasMinLat, biasMinLon, biasMaxLat, biasMaxLon, listener)
                } else {
                    geocoder.getFromLocationName(query, PlaceSearchPolicy.MAX_RESULTS, listener)
                }
            }
        } else {
            @Suppress("DEPRECATION")
            runCatching {
                if (biasMinLat != null && biasMinLon != null && biasMaxLat != null && biasMaxLon != null) {
                    geocoder.getFromLocationName(query, PlaceSearchPolicy.MAX_RESULTS,
                        biasMinLat, biasMinLon, biasMaxLat, biasMaxLon)
                } else {
                    geocoder.getFromLocationName(query, PlaceSearchPolicy.MAX_RESULTS)
                }
            }.getOrNull().orEmpty()
        }
        return addresses.mapNotNull { a ->
            val name = a.featureName?.takeIf { it.isNotBlank() }
                ?: a.getAddressLine(0)?.takeIf { it.isNotBlank() }
                ?: return@mapNotNull null
            PlaceSearchResult(
                name = name,
                latitude = a.latitude,
                longitude = a.longitude,
                providerId = "geocoder:${name.lowercase()}@" +
                    "%.5f,%.5f".format(a.latitude, a.longitude),
                featureName = a.featureName,
                addressLine = a.getAddressLine(0)
            )
        }.distinctBy { it.providerId }
    }
}
