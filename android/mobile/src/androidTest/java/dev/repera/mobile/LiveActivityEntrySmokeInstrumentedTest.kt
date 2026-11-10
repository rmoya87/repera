package dev.repera.mobile

import androidx.activity.ComponentActivity
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Reproduces opening Comenzar offline, before any GPS, TTS or remote download. */
@RunWith(AndroidJUnit4::class)
class LiveActivityEntrySmokeInstrumentedTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @After fun cleanup() { LiveActivityRuntime.stopAll() }

    @Test fun openingStartScreenDoesNotRequireTtsOrStartRecording() {
        val account = "test-live-entry-" + UUID.randomUUID()
        // The local seed must be available without a Supabase session.
        CatalogBootstrap.ensureHydrated(context, account)
        compose.setContent {
            MaterialTheme(colorScheme = reperaColorScheme(false)) {
                LiveActivityScreen(account, onSaved = {}, onOpenTools = {})
            }
        }
        compose.onNodeWithTag("live_activity_screen").assertExists()
        compose.runOnIdle {
            val runtime = LiveActivityRuntime.forAccount(context, account)
            assertEquals(dev.repera.domain.LiveActivityState.Phase.IDLE, runtime.state.phase)
            assertFalse("Abrir Comenzar nunca debe inicializar TTS", runtime.isGuidanceEngineInitialized())
        }
    }
}
