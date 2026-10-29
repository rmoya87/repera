package dev.repera.mobile

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.Locale

/** Búsqueda de POI por nombre (gimnasios, parques, clubes) con Photon
 *  (photon.komoot.io, datos OSM). Sin cuenta, sin clave, sin coste.
 *
 *  Política publicada (README komoot/photon): se puede usar la API pública
 *  "mientras el número de peticiones se mantenga en un límite razonable";
 *  el uso extensivo se limita o bloquea y no hay garantías. Por eso:
 *   - sólo se consulta con pausa de tecleo (PlaceSearchPolicy) y ≥ 3 caracteres,
 *   - separación mínima entre peticiones de red (MIN_INTERVAL_MS),
 *   - caché en memoria por consulta y sesgo redondeado,
 *   - ante 429/5xx/timeout se abre un enfriamiento (COOLDOWN_MS) y la UI
 *     degrada a Geocoder + pin manual, sin errores visibles.
 *  Privacidad: sale a un tercero el texto buscado y el centro del mapa
 *  redondeado a 2 decimales (~1 km), nunca la ubicación exacta ni identidad. */
class PhotonPlaceSearchProvider(
    private val fetch: suspend (url: String) -> HttpResult = ::httpGet,
    private val nowMs: () -> Long = System::currentTimeMillis,
    private val pause: suspend (Long) -> Unit = { kotlinx.coroutines.delay(it) }
) : PlaceSearchProvider {

    data class HttpResult(val code: Int, val body: String)

    private val cache = object : LinkedHashMap<String, List<PlaceSearchResult>>(16, 0.75f, true) {
        override fun removeEldestEntry(e: MutableMap.MutableEntry<String, List<PlaceSearchResult>>) =
            size > CACHE_SIZE
    }
    private var lastCallAt = 0L
    private var cooldownUntil = 0L

    /** true cuando el último intento no pudo consultar el servicio (límite, caída,
     *  enfriamiento): un resultado vacío NO significa «sin establecimientos». */
    @Volatile var degraded: Boolean = false
        private set

    override suspend fun search(
        query: String,
        biasMinLat: Double?, biasMinLon: Double?,
        biasMaxLat: Double?, biasMaxLon: Double?
    ): List<PlaceSearchResult> {
        val q = query.trim()
        if (!dev.repera.domain.PlaceSearchPolicy.shouldSearch(q)) return emptyList()
        val centerLat = if (biasMinLat != null && biasMaxLat != null) (biasMinLat + biasMaxLat) / 2 else null
        val centerLon = if (biasMinLon != null && biasMaxLon != null) (biasMinLon + biasMaxLon) / 2 else null
        val url = buildUrl(q, centerLat, centerLon)
        synchronized(cache) { cache[url] }?.let { degraded = false; return it }
        val now = nowMs()
        if (now < cooldownUntil) {
            degraded = true
            return emptyList()
        }
        // Separación mínima: se ESPERA (no se descarta) para que dos búsquedas
        // legítimas seguidas no parezcan un fallo del servicio.
        val wait = MIN_INTERVAL_MS - (now - lastCallAt)
        if (wait > 0) pause(wait)
        lastCallAt = nowMs()
        val result = runCatching { fetch(url) }.getOrNull()
        if (result == null || result.code == 429 || result.code >= 500) {
            cooldownUntil = nowMs() + COOLDOWN_MS
            degraded = true
            return emptyList()
        }
        if (result.code != 200) { degraded = true; return emptyList() }
        degraded = false
        val parsed = parse(result.body)
        synchronized(cache) { cache[url] = parsed }
        return parsed
    }

    companion object {
        const val BASE = "https://photon.komoot.io/api/"
        const val MIN_INTERVAL_MS = 1_000L
        /** R5 P1-6: Photon suele tardar ~4,5 s; 4 s provocaba timeout+cooldown. */
        const val COOLDOWN_MS = 30_000L
        const val HTTP_TIMEOUT_MS = 12_000
        const val CACHE_SIZE = 40
        const val USER_AGENT = "Repera-Android/1.0 (dev.repera.mobile)"

        fun buildUrl(q: String, lat: Double?, lon: Double?): String {
            val sb = StringBuilder(BASE)
                .append("?q=").append(URLEncoder.encode(q, "UTF-8"))
                .append("&limit=").append(dev.repera.domain.PlaceSearchPolicy.MAX_RESULTS)
            if (lat != null && lon != null) {
                sb.append("&lat=").append(String.format(Locale.US, "%.2f", lat))
                    .append("&lon=").append(String.format(Locale.US, "%.2f", lon))
            }
            return sb.toString()
        }

        /** GeoJSON de Photon → resultados. Ignora features sin nombre o coordenadas. */
        fun parse(body: String): List<PlaceSearchResult> = runCatching {
            val features = JSONObject(body).optJSONArray("features") ?: return emptyList()
            (0 until features.length()).mapNotNull { i ->
                val f = features.optJSONObject(i) ?: return@mapNotNull null
                val coords = f.optJSONObject("geometry")?.optJSONArray("coordinates")
                    ?: return@mapNotNull null
                if (coords.length() < 2) return@mapNotNull null
                val lon = coords.optDouble(0, Double.NaN)
                val lat = coords.optDouble(1, Double.NaN)
                if (lat.isNaN() || lon.isNaN() || lat !in -90.0..90.0 || lon !in -180.0..180.0)
                    return@mapNotNull null
                val p = f.optJSONObject("properties") ?: return@mapNotNull null
                val name = p.optString("name").takeIf { it.isNotBlank() } ?: return@mapNotNull null
                val street = listOf(p.optString("street"), p.optString("housenumber"))
                    .filter { it.isNotBlank() }.joinToString(" ")
                val address = listOf(street, p.optString("city"), p.optString("country"))
                    .filter { it.isNotBlank() }.joinToString(", ").takeIf { it.isNotBlank() }
                val osmType = p.optString("osm_type")
                val osmId = p.optLong("osm_id", -1)
                PlaceSearchResult(
                    name = name, latitude = lat, longitude = lon,
                    providerId = if (osmId >= 0 && osmType.isNotBlank()) "osm:$osmType$osmId"
                    else "photon:${name.lowercase()}@%.5f,%.5f".format(Locale.US, lat, lon),
                    featureName = name, addressLine = address
                )
            }.distinctBy { it.providerId }
        }.getOrDefault(emptyList())

        suspend fun httpGet(url: String): HttpResult = withContext(Dispatchers.IO) {
            val c = URL(url).openConnection() as HttpURLConnection
            try {
                c.connectTimeout = HTTP_TIMEOUT_MS
                c.readTimeout = HTTP_TIMEOUT_MS
                c.setRequestProperty("User-Agent", USER_AGENT)
                c.setRequestProperty("Accept", "application/json")
                val code = c.responseCode
                val body = if (code == 200) c.inputStream.bufferedReader().use { it.readText() } else ""
                HttpResult(code, body)
            } finally { c.disconnect() }
        }
    }
}

