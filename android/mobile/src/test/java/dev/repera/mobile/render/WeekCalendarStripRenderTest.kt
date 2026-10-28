package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import dev.repera.mobile.WeekCalendarStrip
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream
import java.time.LocalDate

/** Previsualizacion JVM de la tira semanal (NO validacion de dispositivo):
 *  compacta = 7 dias sin scroll; expandida = carrusel con mas de 7 dias. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35])
class WeekCalendarStripRenderTest {

    @get:Rule
    val composeRule = createComposeRule()

    private fun save(bitmap: Bitmap, name: String) {
        val dir = File("build/reports/render").apply { mkdirs() }
        FileOutputStream(File(dir, name)).use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }

    @Test
    fun compactShowsSevenDayStrip() {
        composeRule.setContent {
            MaterialTheme {
                Surface(modifier = androidx.compose.ui.Modifier.testTag("weekwrap")) {
                    WeekCalendarStrip(LocalDate.of(2026, 10, 27), true,
                        setOf(LocalDate.of(2026, 10, 26)), null) {}
                }
            }
        }
        composeRule.onNodeWithTag("week_strip_compact").assertIsDisplayed()
        save(composeRule.onNodeWithTag("weekwrap").captureToImage()
            .asAndroidBitmap(), "week_strip_compact.png")
    }

    @Test
    @Config(sdk = [35], qualifiers = "w1000dp-h800dp")
    fun expandedShowsScrollableCarousel() {
        composeRule.setContent {
            MaterialTheme {
                Surface(modifier = androidx.compose.ui.Modifier.testTag("weekwrap")) {
                    WeekCalendarStrip(LocalDate.of(2026, 10, 27), true,
                        setOf(LocalDate.of(2026, 10, 26)), null) {}
                }
            }
        }
        composeRule.onNodeWithTag("week_strip_expanded").assertIsDisplayed()
        save(composeRule.onNodeWithTag("weekwrap").captureToImage()
            .asAndroidBitmap(), "week_strip_expanded.png")
    }
}
