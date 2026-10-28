package dev.repera.mobile

import dev.repera.domain.ExerciseLoggingStyle
import dev.repera.domain.ReviewDimension
import dev.repera.domain.ReviewIndicator
import dev.repera.domain.ScoreBasis
import dev.repera.domain.SessionReview
import dev.repera.domain.WodFormat
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionReviewJsonTest {

    @Test
    fun `roundtrip conserva indicadores y confianza (wire Codable iOS)`() {
        val review = SessionReview(
            overallScore = 8,
            headline = "Rendimiento personal · 8/10",
            vsHistorySummary = "100% del rendimiento registrado tiene referencias.",
            vsStandardSummary = "Historial personal.",
            keepTips = listOf("Cada referencia muestra su nivel."),
            improveTips = listOf("Con más sesiones aumentará la confianza."),
            scoreBasis = ScoreBasis.PERSONAL_HISTORY,
            indicators = listOf(
                ReviewIndicator(ReviewDimension.PERSONAL_PROGRESS, 8, "Detalle",
                    referenceSessions = 2, comparisonLevel = 1),
                ReviewIndicator(ReviewDimension.ADHERENCE, null, "3 de 3 series registradas."),
                ReviewIndicator(ReviewDimension.WOD_PERFORMANCE, null, "Sin referencias.")
            ),
            evidenceCoverage = 1.0,
            confidenceLabel = "En construcción"
        )
        val decoded = SessionReviewJson.fromJson(SessionReviewJson.toJson(review))!!
        assertEquals(review.indicators, decoded.indicators)
        assertEquals(review.confidenceLabel, decoded.confidenceLabel)
        assertEquals(review.scoreBasis, decoded.scoreBasis)
        assertEquals(review.evidenceCoverage!!, decoded.evidenceCoverage!!, 1e-9)
        assertEquals(review.headline, decoded.headline)
    }

    @Test
    fun `decodifica indicador legado sin comparisonLevel`() {
        val old = JSONObject()
            .put("dimension", "personalProgress")
            .put("score", 7)
            .put("detail", "Anterior")
        val obj = JSONObject()
            .put("overallScore", 7)
            .put("headline", "H")
            .put("indicators", org.json.JSONArray().put(old))
        val review = SessionReviewJson.fromJson(obj)!!
        assertNull(review.indicators[0].comparisonLevel)
        assertEquals(7, review.indicators[0].score)
    }

    @Test
    fun `sessionToModel deriva estilos y estructura WOD`() {
        val session = JSONObject("""{
          "id": "s1", "title": "AMRAP 8'", "phase": "finished",
          "finishedAt": "2026-10-24T10:00:00Z",
          "exercises": [{
            "id": "e1",
            "exercise": {"id": "x1", "name": "Burpee box jump over", "muscleGroup": "Cardio"},
            "plannedSets": [{"targetReps": 10}],
            "loggedSets": [],
            "blockId": "b1", "blockKind": "wod", "wodFormat": "amrap",
            "blockTimeCapMinutes": 8
          }],
          "wodResults": [{"id": "b1", "format": "amrap", "roundsCompleted": 4, "totalReps": 2}],
          "routineBlocks": [{
            "id": "b1", "title": "AMRAP 8'", "wodFormat": "amrap", "timeCapMinutes": 8,
            "movements": [{"name": "Burpee box jump over", "reps": 10, "isRest": false}]
          }]
        }""")
        val model = SessionReviewJson.sessionToModel(session)
        assertTrue(model.finished)
        assertEquals(WodFormat.AMRAP, model.wodResults[0].format)
        assertEquals(WodFormat.AMRAP, model.exercises[0].wodFormat)
        assertEquals(ExerciseLoggingStyle.REPS_ONLY, model.exercises[0].exercise.loggingStyle)
        assertEquals(10, model.routineBlocks!![0].movements[0].reps)
        assertEquals(8, model.routineBlocks!![0].timeCapMinutes)
    }
}
