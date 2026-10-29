package dev.repera.domain

import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

/** Lectura horaria histórica (paridad RouteWeatherStrip iOS: °C, humedad, viento km/h). */
data class HistoricalWeatherReading(
    val temperatureC: Double,
    val humidityFraction: Double,
    val windKmh: Double,
    val weatherCode: Int? = null
) {
    val temperatureLabel: String = "${temperatureC.roundToInt()} °C"
    val humidityLabel: String = "${(humidityFraction * 100).roundToInt()} %"
    val windLabel: String = "${windKmh.roundToInt()} km/h"
}

/**
 * Parseo puro Open-Meteo (archive / forecast hourly).
 * Coordenadas redondeadas a ~1 km como WeatherKit iOS.
 */
object HistoricalWeatherLogic {
    private val hourFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")

    fun roundCoordinate(value: Double): Double =
        (value * 100.0).roundToInt() / 100.0

    fun dayIso(epochMs: Long, zone: ZoneId = ZoneId.systemDefault()): String =
        LocalDate.ofInstant(java.time.Instant.ofEpochMilli(epochMs), zone).toString()

    fun isRecent(epochMs: Long, nowMs: Long = System.currentTimeMillis()): Boolean {
        val ageDays = (nowMs - epochMs) / 86_400_000.0
        return ageDays in -0.5..7.5
    }

    fun pickClosestHour(
        timesIso: List<String>,
        temperatures: List<Double?>,
        humidities: List<Double?>,
        winds: List<Double?>,
        weatherCodes: List<Int?>,
        targetEpochMs: Long,
        zone: ZoneId = ZoneId.systemDefault(),
        maxDeltaMs: Long = 3L * 3600_000L
    ): HistoricalWeatherReading? {
        if (timesIso.isEmpty()) return null
        var bestIdx = -1
        var bestDelta = Long.MAX_VALUE
        timesIso.forEachIndexed { i, raw ->
            val epoch = parseHourEpochMs(raw, zone) ?: return@forEachIndexed
            val delta = abs(epoch - targetEpochMs)
            if (delta < bestDelta) {
                bestDelta = delta
                bestIdx = i
            }
        }
        if (bestIdx < 0 || bestDelta > maxDeltaMs) return null
        val temp = temperatures.getOrNull(bestIdx) ?: return null
        val humidityPct = humidities.getOrNull(bestIdx) ?: return null
        val wind = winds.getOrNull(bestIdx) ?: return null
        return HistoricalWeatherReading(
            temperatureC = temp,
            humidityFraction = (humidityPct / 100.0).coerceIn(0.0, 1.0),
            windKmh = wind,
            weatherCode = weatherCodes.getOrNull(bestIdx)
        )
    }

    fun parseOpenMeteoHourly(
        body: String,
        targetEpochMs: Long,
        zone: ZoneId = ZoneId.systemDefault()
    ): HistoricalWeatherReading? {
        val root = runCatching { JSONObject(body) }.getOrNull() ?: return null
        val hourly = root.optJSONObject("hourly") ?: return null
        val times = hourly.optJSONArray("time") ?: return null
        val temps = hourly.optJSONArray("temperature_2m") ?: return null
        val hums = hourly.optJSONArray("relative_humidity_2m") ?: return null
        val winds = hourly.optJSONArray("wind_speed_10m")
            ?: hourly.optJSONArray("windspeed_10m")
            ?: return null
        val codes = hourly.optJSONArray("weather_code")
            ?: hourly.optJSONArray("weathercode")
        val n = times.length()
        fun doubles(arr: org.json.JSONArray): List<Double?> =
            (0 until n).map { i ->
                if (arr.isNull(i)) null else arr.optDouble(i, Double.NaN).takeUnless { it.isNaN() }
            }
        fun ints(arr: org.json.JSONArray?): List<Int?> =
            if (arr == null) List(n) { null }
            else (0 until n).map { i -> if (arr.isNull(i)) null else arr.optInt(i) }
        val timeList = (0 until n).map { times.optString(it) }
        return pickClosestHour(
            timesIso = timeList,
            temperatures = doubles(temps),
            humidities = doubles(hums),
            winds = doubles(winds),
            weatherCodes = ints(codes),
            targetEpochMs = targetEpochMs,
            zone = zone
        )
    }

    fun archiveUrl(latitude: Double, longitude: Double, dayIso: String): String {
        val lat = roundCoordinate(latitude)
        val lon = roundCoordinate(longitude)
        return String.format(
            Locale.US,
            "https://archive-api.open-meteo.com/v1/archive" +
                "?latitude=%.2f&longitude=%.2f" +
                "&start_date=%s&end_date=%s" +
                "&hourly=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m" +
                "&wind_speed_unit=kmh&timezone=auto",
            lat, lon, dayIso, dayIso
        )
    }

    fun forecastPastUrl(latitude: Double, longitude: Double, pastDays: Int = 7): String {
        val lat = roundCoordinate(latitude)
        val lon = roundCoordinate(longitude)
        return String.format(
            Locale.US,
            "https://api.open-meteo.com/v1/forecast" +
                "?latitude=%.2f&longitude=%.2f" +
                "&past_days=%d&forecast_days=1" +
                "&hourly=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m" +
                "&wind_speed_unit=kmh&timezone=auto",
            lat, lon, pastDays.coerceIn(1, 92)
        )
    }

    private fun parseHourEpochMs(raw: String, zone: ZoneId): Long? {
        val truncated = raw.take(16)
        return runCatching {
            LocalDateTime.parse(truncated, hourFmt).atZone(zone).toInstant().toEpochMilli()
        }.getOrNull()
    }
}
