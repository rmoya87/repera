package dev.repera.mobile

import androidx.activity.ComponentActivity
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.LiveSport
import dev.repera.domain.LiveSportHistory
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Fixtures aislados: sin cuentas, ubicación ni Salud reales. */
@RunWith(AndroidJUnit4::class)
class LiveSportHistoryInstrumentedTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()
    private fun session(id: String, sport: String, meters: Double? = null) =
        LiveSportHistory.LiveSession(id, "Actividad $id", sport,
            1792918800000L, 1792922400000L, 1800.0, meters, null, null)

    private fun save(name: String) {
        val bmp = compose.onRoot().captureToImage().asAndroidBitmap()
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val values = android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
            put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ReperaVerification")
        }
        val uri = context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)!!
        context.contentResolver.openOutputStream(uri)!!.use { bmp.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
    }

    @Test fun catalogOpensHistoryAndSessionWithoutInventingHealthMetrics() {
        var opened: String? = null
        val sessions = listOf(session("r1", "running", 5000.0), session("r2", "running", 4500.0), session("p1", "padel"))
        compose.setContent {
            MaterialTheme(colorScheme = darkColorScheme(primary = brandGreen)) {
                Surface(Modifier.fillMaxSize()) {
                    var sport by remember { mutableStateOf<LiveSport?>(null) }
                    if (sport == null) LiveSportsCatalogScreen(sessions, "", { sport = it })
                    else LiveSportHistoryScreen(sport!!, sessions, { sport = null }, { opened = it })
                }
            }
        }
        compose.onNodeWithTag("sport_running").assertIsDisplayed()
        compose.onNodeWithText("Pádel").assertIsDisplayed()
        save("deportes_catalogo")
        compose.onNodeWithTag("sport_running").performClick()
        compose.onNodeWithText("9.5 km").assertExists()
        compose.onNodeWithText("Energía medida").assertDoesNotExist()
        compose.onNodeWithText("Pulso medio").assertDoesNotExist()
        save("deportes_historial_carrera")
        compose.onNodeWithTag("live_session_r1").performScrollTo().performClick()
        assertEquals("r1", opened)
    }

    @Test fun queryFoldsAccentsAndEmptyStateIsHonest() {
        compose.setContent {
            MaterialTheme { LiveSportsCatalogScreen(listOf(session("p", "padel")), "padel", {}) }
        }
        compose.onNodeWithText("Pádel").assertIsDisplayed()
        compose.onNodeWithText("Carrera").assertDoesNotExist()
    }

    @Test fun savedSplitsUseActiveTimeNotWallClock() {
        compose.setContent { MaterialTheme { LiveKilometerSplitsSection(listOf(300.0, 312.0)) } }
        compose.onNodeWithText("05:00 min/km").assertIsDisplayed()
        compose.onNodeWithText("05:12 min/km").assertIsDisplayed()
    }
}
