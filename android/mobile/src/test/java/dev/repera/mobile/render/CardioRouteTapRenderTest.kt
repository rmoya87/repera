package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.dp
import dev.repera.mobile.RouteMapTapTarget
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

/** Apple fafe016a WorkoutMapTapTarget: preview sin gestos + superficie tactil
 *  que abre el mapa a pantalla completa. Prueba JVM con mapa falso (MapLibre
 *  nativo no carga bajo Robolectric - la integracion MapLibre real queda para
 *  runtime/dispositivo). */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w1000dp")
class CardioRouteTapRenderTest {

    @get:Rule
    val composeRule = createComposeRule()

    private fun save(bitmap: Bitmap, name: String) {
        val dir = File("build/reports/render").apply { mkdirs() }
        FileOutputStream(File(dir, name)).use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }

    @Test
    fun tapOnPreviewOpensFullscreenRoute() {
        composeRule.setContent {
            MaterialTheme {
                RouteMapTapTarget(label = "Ampliar recorrido",
                    modifier = Modifier.fillMaxWidth().height(180.dp)) { interactive, m ->
                    Box(m.background(if (interactive) Color.Blue else Color.Gray)
                        .testTag(if (interactive) "dialog-map" else "preview-map"))
                }
            }
        }
        val preview = composeRule.onNodeWithTag("preview-map").captureToImage().asAndroidBitmap()
        save(preview, "tap-target-preview.png")
        composeRule.onNodeWithContentDescription("Ampliar recorrido")
            .assertIsDisplayed()
            .performClick()
        val dialog = composeRule.onNodeWithTag("fullscreen-route-map")
        dialog.assertIsDisplayed()
        val bmp = dialog.captureToImage().asAndroidBitmap()
        save(bmp, "tap-target-fullscreen.png")
        // Evidencia pixel: el dialog ocupa toda la pantalla y pinta el mapa interactivo.
        val w = bmp.width; val h = bmp.height
        assertTrue("fullscreen ancho=$w", w >= 900)
        val px = bmp.getPixel(w / 2, h / 2)
        assertEquals("centro azul (mapa interactivo)", 0xFF0000FF.toInt(), px)
    }

    @Test
    fun previewStaysNonInteractive() {
        composeRule.setContent {
            MaterialTheme {
                RouteMapTapTarget(label = "Ampliar recorrido",
                    modifier = Modifier.fillMaxWidth().height(180.dp)) { interactive, m ->
                    Box(m.testTag(if (interactive) "dialog-map" else "preview-map"))
                }
            }
        }
        // Antes del tap solo existe el preview (sin gestos); nada de dialog.
        composeRule.onNodeWithTag("preview-map").assertIsDisplayed()
        composeRule.onNodeWithTag("fullscreen-route-map").assertDoesNotExist()
    }
}
