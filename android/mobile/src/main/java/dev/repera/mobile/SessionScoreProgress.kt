package dev.repera.mobile

import dev.repera.domain.ProgressDayPoint
import dev.repera.domain.ProgressTimeRange
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.abs
import kotlin.math.roundToInt

/** Verified 1–10 personal-performance evolution for logged training and GPS sports. */
internal object SessionScoreProgress {
    private data class Entry(val json: JSONObject, val day: LocalDate, val finished: Instant)

    fun points(
        state: JSONObject, range: ProgressTimeRange, monday: Boolean,
        now: LocalDate = LocalDate.now(), zone: ZoneId = ZoneId.systemDefault()
    ): List<ProgressDayPoint> {
        val archive = state.optJSONArray("workouts") ?: return emptyList()
        val sessions = (0 until archive.length()).mapNotNull { i ->
            val workout = archive.optJSONObject(i) ?: return@mapNotNull null
            val date = runCatching { Instant.parse(workout.getString("finishedAt")) }.getOrNull()
                ?: return@mapNotNull null
            Entry(workout, date.atZone(zone).toLocalDate(), date)
        }
        val rated = sessions.mapNotNull { session ->
            if (!range.contains(session.day, now, monday)) return@mapNotNull null
            val review = session.json.optJSONObject("sessionReview")
            val persisted = if (review?.optString("scoreBasis") == "personalHistory") {
                review.optDouble("overallScore").takeIf { it.isFinite() && it in 1.0..10.0 }
            } else null
            val score = persisted ?: gpsScore(session, sessions, zone) ?: return@mapNotNull null
            session.day to score
        }
        return rated.groupBy { it.first }.toSortedMap().map { (day, values) ->
            ProgressDayPoint(day, values.map { it.second }.average().roundToInt().toDouble())
        }
    }

    /** Confianza del último entrenamiento realmente puntuable en el periodo.
     * No confundirla con una confianza media inventada de la gráfica. */
    fun latestConfidence(
        state: JSONObject, range: ProgressTimeRange, monday: Boolean,
        now: LocalDate = LocalDate.now(), zone: ZoneId = ZoneId.systemDefault()
    ): String? {
        val archive = state.optJSONArray("workouts") ?: return null
        val sessions = (0 until archive.length()).mapNotNull { i ->
            val workout = archive.optJSONObject(i) ?: return@mapNotNull null
            val end = runCatching { Instant.parse(workout.getString("finishedAt")) }.getOrNull()
                ?: return@mapNotNull null
            Entry(workout, end.atZone(zone).toLocalDate(), end)
        }
        return sessions.filter { range.contains(it.day, now, monday) }
            .mapNotNull { entry ->
                val review = entry.json.optJSONObject("sessionReview")
                val savedScore = if (review?.optString("scoreBasis") == "personalHistory")
                    review.optDouble("overallScore").takeIf { it.isFinite() && it in 1.0..10.0 }
                else null
                when {
                    savedScore != null -> entry.finished to
                        review?.optString("confidenceLabel")
                            ?.takeIf { it.isNotBlank() && it != "null" }
                            .orEmpty().ifBlank { "Media · historial personal" }
                    gpsScore(entry, sessions, zone) != null ->
                        entry.finished to "Media · historial personal"
                    else -> null
                }
            }.maxByOrNull { it.first }?.second
    }

    private fun gpsScore(session: Entry, all: List<Entry>, zone: ZoneId): Double? {
        val current = session.json
        val sport = current.optString("liveSportID").takeIf { it.isNotBlank() && it != "null" }
            ?: return null
        val distance = current.optDouble("recordedDistanceMeters")
        val seconds = current.optDouble("activeDurationSeconds")
        if (!distance.isFinite() || distance < 500 || !seconds.isFinite() || seconds <= 0) return null
        val comparable = all.filter { prior ->
            val other = prior.json
            val meters = other.optDouble("recordedDistanceMeters")
            val duration = other.optDouble("activeDurationSeconds")
            other.optString("liveSportID") == sport && prior.finished < session.finished &&
                prior.finished >= session.finished.minusSeconds(180L * 86_400L) &&
                meters.isFinite() && meters >= 500 && duration.isFinite() && duration > 0 &&
                abs(meters - distance) / distance <= 0.20
        }
        if (comparable.map { it.finished.atZone(zone).toLocalDate() }.distinct().size < 2) return null
        val speeds = comparable.map {
            it.json.optDouble("recordedDistanceMeters") / it.json.optDouble("activeDurationSeconds")
        }.sorted()
        val baseline = speeds[speeds.size / 2]
        if (baseline <= 0) return null
        return (7 + ((distance / seconds) / baseline - 1) * 12)
            .roundToInt().coerceIn(1, 10).toDouble()
    }
}
