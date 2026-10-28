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
    }    @Test fun selectedDayDurationsAndWeeklyCountsIncludeExternalSamplesAndKeepMissingEnergyUnknown() {
        val state=JSONObject().put("exercises",JSONArray()).put("routines",JSONArray()).put("bodyWeights",JSONArray())
            .put("workouts",JSONArray().put(JSONObject().put("id","live").put("title","Carrera").put("phase","finished")
                .put("startedAt","2026-10-25T10:00:00Z").put("finishedAt","2026-10-25T11:00:00Z")
                .put("liveSportID","running").put("activeDurationSeconds",1800.0).put("exercises",JSONArray())))
        val day=java.time.LocalDate.of(2026,10,25)
        val external=dev.repera.domain.HealthMuscleMapper.ExternalActivity(day.atTime(18,0).atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli(),"walking",20.0)
        val health=HealthSamples(emptyList(),emptyList(),listOf(external))
        val overview=StateOverview.fromBytes(state.toString().toByteArray(),health)!!
        assertEquals(50.0,overview.dayWorkoutMinutes[day]!!,0.00001)
        assertEquals(2,overview.dayWorkoutCounts[day])
        state.getJSONArray("workouts").getJSONObject(0).put("healthConnectRecordId","verified")
        val linked=health.copy(verifiedWorkoutMinutes=mapOf("verified" to HealthWorkoutMinutes.Verified(12.0,true)))
        val reconciled=StateOverview.fromBytes(state.toString().toByteArray(),linked)!!
        assertEquals(32.0,reconciled.dayWorkoutMinutes[day]!!,0.00001)
        assertEquals(2,reconciled.dayWorkoutCounts[day])
        assertNull(overview.dayEnergyKcal[day])
        assertNull(overview.dayWorkoutMinutes[day.minusDays(1)])
    }

}
