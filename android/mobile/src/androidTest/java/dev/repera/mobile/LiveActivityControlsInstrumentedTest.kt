package dev.repera.mobile

import android.app.NotificationManager
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.LiveActivityState
import dev.repera.domain.LiveSport
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Emulator only, fresh synthetic account. No GPS, backend or Health access. */
@RunWith(AndroidJUnit4::class)
class LiveActivityControlsInstrumentedTest {
    @get:Rule val compose = createAndroidComposeRule<androidx.activity.ComponentActivity>()
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext
    private fun capture(name: String) {
        compose.waitForIdle()
        Thread.sleep(600) // Wait for frame commit, not only semantic tree.
        val bitmap = InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()!!
        val values = android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, name)
            put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ReperaVerification")
        }
        val uri = context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)!!
        context.contentResolver.openOutputStream(uri)!!.use { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it) }
    }
    @Test fun activeClassicWorkoutRoutesToContinueWithoutStartingLiveRecorder() {
        val account = "test-classic-guard-${UUID.randomUUID()}"
        var opened = false
        LiveActivityRuntime.forAccount(context,account).choose(LiveSport.RUNNING)
        compose.setContent { MaterialTheme(colorScheme = reperaColorScheme(false)) {
            LiveActivityScreen(account, {}, {}, hasActiveWorkout = true, onOpenWorkout = { opened = true })
        } }
        compose.onNodeWithText("Continuar entrenamiento").assertIsDisplayed()
        capture("comenzar_entreno_clasico_activo.png")
        compose.onNodeWithTag("live_start").performClick()
        compose.runOnIdle {
            assertTrue(opened)
            assertEquals(LiveActivityState.Phase.IDLE, LiveActivityRuntime.forAccount(context, account).state.phase)
            LiveActivityRuntime.stopAll()
        }
    }
    @Test fun sportPickerSelectsIndoorActivityAndClosesWithoutStartingSensors() {
        val account = "test-picker-${UUID.randomUUID()}"
        LiveActivityRuntime.forAccount(context,account).choose(LiveSport.RUNNING)
        compose.setContent { MaterialTheme(colorScheme = reperaColorScheme(false)) {
            LiveActivityScreen(account, {}, {})
        } }
        compose.onNodeWithTag("live_sport_picker").performClick()
        compose.onNodeWithTag("choose_sport_running").assertIsDisplayed()
        compose.waitForIdle();Thread.sleep(500)
        capture("comenzar_selector_deporte.png")
        compose.onNodeWithTag("choose_sport_padel").performScrollTo().performClick()
        compose.onNodeWithTag("live_sport_picker").assertTextContains("Elegir actividad: Pádel")
        compose.onNodeWithTag("choose_sport_padel").assertDoesNotExist()
        capture("comenzar_padel_idle.png")
        compose.runOnIdle {
            val runtime = LiveActivityRuntime.forAccount(context, account)
            assertEquals(LiveSport.PADEL, runtime.state.sport)
            assertEquals(LiveActivityState.Phase.IDLE, runtime.state.phase)
            LiveActivityRuntime.stopAll()
        }
    }
    @Test fun gpsCanvasAlternatesMetricsAndMapWithSyntheticPointsWithoutSensors() {
        val account = "test-canvas-${UUID.randomUUID()}"
        val runtime = LiveActivityRuntime.forAccount(context,account)
        runtime.choose(LiveSport.RUNNING)
        val rendered=java.util.concurrent.atomic.AtomicInteger(0)
        fun awaitMapAfter(previous:Int) {
            compose.waitUntil(60_000) { rendered.get()>previous }
            Thread.sleep(1_000)
        }
        compose.setContent { MaterialTheme(colorScheme = reperaColorScheme(false)) {
            LiveActivityScreen(account, {}, {}, onMapRendered={rendered.incrementAndGet()})
        } }
        compose.onNodeWithText("Sin ubicación. Pulsa Centrar para situarte.").assertIsDisplayed()
        awaitMapAfter(0)
        capture("comenzar_gps_idle_mapa.png")
        compose.runOnIdle {
            // Direct recorder fixture: do not start any provider/service.
            val now = System.currentTimeMillis()
            runtime.state.start(now-30_000,"synthetic-canvas")
            runtime.state.receive("synthetic-canvas",dev.repera.domain.WorkoutRoutePoint(0,40.438,-3.703,now-30_000),0.0)
            runtime.state.receive("synthetic-canvas",dev.repera.domain.WorkoutRoutePoint(1,40.4381,-3.703,now-15_000),12.0)
            runtime.publish()
        }
        val beforeMetrics=rendered.get()
        compose.onNodeWithText("Ver métricas").performClick()
        compose.onNodeWithTag("live_pause").assertIsDisplayed()
        awaitMapAfter(beforeMetrics)
        capture("comenzar_gps_metricas.png")
        val beforeMap=rendered.get()
        compose.onNodeWithText("Ver mapa").performClick()
        compose.onNodeWithText("Ver métricas").assertIsDisplayed()
        awaitMapAfter(beforeMap)
        capture("comenzar_gps_mapa_activo.png")
        compose.runOnIdle { runtime.discard();LiveActivityRuntime.stopAll() }
    }
    @Test fun savingReviewReturnsSessionStartDayNotSaveDayAndClearsDraft() {
        val account="test-save-day-${UUID.randomUUID()}"
        LocalSnapshotStore(context,account).write(org.json.JSONObject().put("workouts",org.json.JSONArray())
            .put("exercises",org.json.JSONArray()).put("routines",org.json.JSONArray()).toString().toByteArray())
        val runtime=LiveActivityRuntime.forAccount(context,account)
        val start=System.currentTimeMillis()-2*86_400_000L
        runtime.choose(LiveSport.PADEL);runtime.state.start(start,"synthetic-save-day")
        runtime.state.finish(start+60_000);runtime.publish()
        var savedDay:Long?=null;var saves=0
        compose.setContent { MaterialTheme(colorScheme=reperaColorScheme(false)) {
            LiveActivityScreen(account,{saves++},{},onSavedDay={savedDay=it})
        } }
        compose.onNodeWithText("Nombre de la actividad").performTextInput("Partido antiguo")
        compose.onNodeWithTag("live_save").performScrollTo().performClick()
        compose.runOnIdle {
            assertEquals(start,savedDay);assertEquals(1,saves)
            assertEquals(LiveActivityState.Phase.IDLE,runtime.state.phase)
            val archived=StateOverview.fromBytes(LocalSnapshotStore(context,account).read())!!.completeHistory.single()
            assertEquals("Partido antiguo",archived.title)
            LiveActivityRuntime.stopAll()
        }
    }
    @Test fun activeLiveActivityBlocksAllClassicSessionEntrypointsBeforeAnyWrite() {
        val account = "test-inverse-guard-${UUID.randomUUID()}"
        val runtime = LiveActivityRuntime.forAccount(context,account)
        runtime.choose(LiveSport.PADEL);runtime.start()
        val repository = WorkoutRepository(context,account)
        try {
            listOf<() -> Unit>(
                { repository.startRoutine("none") },
                { repository.startQuickLog("none") },
                { repository.startSessionFromDrafts("none",emptyList(),false) }
            ).forEach { start ->
                try { start();fail("Classic session started with live recorder active") }
                catch (expected: IllegalStateException) { assertTrue(expected.message.orEmpty().contains("En vivo")) }
            }
            assertNull(LocalSnapshotStore(context,account).read())
        } finally { runtime.discard();LiveActivityRuntime.stopAll() }
    }
    @Test fun indoorForegroundServiceNotificationPausesResumesAndFinishesSyntheticSession() {
        val store = SessionStore(context)
        // Never replace a real account. This test requires a fresh emulator.
        assertNull("Fresh test emulator required", store.load())
        val account = "test-fgs-${UUID.randomUUID()}"
        val runtime = LiveActivityRuntime.forAccount(context, account)
        val manager = context.getSystemService(NotificationManager::class.java)
        try {
            store.save(SessionStore.StoredSession(account,"synthetic@example.invalid","Test",account,
                "synthetic-not-valid","synthetic-not-valid",System.currentTimeMillis()/1000+600))
            compose.runOnIdle {
                runtime.choose(LiveSport.PADEL);runtime.start()
                LiveActivityService.startFromVisibleUI(context, account)
            }
            compose.waitUntil(10_000) { manager.activeNotifications.any { it.id == 4203 } }
            fun action(label: String) {
                compose.waitUntil(10_000) { manager.activeNotifications.firstOrNull { it.id == 4203 }
                    ?.notification?.actions?.any { it.title.toString() == label } == true }
                manager.activeNotifications.first { it.id == 4203 }.notification.actions
                    .first { it.title.toString() == label }.actionIntent.send()
            }
            action("Pausar")
            compose.waitUntil(10_000) { runtime.state.phase == LiveActivityState.Phase.PAUSED }
            action("Reanudar")
            compose.waitUntil(10_000) { runtime.state.phase == LiveActivityState.Phase.RECORDING }
            action("Finalizar")
            compose.waitUntil(10_000) { runtime.state.phase == LiveActivityState.Phase.REVIEW }
            compose.waitUntil(10_000) { manager.activeNotifications.none { it.id == 4203 } }
            assertTrue(runtime.discard())
        } finally {
            LiveActivityService.stop(context)
            compose.waitForIdle()
            store.clear();LiveActivityRuntime.stopAll()
        }
    }
}
