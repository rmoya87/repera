package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.Whatshot
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.unit.dp
import dev.repera.mobile.WorkoutSummaryTile
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

/** Apple 1b5d4eea/056cba8b/025828b5 WorkoutSummaryTile: icono+etiqueta en fila
 *  centrada y valor centrado debajo, altura intrinseca. Previsualizacion JVM
 *  (NO validacion de dispositivo). */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w1000dp")
class WorkoutSummaryTileRenderTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun tilesShowIconLabelAndCenteredValue() {
        composeRule.setContent {
            MaterialTheme {
                Surface(Modifier.testTag("tileswrap")) {
                    Card(Modifier.fillMaxWidth().padding(16.dp)) {
                        Row(Modifier.fillMaxWidth().padding(16.dp)) {
                            WorkoutSummaryTile("Tiempo", "1:23:45", Icons.Outlined.AccessTime,
                                Modifier.weight(1f).testTag("tile-time"))
                            WorkoutSummaryTile("Distancia", "12,34 km", Icons.Outlined.Route,
                                Modifier.weight(1f))
                            WorkoutSummaryTile("Energía", "640 kcal", Icons.Outlined.Whatshot,
                                Modifier.weight(1f))
                        }
                    }
                }
            }
        }
        composeRule.onNodeWithText("1:23:45").assertIsDisplayed()
        composeRule.onNodeWithText("Tiempo").assertIsDisplayed()
        val bmp = composeRule.onNodeWithTag("tileswrap").captureToImage().asAndroidBitmap()
        File("build/reports/render").mkdirs()
        FileOutputStream("build/reports/render/summary-tiles.png").use {
            bmp.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        // Evidencia pixel: la fila de tiles pinta contenido no trivial.
        var colored = 0
        for (x in 0 until bmp.width step 7) for (y in 0 until bmp.height step 5) {
            val p = bmp.getPixel(x, y)
            if ((p ushr 24) != 0 && p != -1 && p != 0xFF000000.toInt()) colored++
        }
        assertTrue("tiles con contenido ($colored muestras no blancas)", colored > 200)
    }
}
