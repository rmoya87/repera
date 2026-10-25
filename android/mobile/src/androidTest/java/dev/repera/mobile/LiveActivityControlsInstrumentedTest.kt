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
        compose.setContent { MaterialTheme(colorScheme = lightColorScheme(primary = brandGreen)) {
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
        compose.setContent { MaterialTheme(colorScheme = lightColorScheme(primary = brandGreen)) {
            LiveActivityScreen(account, {}, {})
        } }
        compose.onNodeWithTag("live_sport_picker").performClick()
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
