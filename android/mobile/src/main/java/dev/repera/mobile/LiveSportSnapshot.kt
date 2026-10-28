package dev.repera.mobile

import dev.repera.domain.LiveSportHistory
import org.json.JSONObject
import java.time.Instant

/** Archivo completo de actividades terminadas, igual que LiveSportsCatalogView.
 * No depende del límite de 20 tarjetas recientes ni fabrica datos de Salud. */
internal object LiveSportSnapshot {
    fun sessions(state: JSONObject): List<LiveSportHistory.LiveSession> {
        val array = state.optJSONArray("workouts") ?: return emptyList()
        return (0 until array.length()).mapNotNull { i ->
            val s = array.optJSONObject(i) ?: return@mapNotNull null
            val sport = s.optString("liveSportID").takeIf { it.isNotBlank() && it != "null" }
                ?: return@mapNotNull null
            if (s.optString("phase") != "finished" || s.isNull("finishedAt")) return@mapNotNull null
            fun epoch(key: String): Long? = runCatching { Instant.parse(s.getString(key)).toEpochMilli() }.getOrNull()
            fun measured(key: String): Double? = if (s.isNull(key)) null
                else s.optDouble(key, Double.NaN).takeIf { it.isFinite() }
            val finished = epoch("finishedAt") ?: return@mapNotNull null
            LiveSportHistory.LiveSession(
                id = s.optString("id"), title = s.optString("title"), sportID = sport,
                startedEpochMillis = epoch("startedAt"), finishedEpochMillis = finished,
                activeDurationSeconds = measured("activeDurationSeconds"),
                recordedDistanceMeters = measured("recordedDistanceMeters"),
                averageHeartRateBpm = measured("appleAverageHeartRateBpm"),
                activeEnergyKcal = measured("appleActiveEnergyKcal"),
                liveRouteID = s.optString("liveRouteID").takeIf { it.isNotBlank() && it != "null" },
                liveKilometerSplitsSeconds = s.optJSONArray("liveKilometerSplitsSeconds")?.let { a ->
                    (0 until a.length()).map { a.optDouble(it, Double.NaN) }.filter { it.isFinite() && it > 0 }
                }.orEmpty())
        }
    }
}
