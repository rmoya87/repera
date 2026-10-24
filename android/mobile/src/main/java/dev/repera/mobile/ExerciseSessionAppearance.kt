package dev.repera.mobile

import dev.repera.domain.ExerciseEquivalence
import dev.repera.domain.SetSummaryLine
import dev.repera.domain.WodFormat
import dev.repera.domain.ResultCapture
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

/**
 * Cómo apareció un ejercicio / WOD en un entreno concreto.
 * Port 1:1 de ExerciseSessionAppearance.swift (iOS) sobre el snapshot JSON;
 * presentación pura, nunca escribe en el estado.
 */
data class SessionAppearance(
    val sessionId: String,
    val dateEpochMillis: Long,
    val sessionTitle: String,
    val setLines: List<String> = emptyList(),
    val prescriptionLine: String? = null,
    val wodScoreLabel: String? = null,
    val wodFormatName: String? = null,
    val wodTemplateId: String? = null,
    val wodTemplateName: String? = null,
    val isGlobalWodScore: Boolean = false
) {
    val hasContent: Boolean
        get() = setLines.isNotEmpty() || prescriptionLine != null || wodScoreLabel != null
}

object ExerciseSessionAppearances {

    private fun epochOf(session: JSONObject): Long {
        val raw = session.optString("finishedAt").takeIf { it.isNotBlank() }
            ?: session.optString("startedAt").takeIf { it.isNotBlank() }
            ?: return 0L
        return runCatching { Instant.parse(raw).toEpochMilli() }.getOrDefault(0L)
    }

    private fun matchEntry(session: JSONObject, exerciseId: String,
                           anchorName: String?): JSONObject? {
        val exercises = session.optJSONArray("exercises") ?: return null
        return (0 until exercises.length())
            .map { exercises.getJSONObject(it) }
            .firstOrNull { entry ->
                val ex = entry.optJSONObject("exercise")
                val entryId = ex?.optString("id") ?: entry.optString("exerciseId")
                if (entryId == exerciseId) return@firstOrNull true
                val name = ex?.optString("name") ?: return@firstOrNull false
                anchorName != null && ExerciseEquivalence.sameName(name, anchorName)
            }
    }

    private fun entryExerciseId(entry: JSONObject): String =
        entry.optJSONObject("exercise")?.optString("id")
            ?: entry.optString("exerciseId")

    private fun entryName(entry: JSONObject): String =
        entry.optJSONObject("exercise")?.optString("name") ?: ""

    /** summaryLabel de WODBlockResult (Models.swift iOS). */
    fun wodScoreSummaryLabel(score: JSONObject): String {
        if (score.has("elapsedSeconds") && !score.isNull("elapsedSeconds")) {
            val total = score.getInt("elapsedSeconds")
            return "%d:%02d".format(total / 60, total % 60)
        }
        if (score.has("totalReps") && !score.isNull("totalReps")) {
            if (score.has("roundsCompleted") && !score.isNull("roundsCompleted")) {
                return "${score.getInt("roundsCompleted")} rondas + " +
                    "${score.getInt("totalReps")} reps"
            }
            return "${score.getInt("totalReps")} reps"
        }
        if (score.has("roundsCompleted") && !score.isNull("roundsCompleted")) {
            return "${score.getInt("roundsCompleted")} rondas"
        }
        return "—"
    }

    private fun formatDisplayName(wire: String?): String? =
        wire?.takeIf { it.isNotBlank() }?.let { WodFormat.fromWire(it)?.displayName }

    private fun usesBlockScoreResult(entry: JSONObject): Boolean {
        val wire = entry.optString("wodFormat").takeIf { it.isNotBlank() }
            ?: return false
        val format = WodFormat.fromWire(wire) ?: return false
        return format.capture == ResultCapture.TOTAL_REPS ||
            format.capture == ResultCapture.ELAPSED_TIME
    }

