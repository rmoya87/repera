package dev.repera.mobile

import dev.repera.domain.ProgressDayPoint
import dev.repera.domain.ProgressTimeRange
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.abs
import kotlin.math.roundToInt

/** Glance de esfuerzo de la última sesión verificada del periodo. */
data class SessionScoreEffortGlance(
    val relativeChangePercent: Int?,
    val coveragePercent: Int?,
    val referenceDays: Int?
)

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
                            ?.takeIf { it.isNotBlank() && it != "null" && it != "En construcción" }
                            .orEmpty().ifBlank { "Media · historial personal" }
                    gpsScore(entry, sessions, zone) != null ->
                        entry.finished to "Media · historial personal"
                    else -> null
                }
            }.maxByOrNull { it.first }?.second
    }

    /** Esfuerzo de la última sesión con nota personal en el periodo. */
    fun latestEffort(
        state: JSONObject, range: ProgressTimeRange, monday: Boolean,
        now: LocalDate = LocalDate.now(), zone: ZoneId = ZoneId.systemDefault()
    ): SessionScoreEffortGlance? {
        val archive = state.optJSONArray("workouts") ?: return null
        val sessions = (0 until archive.length()).mapNotNull { i ->
            val workout = archive.optJSONObject(i) ?: return@mapNotNull null
            if (workout.optJSONObject("timerDetails") != null) return@mapNotNull null
            val end = runCatching { Instant.parse(workout.getString("finishedAt")) }.getOrNull()
                ?: return@mapNotNull null
            Entry(workout, end.atZone(zone).toLocalDate(), end)
        }
        data class Rated(val finished: Instant, val entry: Entry, val review: JSONObject?, val score: Double)
        val latest = sessions.filter { range.contains(it.day, now, monday) }
            .mapNotNull { entry ->
                val review = entry.json.optJSONObject("sessionReview")
                if (review?.optString("scoreBasis") == "personalHistory") {
                    val score = review.optDouble("overallScore")
                        .takeIf { it.isFinite() && it in 1.0..10.0 } ?: return@mapNotNull null
                    Rated(entry.finished, entry, review, score)
                } else {
                    val score = gpsScore(entry, sessions, zone) ?: return@mapNotNull null
                    Rated(entry.finished, entry, null, score)
                }
            }.maxByOrNull { it.finished } ?: return null

        val live = latest.entry.json.optString("liveSportID").isNotBlank() &&
            latest.entry.json.optString("liveSportID") != "null"
        val review = latest.review
        if (review != null) {
            val relative = when {
                review.has("relativeChangePercent") && !review.isNull("relativeChangePercent") ->
                    review.getInt("relativeChangePercent")
                else -> inferredRelativeChange(latest.score.roundToInt(), live)
            }
            val coverage = when {
                review.has("evidenceCoverage") && !review.isNull("evidenceCoverage") ->
                    (review.getDouble("evidenceCoverage") * 100).roundToInt()
                live -> 100
                else -> null
            }
            val references = when {
                review.has("referenceDays") && !review.isNull("referenceDays") ->
                    review.getInt("referenceDays").takeIf { it > 0 }
                else -> {
                    val indicators = review.optJSONArray("indicators")
                    if (indicators == null || indicators.length() == 0) null
                    else (0 until indicators.length()).mapNotNull { i ->
                        val ind = indicators.optJSONObject(i) ?: return@mapNotNull null
                        if (!ind.has("score") || ind.isNull("score")) return@mapNotNull null
                        ind.optInt("referenceSessions").takeIf { it > 0 }
                    }.minOrNull()
                }
            } ?: if (live) gpsReferenceDays(latest.entry, sessions, zone) else null
            return SessionScoreEffortGlance(relative, coverage, references)
        }
        val gps = gpsEffort(latest.entry, sessions, zone) ?: return SessionScoreEffortGlance(
            inferredRelativeChange(latest.score.roundToInt(), liveSport = true),
            100,
            null
        )
        return gps
    }

    private fun inferredRelativeChange(score: Int, liveSport: Boolean): Int =
        if (liveSport) ((score - 7) / 12.0 * 100).roundToInt()
        else {
            val ratio = kotlin.math.exp((score - 7) / 11.0)
            ((ratio - 1) * 100).roundToInt()
        }

    private fun gpsComparable(session: Entry, all: List<Entry>, zone: ZoneId): List<Entry>? {
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
        return comparable
    }

    private fun gpsReferenceDays(session: Entry, all: List<Entry>, zone: ZoneId): Int? =
        gpsComparable(session, all, zone)
            ?.map { it.finished.atZone(zone).toLocalDate() }
            ?.distinct()
            ?.size

    private fun gpsEffort(
        session: Entry, all: List<Entry>, zone: ZoneId
    ): SessionScoreEffortGlance? {
        val comparable = gpsComparable(session, all, zone) ?: return null
        val distance = session.json.optDouble("recordedDistanceMeters")
        val seconds = session.json.optDouble("activeDurationSeconds")
        val speeds = comparable.map {
            it.json.optDouble("recordedDistanceMeters") / it.json.optDouble("activeDurationSeconds")
        }.sorted()
        val baseline = speeds[speeds.size / 2]
        if (baseline <= 0) return null
        val relativePace = (distance / seconds) / baseline
        val days = comparable.map { it.finished.atZone(zone).toLocalDate() }.distinct().size
        return SessionScoreEffortGlance(
            relativeChangePercent = ((relativePace - 1) * 100).roundToInt(),
            coveragePercent = 100,
            referenceDays = days
        )
    }

    private fun gpsScore(session: Entry, all: List<Entry>, zone: ZoneId): Double? {
        val comparable = gpsComparable(session, all, zone) ?: return null
        val distance = session.json.optDouble("recordedDistanceMeters")
        val seconds = session.json.optDouble("activeDurationSeconds")
        val speeds = comparable.map {
            it.json.optDouble("recordedDistanceMeters") / it.json.optDouble("activeDurationSeconds")
        }.sorted()
        val baseline = speeds[speeds.size / 2]
        if (baseline <= 0) return null
        return (7 + ((distance / seconds) / baseline - 1) * 12)
            .roundToInt().coerceIn(1, 10).toDouble()
    }
}
