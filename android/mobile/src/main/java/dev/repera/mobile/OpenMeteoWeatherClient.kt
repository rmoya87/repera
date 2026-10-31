package dev.repera.mobile

import dev.repera.domain.HistoricalWeatherLogic
import dev.repera.domain.HistoricalWeatherReading
import java.net.HttpURLConnection
import java.net.URL
import java.time.ZoneId
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Clima histórico on-demand (paridad WeatherKit iOS).
 * Proveedor: Open-Meteo (gratis, sin API key). No se persiste en el entreno.
 */
internal object OpenMeteoWeatherClient {
    private const val TIMEOUT_MS = 12_000
    private const val USER_AGENT = "ReperaAndroid/1.0 (historical weather; +https://repera.app)"

    const val ATTRIBUTION_LABEL = "Open-Meteo"
    const val ATTRIBUTION_URL = "https://open-meteo.com/"

    suspend fun fetch(
        latitude: Double,
        longitude: Double,
        workoutEpochMs: Long,
        zone: ZoneId = ZoneId.systemDefault()
    ): Result<HistoricalWeatherReading> = withContext(Dispatchers.IO) {
        runCatching {
            require(latitude in -90.0..90.0 && longitude in -180.0..180.0) {
                "Coordenadas no válidas para consultar el tiempo."
            }
            val url = if (HistoricalWeatherLogic.isRecent(workoutEpochMs)) {
                HistoricalWeatherLogic.forecastPastUrl(latitude, longitude)
            } else {
                HistoricalWeatherLogic.archiveUrl(
                    latitude, longitude,
                    HistoricalWeatherLogic.dayIso(workoutEpochMs, zone)
                )
            }
            val body = httpGet(url)
            HistoricalWeatherLogic.parseOpenMeteoHourly(body, workoutEpochMs, zone)
                ?: error("Sin datos horarios para esa fecha y lugar.")
        }
    }

    suspend fun fetchConditions(
        latitude: Double,
        longitude: Double,
        liveSportId: String?,
        atEpochMs: Long = System.currentTimeMillis(),
        zone: ZoneId = ZoneId.systemDefault()
    ): Result<dev.repera.domain.ActivityConditionsSnapshot> = withContext(Dispatchers.IO) {
        runCatching {
            val family = dev.repera.domain.ActivityConditionsSnapshot.familyForLiveSportId(liveSportId)
            require(family != dev.repera.domain.ActivityConditionsFamily.NONE) {
                "Sin familia de condiciones para este deporte."
            }
            val forecast = httpGet(dev.repera.domain.ActivityConditionsLogic.forecastUrl(latitude, longitude))
            val marine = if (family == dev.repera.domain.ActivityConditionsFamily.WATER) {
                runCatching {
                    httpGet(dev.repera.domain.ActivityConditionsLogic.marineUrl(latitude, longitude))
                }.getOrNull()
            } else null
            dev.repera.domain.ActivityConditionsLogic.parse(
                family, forecast, marine, atEpochMs, zone
            ) ?: error("Sin datos de condiciones.")
        }
    }

    private fun httpGet(url: String): String {
        val c = URL(url).openConnection() as HttpURLConnection
        try {
            c.connectTimeout = TIMEOUT_MS
            c.readTimeout = TIMEOUT_MS
            c.setRequestProperty("User-Agent", USER_AGENT)
            c.setRequestProperty("Accept", "application/json")
            val code = c.responseCode
            val stream = if (code in 200..299) c.inputStream else c.errorStream
            val body = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
            check(code in 200..299) { "Tiempo no disponible (HTTP $code)." }
            return body
        } finally {
            c.disconnect()
        }
    }
}