    /** Aparición del ejercicio en una sesión (id / nombre). Si el bloque es un
     *  WOD de catálogo (wodTemplateId), la marca es la del WOD global. */
    fun appearance(
        exerciseId: String,
        session: JSONObject,
        catalog: JSONArray? = null
    ): SessionAppearance? {
        // Ancla por catálogo (id → nombre canónico) o por el propio historial.
        var anchorName: String? = catalog?.let { array ->
            (0 until array.length()).map { array.getJSONObject(it) }
                .firstOrNull { it.optString("id") == exerciseId }?.optString("name")
        }
        var entry = matchEntry(session, exerciseId, anchorName)
        if (entry == null && anchorName == null) {
            // Sin catálogo: el nombre puede venir de cualquier sesión (iOS busca
            // en workouts); aquí lo intenta con el propio historial recibido.
            anchorName = null
        }
        if (entry == null) return null
        val date = epochOf(session)
        val results = session.optJSONArray("wodResults") ?: JSONArray()
        val blockResult: JSONObject? = entry.optString("blockId")
            .takeIf { it.isNotBlank() }
            ?.let { blockId ->
                (0 until results.length()).map { results.getJSONObject(it) }
                    .firstOrNull { it.optString("id") == blockId }
            }
        val templateId = blockResult?.optString("wodTemplateId")?.takeIf { it.isNotBlank() }
            ?: (0 until results.length()).map { results.getJSONObject(it) }
                .firstOrNull { it.optString("wodTemplateId").isNotBlank() }
                ?.optString("wodTemplateId")

        // WOD predeterminado → comparar el score global del benchmark.
        if (templateId != null) {
            val result = blockResult
                ?: (0 until results.length()).map { results.getJSONObject(it) }
                    .firstOrNull { it.optString("wodTemplateId") == templateId }
            if (result != null) {
                val score = wodScoreSummaryLabel(result)
                if (score == "—") return null
                val title = session.optString("title")
                return SessionAppearance(
                    sessionId = session.optString("id"),
                    dateEpochMillis = date,
                    sessionTitle = title,
                    wodScoreLabel = score,
                    wodFormatName = formatDisplayName(
                        result.optString("format").takeIf { it.isNotBlank() }
                            ?: entry.optString("wodFormat")),
                    wodTemplateId = templateId,
                    // Sin catálogo de templates en Android: nombre del WOD =
                    // título de la sesión (fallback idéntico a iOS sin template).
                    wodTemplateName = title,
                    isGlobalWodScore = true
                )
            }
        }

        val work = WorkoutHistorySets.effectiveWorkSets(session, entry)
        val setLines = work.map { set ->
            SetSummaryLine.displayLine(
                reps = set.reps,
                quantityUnit = set.unit,
                weightKg = set.weightKg,
                durationSeconds = set.durationSeconds
            )
        }
        var scoreLabel: String? = null
        var formatName: String? = null
        if (blockResult != null) {
            scoreLabel = wodScoreSummaryLabel(blockResult)
            formatName = formatDisplayName(
                blockResult.optString("format").takeIf { it.isNotBlank() }
                    ?: entry.optString("wodFormat"))
        } else if (usesBlockScoreResult(entry)) {
            formatName = formatDisplayName(entry.optString("wodFormat"))
        }
        val name = entryName(entry)
        val prescription: String? = if (setLines.isNotEmpty()) null else {
            val planned = entry.optJSONArray("plannedSets")
            val first = planned?.takeIf { it.length() > 0 }?.getJSONObject(0)
            val line = SetSummaryLine.prescriptionLine(
                targetReps = first?.optInt("targetReps"),
                targetWeightKg = first?.let {
                    if (it.has("targetWeightKg") && !it.isNull("targetWeightKg"))
                        it.getDouble("targetWeightKg") else null
                },
                exerciseName = name
            )
            if (line == name) null else line
        }
        val appearance = SessionAppearance(
            sessionId = session.optString("id"),
            dateEpochMillis = date,
            sessionTitle = session.optString("title"),
            setLines = setLines,
            prescriptionLine = prescription,
            wodScoreLabel = scoreLabel,
            wodFormatName = formatName,
            isGlobalWodScore = false
        )
        return if (appearance.hasContent) appearance else null
    }

    /** Marca global de un WOD de catálogo en una sesión (iOS wodTemplateAppearance). */
    fun wodTemplateAppearance(templateId: String, session: JSONObject): SessionAppearance? {
        val results = session.optJSONArray("wodResults") ?: return null
        val result = (0 until results.length()).map { results.getJSONObject(it) }
            .firstOrNull { it.optString("wodTemplateId") == templateId } ?: return null
        val score = wodScoreSummaryLabel(result)
        if (score == "—") return null
        val title = session.optString("title")
        return SessionAppearance(
            sessionId = session.optString("id"),
            dateEpochMillis = epochOf(session),
            sessionTitle = title,
            wodScoreLabel = score,
            wodFormatName = formatDisplayName(result.optString("format")),
            wodTemplateId = templateId,
            wodTemplateName = title,
            isGlobalWodScore = true
        )
    }

    /** Apariciones previas: mismo WOD de catálogo si la destacada es benchmark,
     *  o el mismo movimiento en otro caso (iOS priorAppearances, límite 5). */
    fun priorAppearances(
        exerciseId: String,
        workouts: List<JSONObject>,
        catalog: JSONArray? = null,
        excludingSessionId: String? = null,
        limit: Int = 5
    ): List<SessionAppearance> {
        val sorted = workouts.sortedByDescending { epochOf(it) }
        val highlightTemplateId: String? = excludingSessionId?.let { excl ->
            val session = workouts.firstOrNull { it.optString("id") == excl }
            session?.let {
                appearance(exerciseId, it, catalog)
                    ?.takeIf { row -> row.isGlobalWodScore }?.wodTemplateId
            }
        }
        val rows = mutableListOf<SessionAppearance>()
        for (session in sorted) {
            if (excludingSessionId != null &&
                session.optString("id") == excludingSessionId) continue
            val finished = session.optString("phase") == "finished" ||
                session.optString("finishedAt").isNotBlank()
            if (!finished) continue
            val row = if (highlightTemplateId != null) {
                wodTemplateAppearance(highlightTemplateId, session) ?: continue
            } else {
                val r = appearance(exerciseId, session, catalog) ?: continue
                if (r.isGlobalWodScore) continue
                r
            }
            rows.add(row)
            if (rows.size >= limit) break
        }
        return rows
    }
}
