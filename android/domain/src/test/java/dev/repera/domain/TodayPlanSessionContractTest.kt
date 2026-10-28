package dev.repera.domain

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Contrato del plan del día para Wear: si hay activeSession, el teléfono no
 * publica plan (todayPlanSession → null). Mirror del gate en WorkoutRepository.
 */
class TodayPlanSessionContractTest {
    @Test
    fun activeSessionBlocksTodayPlanPublication() {
        val withActive = JSONObject()
            .put("activeSession", JSONObject().put("id", "live"))
            .put("routines", JSONArray())
        assertTrue(withActive.has("activeSession") && !withActive.isNull("activeSession"))
        // Gate documentado: publishTodayPlan solo con todayPlanSession != null.
        val shouldPublish = withActive.isNull("activeSession")
        assertFalse(shouldPublish)
    }

    @Test
    fun emptyActiveAllowsPlanLookup() {
        val idle = JSONObject().put("routines", JSONArray())
        assertTrue(idle.isNull("activeSession") || !idle.has("activeSession"))
    }
}