/** Photon primero (POI por nombre); si falla, está en enfriamiento o no
 *  devuelve nada, cae a Geocoder (direcciones/lugares de plataforma). */
class CompositePlaceSearchProvider(
    private val primary: PlaceSearchProvider,
    private val fallback: PlaceSearchProvider
) : PlaceSearchProvider {
    /** La búsqueda de establecimientos (primaria) no pudo consultarse en la última búsqueda. */
    val establishmentsUnavailable: Boolean
        get() = (primary as? PhotonPlaceSearchProvider)?.degraded == true

    override suspend fun search(
        query: String,
        biasMinLat: Double?, biasMinLon: Double?,
        biasMaxLat: Double?, biasMaxLon: Double?
    ): List<PlaceSearchResult> {
        val first = primary.search(query,biasMinLat,biasMinLon,biasMaxLat,biasMaxLon)
        if (first.size >= dev.repera.domain.PlaceSearchPolicy.MAX_RESULTS) return first
        // Los POI y las direcciones son complementarios; sin Google ni facturación.
        val more = runCatching {
            fallback.search(query,biasMinLat,biasMinLon,biasMaxLat,biasMaxLon)
        }.getOrDefault(emptyList())
        return (first + more).filter {
            it.latitude.isFinite() && it.longitude.isFinite() &&
                it.latitude in -90.0..90.0 && it.longitude in -180.0..180.0
        }.fold(mutableListOf<PlaceSearchResult>()) { items, candidate ->
            val duplicate = items.any {
                it.name.trim().equals(candidate.name.trim(),ignoreCase=true) &&
                    kotlin.math.abs(it.latitude-candidate.latitude)<0.0005 &&
                    kotlin.math.abs(it.longitude-candidate.longitude)<0.0005
            }
            if (!duplicate) items.add(candidate)
            items
        }.take(dev.repera.domain.PlaceSearchPolicy.MAX_RESULTS)
    }
}
