package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class HealthGoalsInstrumentedTest {
    @Test fun optionalGoalsPersistValidateAndClearWithoutChangingOtherSettings() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val id="goals-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(ctx,id)
        val state=JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray())
            .put("settings",JSONObject().put("weightUnit","lb").put("future","preserve"))
        local.write(state.toString().toByteArray());val repo=WorkoutRepository(ctx,id)
        assertEquals(HealthGoals(),HealthGoals.read(state))
        val goals=HealthGoals(10000,500,45,4,75.5)
        repo.updateHealthGoals(goals)
        assertEquals(goals,StateOverview.fromBytes(local.read())!!.healthGoals)
        val before=local.read()!!
        try {repo.updateHealthGoals(goals.copy(steps=99));fail("Invalid goal accepted")} catch(_:IllegalArgumentException) {}
        assertArrayEquals(before,local.read())
        repo.updateHealthGoals(HealthGoals())
        val reread=JSONObject(String(local.read()!!))
        assertEquals(HealthGoals(),HealthGoals.read(reread));assertFalse(reread.getJSONObject("settings").has("dailyStepsGoal"))
        assertEquals("preserve",reread.getJSONObject("settings").getString("future"))
        assertEquals("lb",reread.getJSONObject("settings").getString("weightUnit"))
    }
}
