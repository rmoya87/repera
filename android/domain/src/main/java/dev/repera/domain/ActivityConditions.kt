package dev.repera.domain

import org.json.JSONObject
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.math.abs

enum class ActivityConditionsFamily { WATER, SNOW, OUTDOOR, NONE }

enum class TideTrend { RISING, FALLING, SLACK }

/** Snapshot Open-Meteo (gratis) de marea/nieve; orientativo. */
data class ActivityConditionsSnapshot(
    val family: ActivityConditionsFamily,
    val capturedAtEpochMs: Long,
    val temperatureC: Double? = null,
    val windKmh: Double? = null,
    val tideHeightMeters: Double? = null,
    val tideTrend: TideTrend? = null,
    val nextTideLabel: String? = null,
    val waveHeightMeters: Double? = null,
    val snowfallCm: Double? = null,
    val snowDepthMeters: Double? = null,
    val attribution: String = "Open-Meteo",
    val disclaimer: String? = null
) {
    val tideTrendLabel: String?
        get() = when (tideTrend) {
            TideTrend.RISING -> "Subiendo"
            TideTrend.FALLING -> "Bajando"
            TideTrend.SLACK -> "Estable"
            null -> null
        }

    fun toJson(): JSONObject = JSONObject()
        .put("family", family.name.lowercase())
        .put("capturedAtEpochMs", capturedAtEpochMs)
        .putOpt("temperatureC", temperatureC)
        .putOpt("windKmh", windKmh)
        .putOpt("tideHeightMeters", tideHeightMeters)
        .putOpt("tideTrend", tideTrend?.name?.lowercase())
        .putOpt("nextTideLabel", nextTideLabel)
        .putOpt("waveHeightMeters", waveHeightMeters)
        .putOpt("snowfallCm", snowfallCm)
        .putOpt("snowDepthMeters", snowDepthMeters)
        .put("attribution", attribution)
        .putOpt("disclaimer", disclaimer)

    companion object {
        fun familyForLiveSportId(id: String?): ActivityConditionsFamily {
            if (id.isNullOrBlank() || id == "companion") return ActivityConditionsFamily.NONE
            return when (id) {
                "surfing", "windsurfing", "kitesurfing", "kayaking", "rowing",
                "canoeing", "sailing", "swimming" -> ActivityConditionsFamily.WATER
                "skiing", "snowboarding", "crossCountrySkiing" -> ActivityConditionsFamily.SNOW
                "running", "trail", "walking", "hiking", "cycling", "mountainBike",
                "gravel", "skateboarding", "golf" -> ActivityConditionsFamily.OUTDOOR
                else -> ActivityConditionsFamily.NONE
            }
        }

        fun fromJson(o: JSONObject?): ActivityConditionsSnapshot? {
            if (o == null) return null
            val family = runCatching {
                ActivityConditionsFamily.valueOf(o.optString("family").uppercase())
            }.getOrDefault(ActivityConditionsFamily.NONE)
            if (family == ActivityConditionsFamily.NONE && !o.has("temperatureC")) return null
            return ActivityConditionsSnapshot(
                family = family,
                capturedAtEpochMs = o.optLong("capturedAtEpochMs", System.currentTimeMillis()),
                temperatureC = o.optDoubleOrNull("temperatureC"),
                windKmh = o.optDoubleOrNull("windKmh"),
                tideHeightMeters = o.optDoubleOrNull("tideHeightMeters"),
                tideTrend = o.optString("tideTrend").takeIf { it.isNotBlank() }?.let {
                    runCatching { TideTrend.valueOf(it.uppercase()) }.getOrNull()
                },
                nextTideLabel = o.optString("nextTideLabel").takeIf { it.isNotBlank() },
                waveHeightMeters = o.optDoubleOrNull("waveHeightMeters"),
                snowfallCm = o.optDoubleOrNull("snowfallCm"),
                snowDepthMeters = o.optDoubleOrNull("snowDepthMeters"),
                attribution = o.optString("attribution").ifBlank { "Open-Meteo" },
                disclaimer = o.optString("disclaimer").takeIf { it.isNotBlank() }
            )
        }

        private fun JSONObject.optDoubleOrNull(key: String): Double? =
            if (!has(key) || isNull(key)) null else optDouble(key).takeIf { it.isFinite() }
    }
}

object ActivityConditionsLogic {
    private val hourFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")

    fun roundCoordinate(value: Double): Double =
        kotlin.math.round(value * 100.0) / 100.0

    fun forecastUrl(lat: Double, lon: Double): String {
        val la = roundCoordinate(lat)
        val lo = roundCoordinate(lon)
        return "https://api.open-meteo.com/v1/forecast?latitude=$la&longitude=$lo" +
            "&hourly=temperature_2m,wind_speed_10m,snowfall,snow_depth" +
            "&forecast_days=2&timezone=auto&wind_speed_unit=kmh"
    }

