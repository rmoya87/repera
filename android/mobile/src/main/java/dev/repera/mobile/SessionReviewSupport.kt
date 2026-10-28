package dev.repera.mobile

import dev.repera.domain.SessionReview
import dev.repera.domain.VerifiedSessionReviewEngine
import org.json.JSONObject

/**
 * Port del cableado iOS (ReperaStore.attachSessionReview /
 * ensureSessionReview / refreshSessionReviewsIfNeeded): la nota se calcula al
 * terminar la sesión con TODO el historial, se persiste dentro de la sesión
 * (clave "sessionReview", wire Codable iOS) y se recalcula al subir la versión
 * de la fórmula.
 */
object SessionReviewSupport {
    /** Versión de la fórmula de Resultado; al subir, se recalculan todas las notas. */
    const val FORMULA_VERSION = 11
    const val PREFS_VERSION_KEY = "sessionReviewFormulaVersion"
    const val PREFS_PENDING_KEY = "pendingReviewSessionId"

    /** Calcula y persiste la valoración al terminar (attachSessionReview iOS). */
    fun attachToFinishedSession(state: JSONObject, session: JSONObject): SessionReview? {
        val model = SessionReviewJson.sessionToModel(session)
        val archive = state.optJSONArray("workouts")
        val history = buildList {
            if (archive != null) {
                for (i in 0 until archive.length()) {
                    val other = archive.optJSONObject(i) ?: continue
                    if (other.optString("id") != session.optString("id"))
                        add(SessionReviewJson.sessionToModel(other))
                }
            }
        }
        val review = VerifiedSessionReviewEngine.review(model, history)
        if (review != null) {
            session.put("sessionReview", SessionReviewJson.toJson(review))
        } else {
            session.remove("sessionReview")
        }
        return review
    }

    /** Afina la nota de una sesión terminada con la muestra de Salud
     *  (refreshSessionReviewWithCardio iOS). Persiste dentro de la sesión y
     *  devuelve la nota actualizada, o null si no hay nota o no cambió. */
    fun refineWithCardio(state: JSONObject, sessionId: String,
                         sample: dev.repera.domain.SessionCardioSample): SessionReview? {
        val archive = state.optJSONArray("workouts") ?: return null
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") != sessionId) continue
            val current = session.optJSONObject("sessionReview")
                ?.let { SessionReviewJson.fromJson(it) } ?: return null
            val updated = dev.repera.domain.SessionCardioEffort.apply(current, sample)
            if (updated == current) return null
            session.put("sessionReview", SessionReviewJson.toJson(updated))
            return updated
        }
        return null
    }

    /** Apple finishWorkout stores the HealthKit active energy on the saved session.
     *  Here the value is only the sample read from the reliably associated Health
     *  Connect session (readSessionSample), written once and never overwritten or
     *  fabricated from time/load. Returns true when the session changed. */
    fun applyMeasuredEnergy(state: JSONObject, sessionId: String, kcal: Double?, sourceRecordId: String?): Boolean {
        if (sourceRecordId.isNullOrBlank()) return false
        if (kcal == null || !kcal.isFinite() || kcal <= 0.0) return false
        val archive = state.optJSONArray("workouts") ?: return false
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            if (session.optString("id") != sessionId) continue
            if (session.has("appleActiveEnergyKcal") && !session.isNull("appleActiveEnergyKcal")) return false
            // The matcher compares one local session with Health candidates only; it does
            // not prove that no other local session matched the same record. Skip rather
            // than risk counting the same energy twice: no times or any time overlap
            // with another saved workout means no write.
            val range = instantRange(session) ?: return false
            for (j in 0 until archive.length()) {
                if (j == i) continue
                val other = archive.optJSONObject(j) ?: continue
                val o = instantRange(other) ?: continue
                if (o.first < range.second && range.first < o.second) return false
            }
            // Another local workout already linked to the same Health record: ambiguous.
            for (j in 0 until archive.length()) {
                if (j == i) continue
                val link = archive.optJSONObject(j)?.optString(dev.repera.domain.HealthSessionLink.SNAPSHOT_FIELD)
                if (link == sourceRecordId) return false
            }
            session.put("appleActiveEnergyKcal", kcal)
            return true
        }
        return false
    }

    private fun instantRange(session: JSONObject): Pair<java.time.Instant, java.time.Instant>? = runCatching {
        val a = java.time.Instant.parse(session.getString("startedAt"))
        val b = java.time.Instant.parse(session.getString("finishedAt"))
        if (b > a) a to b else null
    }.getOrNull()

    /** Recalcula notas de todos los entrenos si la fórmula cambió (p. ej. equivalencias). */
    fun refreshAllIfNeeded(state: JSONObject, storedVersion: Int): Boolean {
        if (storedVersion >= FORMULA_VERSION) return false
        val archive = state.optJSONArray("workouts") ?: return false
        val models = (0 until archive.length()).mapNotNull { i ->
            archive.optJSONObject(i)?.let { it.optString("id") to SessionReviewJson.sessionToModel(it) }
        }
        for (i in 0 until archive.length()) {
            val session = archive.optJSONObject(i) ?: continue
            val model = models.firstOrNull { it.first == session.optString("id") }?.second ?: continue
            if (!model.finished) continue
            val history = models.filter { it.first != model.id }.map { it.second }
            val review = VerifiedSessionReviewEngine.review(model, history)
            if (review != null) session.put("sessionReview", SessionReviewJson.toJson(review))
            else session.remove("sessionReview")
        }
        return true
    }
}
