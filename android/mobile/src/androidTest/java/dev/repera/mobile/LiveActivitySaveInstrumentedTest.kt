package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.LiveActivityState
import dev.repera.domain.LiveSport
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Cuenta sintética aislada, sin sensores, red ni Salud. */
@RunWith(AndroidJUnit4::class)
class LiveActivitySaveInstrumentedTest {
    @Test fun saveLiveActivityIsIdempotentAndDoesNotInventExerciseOrHealthValues() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val account="test-live-save-${UUID.randomUUID()}"
        val local=LocalSnapshotStore(context,account)
        local.write(JSONObject().put("workouts",JSONArray()).put("exercises",JSONArray())
            .put("routines",JSONArray()).toString().toByteArray())
        val recorder=LiveActivityState();recorder.choose(LiveSport.PADEL)
        recorder.start(1_000_000,"synthetic-live");recorder.pause(1_060_000)
        recorder.resume(1_120_000);recorder.finish(1_180_000)
        val repo=WorkoutRepository(context,account)
        repeat(2) { repo.saveLiveActivity(recorder.snapshot(1_180_000)!!,1_180_000,
            recorder.durationSeconds(1_180_000),"  Partido  ","  nota  ") }
        val archive=JSONObject(String(local.read()!!)).getJSONArray("workouts")
        assertEquals(1,archive.length())
        val s=archive.getJSONObject(0)
        assertEquals("Partido",s.getString("title"));assertEquals("padel",s.getString("liveSportID"))
        assertEquals(120.0,s.getDouble("activeDurationSeconds"),0.0)
        assertEquals(0,s.getJSONArray("exercises").length())
        assertFalse(s.has("recordedDistanceMeters"));assertFalse(s.has("appleActiveEnergyKcal"))
        assertFalse(s.has("appleAverageHeartRateBpm"))
        val overview=StateOverview.fromBytes(local.read())!!
        assertEquals(1,overview.liveSportSessions.size)
        assertEquals("synthetic-live",overview.completeHistory.single().id)
    }
}