    fun marineUrl(lat: Double, lon: Double): String {
        val la = roundCoordinate(lat)
        val lo = roundCoordinate(lon)
        return "https://marine-api.open-meteo.com/v1/marine?latitude=$la&longitude=$lo" +
            "&hourly=sea_level_height_msl,wave_height&forecast_days=2&timezone=auto"
    }

    fun parse(
        family: ActivityConditionsFamily,
        forecastBody: String?,
        marineBody: String?,
        atEpochMs: Long,
        zone: ZoneId = ZoneId.systemDefault()
    ): ActivityConditionsSnapshot? {
        if (family == ActivityConditionsFamily.NONE) return null
        var temp: Double? = null
        var wind: Double? = null
        var snow: Double? = null
        var depth: Double? = null
        forecastBody?.let { body ->
            val hourly = JSONObject(body).optJSONObject("hourly") ?: return@let
            val times = hourly.optJSONArray("time") ?: return@let
            val idx = closestIndex(times, atEpochMs, zone) ?: return@let
            temp = hourly.optJSONArray("temperature_2m")?.optDoubleOrNull(idx)
            wind = hourly.optJSONArray("wind_speed_10m")?.optDoubleOrNull(idx)
                ?: hourly.optJSONArray("windspeed_10m")?.optDoubleOrNull(idx)
            if (family == ActivityConditionsFamily.SNOW) {
                snow = hourly.optJSONArray("snowfall")?.optDoubleOrNull(idx)
                depth = hourly.optJSONArray("snow_depth")?.optDoubleOrNull(idx)
            }
        }
        var tide: Double? = null
        var trend: TideTrend? = null
        var nextLabel: String? = null
        var wave: Double? = null
        if (family == ActivityConditionsFamily.WATER && marineBody != null) {
            val hourly = JSONObject(marineBody).optJSONObject("hourly")
            val times = hourly?.optJSONArray("time")
            if (hourly != null && times != null) {
                val levels = doubles(hourly.optJSONArray("sea_level_height_msl"))
                val waves = doubles(hourly.optJSONArray("wave_height"))
                val idx = closestIndex(times, atEpochMs, zone)
                if (idx != null) {
                    tide = levels.getOrNull(idx)
                    wave = waves.getOrNull(idx)
                    val prev = if (idx > 0) levels.getOrNull(idx - 1) else null
                    if (tide != null && prev != null) {
                        val d = tide - prev
                        trend = when {
                            abs(d) < 0.02 -> TideTrend.SLACK
                            d > 0 -> TideTrend.RISING
                            else -> TideTrend.FALLING
                        }
                    }
                    nextLabel = nextExtremum(levels, times, idx)
                }
            }
        }
        val hasAny = temp != null || wind != null || tide != null || wave != null ||
            snow != null || depth != null
        if (!hasAny) return null
        return ActivityConditionsSnapshot(
            family = family,
            capturedAtEpochMs = atEpochMs,
            temperatureC = temp,
            windKmh = wind,
            tideHeightMeters = tide,
            tideTrend = trend,
            nextTideLabel = nextLabel,
            waveHeightMeters = wave,
            snowfallCm = snow,
            snowDepthMeters = depth,
            disclaimer = if (family == ActivityConditionsFamily.WATER)
                "No usar para navegar" else null
        )
    }

    private fun closestIndex(
        times: org.json.JSONArray,
        targetMs: Long,
        zone: ZoneId
    ): Int? {
        var best = -1
        var bestDelta = Long.MAX_VALUE
        for (i in 0 until times.length()) {
            val raw = times.optString(i)
            val trimmed = if (raw.length >= 16) raw.substring(0, 16) else raw
            val epoch = runCatching {
                LocalDateTime.parse(trimmed, hourFmt).atZone(zone).toInstant().toEpochMilli()
            }.getOrNull() ?: continue
            val d = abs(epoch - targetMs)
            if (d < bestDelta) {
                bestDelta = d
                best = i
            }
        }
        return best.takeIf { it >= 0 && bestDelta <= 3L * 3600_000L }
    }

    private fun doubles(arr: org.json.JSONArray?): List<Double?> {
        if (arr == null) return emptyList()
        return (0 until arr.length()).map { i ->
            if (arr.isNull(i)) null else arr.optDouble(i).takeIf { it.isFinite() }
        }
    }

    private fun org.json.JSONArray.optDoubleOrNull(i: Int): Double? =
        if (isNull(i)) null else optDouble(i).takeIf { it.isFinite() }

    private fun nextExtremum(
        levels: List<Double?>,
        times: org.json.JSONArray,
        from: Int
    ): String? {
        var i = from + 1
        while (i + 1 < levels.size) {
            val a = levels[i - 1]
            val b = levels[i]
            val c = levels[i + 1]
            if (a == null || b == null || c == null) {
                i++
                continue
            }
            val isMax = b >= a && b >= c
            val isMin = b <= a && b <= c
            if (isMax || isMin) {
                val kind = if (isMax) "Pleamar" else "Bajamar"
                val clock = times.optString(i).takeLast(5)
                return "$kind ~$clock"
            }
            i++
        }
        return null
    }
}
