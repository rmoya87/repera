package dev.repera.mobile

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.Favorite
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Repeat
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import dev.repera.domain.LiveSport
import dev.repera.domain.ReperaNumberFormat
import dev.repera.domain.TimerCompletionDetails
import org.json.JSONObject
import kotlin.math.roundToInt

/** Spec de tile de cabecera (paridad iOS SessionSummaryTileSpec). */
internal data class SessionSummaryTileSpec(
    val title: String,
    val value: String,
    val icon: ImageVector,
    val tint: Color
)

/**
 * Tres tiles de cabecera según tipo de sesión (Historial + Guardar entreno).
 * Port de `SessionSummaryTilesBuilder` (RegisterSessionChrome.swift).
 *
 * Matriz (paridad iOS):
 * - Timer → Tiempo · Modalidad · Rondas|Kcal
 * - GPS → Tiempo · Distancia · Ritmo|Vel. media
 * - Raqueta/equipo/combate → Tiempo · Kcal · Pasos
 * - Yoga/pilates/movilidad/baile/core → Tiempo · Kcal · FC media
 * - HIIT/CrossFit/HYROX/fuerza Comenzar → Tiempo · Kcal · FC|Pasos
 * - Natación/escalada (+ legacy) → Tiempo · Kcal · Distancia|FC
 * - **Programado sin liveSport** → Tiempo · Marca · Kcal (WOD) | Tiempo · Kcal · Volumen (fuerza)
 * - Fallback indoor → Tiempo · Kcal · FC media
 */
internal object SessionSummaryTilesBuilder {
    private val blue = Color(0xFF0A84FF)
    private val orange = Color(0xFFFF9F0A)
    private val red = Color(0xFFFF453A)
    private val accent = Color(0xFF30D158)

    fun tiles(
        durationLabel: String,
        sport: LiveSport?,
        kcal: Double? = null,
        steps: Int? = null,
        averageHeartRateBpm: Double? = null,
        distanceMeters: Double? = null,
        paceOrSpeedLabel: String? = null,
        timerDetails: TimerCompletionDetails? = null,
        volumeKg: Double? = null,
        scoreSessionJson: String? = null,
        /** Textos de marca ya formateados (WorkoutHistoryEntry.results). */
        displayResults: List<String> = emptyList(),
        /** True si hay bloque WOD/EMOM aunque la marca numérica esté vacía. */
        hasWodBlock: Boolean = false
    ): List<SessionSummaryTileSpec> {
        val kcalValue = kcal?.takeIf { it > 0 }?.let { "${it.roundToInt()}" } ?: "—"
        val stepsValue = steps?.takeIf { it > 0 }?.let { ReperaNumberFormat.integer(it) } ?: "—"
        val hrValue = averageHeartRateBpm?.takeIf { it > 0 }
            ?.let { "${it.roundToInt()}" } ?: "—"
        val distanceValue = formatDistance(distanceMeters)

        timerDetails?.let { timer ->
            val row = mutableListOf(
                SessionSummaryTileSpec("Tiempo", formatTimer(timer.configuredSeconds), Icons.Outlined.AccessTime, blue),
                SessionSummaryTileSpec("Modalidad", timer.modeTitle, Icons.Outlined.Timer, accent)
            )
            if (timer.modeRaw == "intervals") {
                row += SessionSummaryTileSpec("Rondas", "${timer.rounds}", Icons.Outlined.Repeat, orange)
            } else {
                row += SessionSummaryTileSpec("Kcal", kcalValue, Icons.Outlined.LocalFireDepartment, orange)
            }
            return row
        }

        val time = SessionSummaryTileSpec("Tiempo", durationLabel, Icons.Outlined.AccessTime, blue)

        // Entreno programado: sin liveSport (antes que familias Comenzar).
        if (sport == null) {
            return programmedTiles(
                time = time,
                kcalValue = kcalValue,
                volumeKg = volumeKg,
                scoreSessionJson = scoreSessionJson,
                displayResults = displayResults,
                hasWodBlock = hasWodBlock
            )
        }

        if (sport.usesGPS) {
            val thirdTitle = if (sport.showsElevationAndSpeedStats || sport.displaysSpeed) "Vel. media" else "Ritmo"
            return listOf(
                time,
                SessionSummaryTileSpec("Distancia", distanceValue, Icons.Outlined.Route, accent),
                SessionSummaryTileSpec(thirdTitle, paceOrSpeedLabel ?: "—", Icons.Outlined.Speed, blue)
            )
        }

        if (sport.usesStepsKcalSummaryTiles) {
            return listOf(
                time,
                SessionSummaryTileSpec("Kcal", kcalValue, Icons.Outlined.LocalFireDepartment, orange),
                SessionSummaryTileSpec("Pasos", stepsValue, Icons.Outlined.DirectionsWalk, accent)
            )
        }

        if (sport.usesHeartRateSummaryTiles) {
            return listOf(
                time,
                SessionSummaryTileSpec("Kcal", kcalValue, Icons.Outlined.LocalFireDepartment, orange),
                SessionSummaryTileSpec("FC media", hrValue, Icons.Outlined.Favorite, red)
            )
        }

        if (sport.usesFitnessClassSummaryTiles) {
            val third = if (averageHeartRateBpm != null && averageHeartRateBpm > 0) {
                SessionSummaryTileSpec("FC media", hrValue, Icons.Outlined.Favorite, red)
            } else {
                SessionSummaryTileSpec("Pasos", stepsValue, Icons.Outlined.DirectionsWalk, accent)
            }
            return listOf(
                time,
                SessionSummaryTileSpec("Kcal", kcalValue, Icons.Outlined.LocalFireDepartment, orange),
                third
            )
        }

        if (sport == LiveSport.SWIMMING || sport == LiveSport.ELLIPTICAL
            || sport == LiveSport.STAIR_CLIMBING || sport == LiveSport.CLIMBING
        ) {
            val third = if ((distanceMeters ?: 0.0) > 0) {
                SessionSummaryTileSpec("Distancia", distanceValue, Icons.Outlined.Route, accent)
            } else {
                SessionSummaryTileSpec("FC media", hrValue, Icons.Outlined.Favorite, red)
            }
            return listOf(
                time,
                SessionSummaryTileSpec("Kcal", kcalValue, Icons.Outlined.LocalFireDepartment, orange),
                third
            )
        }

        // Fallback indoor / other.
        return listOf(
            time,
            SessionSummaryTileSpec("Kcal", kcalValue, Icons.Outlined.LocalFireDepartment, orange),
            SessionSummaryTileSpec("FC media", hrValue, Icons.Outlined.Favorite, red)
        )
    }

