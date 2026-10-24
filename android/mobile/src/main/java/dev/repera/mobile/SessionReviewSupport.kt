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
