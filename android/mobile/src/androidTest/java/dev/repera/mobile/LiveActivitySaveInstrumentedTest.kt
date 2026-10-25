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
    @get:org.junit.Rule val compose = androidx.compose.ui.test.junit4.createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun evolutionMapCapturesRealWindowAfterStyleLoaded() {
        val loaded = java.util.concurrent.CountDownLatch(1)
        val route = LiveSavedRoute(title = "Ruta sintética Madrid", sportID = "running", points = listOf(
            dev.repera.domain.WorkoutRoutePoint(0,40.438,-3.703,0),
            dev.repera.domain.WorkoutRoutePoint(1,40.441,-3.700,300_000),
            dev.repera.domain.WorkoutRoutePoint(2,40.439,-3.697,600_000)))
        compose.setContent {
            androidx.compose.material3.MaterialTheme {
                LiveRouteEvolutionScreen(route, LiveSport.RUNNING, emptyList(), {}, {}, { loaded.countDown() })
            }
        }
        assertTrue("No cargó el estilo del mapa real", loaded.await(60, java.util.concurrent.TimeUnit.SECONDS))
        Thread.sleep(8_000)
        val bitmap = InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()
        assertNotNull(bitmap)
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val values = android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, "deportes_evolucion_mapa_real.png")
            put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ReperaVerification")
        }
        val uri = context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)!!
        context.contentResolver.openOutputStream(uri)!!.use { bitmap!!.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it) }
    }

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