    /** Programado: WOD/EMOM → Tiempo · Marca · Kcal; fuerza → Tiempo · Kcal · Volumen. */
    private fun programmedTiles(
        time: SessionSummaryTileSpec,
        kcalValue: String,
        volumeKg: Double?,
        scoreSessionJson: String?,
        displayResults: List<String>,
        hasWodBlock: Boolean
    ): List<SessionSummaryTileSpec> {
        val mark = compactWodMark(scoreSessionJson)
            ?: compactWodMarkFromDisplayResults(displayResults)
        val isWod = hasWodBlock
            || hasWodResults(scoreSessionJson)
            || hasWodBlockKind(scoreSessionJson)
            || displayResults.isNotEmpty()
            || (mark != null && mark != "—")
        if (isWod) {
            return listOf(
                time,
                SessionSummaryTileSpec("Marca", mark?.takeIf { it != "—" } ?: "—", Icons.Outlined.Flag, accent),
                SessionSummaryTileSpec("Kcal", kcalValue, Icons.Outlined.LocalFireDepartment, orange)
            )
        }
        val volume = (volumeKg?.takeIf { it > 0 }
            ?: volumeKgFromScoreSession(scoreSessionJson))
            ?.takeIf { it > 0 }
            ?.let { ReperaNumberFormat.integer(it.roundToInt()) }
            ?: "—"
        return listOf(
            time,
            SessionSummaryTileSpec("Kcal", kcalValue, Icons.Outlined.LocalFireDepartment, orange),
            SessionSummaryTileSpec("Volumen", volume, Icons.Outlined.FitnessCenter, accent)
        )
    }

    private fun hasWodBlockKind(scoreSessionJson: String?): Boolean {
        val ex = runCatching {
            JSONObject(scoreSessionJson ?: return false).optJSONArray("exercises")
        }.getOrNull() ?: return false
        for (i in 0 until ex.length()) {
            if (ex.optJSONObject(i)?.optString("blockKind") == "wod") return true
        }
        return false
    }

    /** Marca corta para el tile: `12:34`, `150`, `3+45`. */
    fun compactWodMark(scoreSessionJson: String?): String? {
        val raw = scoreSessionJson?.takeIf { it.isNotBlank() } ?: return null
        val arr = runCatching { JSONObject(raw).optJSONArray("wodResults") }.getOrNull()
            ?: return null
        if (arr.length() == 0) return null
        val score = arr.optJSONObject(0) ?: return null
        return compactMarkFromScoreObject(score)
    }

    fun compactWodMarkFromDisplayResults(results: List<String>): String? {
        val first = results.firstOrNull { it.isNotBlank() } ?: return null
        // "For Time · 12:34" / "AMRAP · 3 rondas + 45 reps" / "… · 150"
        val afterDot = first.substringAfter("·", missingDelimiterValue = first).trim()
        Regex("""^(\d+):(\d{2})$""").find(afterDot)?.let { m ->
            return "%d:%02d".format(m.groupValues[1].toInt(), m.groupValues[2].toInt())
        }
        Regex("""(\d+)\s*rondas?\s*\+\s*(\d+)""", RegexOption.IGNORE_CASE).find(afterDot)?.let { m ->
            return "${m.groupValues[1]}+${m.groupValues[2]}"
        }
        Regex("""(\d+)\s*rondas?""", RegexOption.IGNORE_CASE).find(afterDot)?.let { m ->
            return m.groupValues[1]
        }
        Regex("""(\d+)\s*reps?""", RegexOption.IGNORE_CASE).find(afterDot)?.let { m ->
            return m.groupValues[1]
        }
        if (afterDot.all { it.isDigit() }) return afterDot
        return null
    }

    private fun compactMarkFromScoreObject(score: JSONObject): String? {
        if (score.has("elapsedSeconds") && !score.isNull("elapsedSeconds")) {
            val elapsed = score.optDouble("elapsedSeconds", Double.NaN)
                .takeIf { it.isFinite() }?.roundToInt()
                ?: score.optInt("elapsedSeconds", -1).takeIf { it >= 0 }
            if (elapsed != null && elapsed >= 0) {
                return "%d:%02d".format(elapsed / 60, elapsed % 60)
            }
        }
        if (score.has("totalReps") && !score.isNull("totalReps")) {
            val reps = score.optInt("totalReps")
            if (score.has("roundsCompleted") && !score.isNull("roundsCompleted")) {
                return "${score.optInt("roundsCompleted")}+$reps"
            }
            return "$reps"
        }
        if (score.has("roundsCompleted") && !score.isNull("roundsCompleted")) {
            return "${score.optInt("roundsCompleted")}"
        }
        return null
    }

    private fun hasWodResults(scoreSessionJson: String?): Boolean {
        val arr = runCatching {
            JSONObject(scoreSessionJson ?: return false).optJSONArray("wodResults")
        }.getOrNull() ?: return false
        return arr.length() > 0
    }

    /** Volumen kg ≈ suma weight×reps de series work (scoreSessionJson). */
    fun volumeKgFromScoreSession(scoreSessionJson: String?): Double? {
        val root = runCatching { JSONObject(scoreSessionJson ?: return null) }.getOrNull()
            ?: return null
        val ex = root.optJSONArray("exercises") ?: return null
        var total = 0.0
        for (i in 0 until ex.length()) {
            val logged = ex.optJSONObject(i)?.optJSONArray("loggedSets") ?: continue
            for (j in 0 until logged.length()) {
                val set = logged.optJSONObject(j) ?: continue
                if (set.optString("phase", "work") != "work") continue
                if (set.optBoolean("isWarmup", false)) continue
                val reps = set.optInt("reps", 0)
                val weight = set.optDouble("weightKg", Double.NaN)
                if (reps > 0 && weight.isFinite() && weight > 0) {
                    total += weight * reps
                }
            }
        }
        return total.takeIf { it > 0 }
    }

    private fun formatDistance(meters: Double?): String {
        val m = meters?.takeIf { it > 0 } ?: return "—"
        return if (m >= 1000) "${ReperaNumberFormat.decimal(m / 1000)} km"
        else "${m.roundToInt()} m"
    }

    private fun formatTimer(seconds: Int): String {
        val s = seconds.coerceAtLeast(0)
        val h = s / 3600
        val m = (s % 3600) / 60
        val sec = s % 60
        return if (h > 0) "%d:%02d:%02d".format(h, m, sec) else "%d:%02d".format(m, sec)
    }

    fun paceOrSpeedLabel(
        sport: LiveSport?,
        distanceMeters: Double?,
        activeSeconds: Double?
    ): String? {
        if (sport?.usesGPS != true) return null
        val meters = distanceMeters?.takeIf { it > 0 } ?: return null
        val seconds = activeSeconds?.takeIf { it > 0 } ?: return null
        return if (sport.showsElevationAndSpeedStats || sport.displaysSpeed) {
            ReperaNumberFormat.decimal(meters / seconds * 3.6)
        } else {
            val secPerKm = (seconds / (meters / 1000.0)).roundToInt()
            "%d:%02d".format(secPerKm / 60, secPerKm % 60)
        }
    }
}
