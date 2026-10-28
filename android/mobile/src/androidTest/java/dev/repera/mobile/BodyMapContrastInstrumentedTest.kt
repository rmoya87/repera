package dev.repera.mobile

import android.graphics.Color as AndroidColor
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class BodyMapContrastInstrumentedTest {
    @get:Rule val compose = createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun neutralAnatomyAndFirstLegendRemainVisibleInBothThemes() {
        var dark by androidx.compose.runtime.mutableStateOf(false)
        compose.setContent {
            MaterialTheme(colorScheme = reperaColorScheme(dark)) {
                Surface(Modifier.fillMaxSize().safeDrawingPadding()) {
                    MuscleBalanceCard(emptyMap(), emptyMap(), emptyMap(), emptyMap(), false)
                }
            }
        }
        for (isDark in listOf(false, true)) {
            compose.runOnIdle { dark = isDark }
            compose.waitUntil(10000) {
                compose.onAllNodesWithTag("body_map_loaded").fetchSemanticsNodes().isNotEmpty()
            }
            compose.waitForIdle()
            // All values are zero. Colored active muscles cannot mask missing anatomy.
            val anatomy = compose.onNodeWithTag("body_map_loaded").captureToImage().asAndroidBitmap()
            val background = anatomy.getPixel(2, 2)
            fun luminance(color: Int) = (0.2126 * AndroidColor.red(color) +
                0.7152 * AndroidColor.green(color) + 0.0722 * AndroidColor.blue(color)) / 255
            var contrasting = 0
            for (y in 0 until anatomy.height step 3) for (x in 0 until anatomy.width step 3) {
                if (kotlin.math.abs(luminance(anatomy.getPixel(x, y)) - luminance(background)) > 0.12) contrasting++
            }
            assertTrue("Neutral anatomy not visible in dark=$isDark: $contrasting pixels", contrasting > 1000)
            val legend = compose.onNodeWithTag("body_legend_0").captureToImage().asAndroidBitmap()
            assertTrue("Neutral legend blends into card dark=$isDark",
                kotlin.math.abs(luminance(legend.getPixel(legend.width / 2, legend.height / 2)) - luminance(background)) > 0.12)
            val bitmap = InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()!!
            val context = InstrumentationRegistry.getInstrumentation().targetContext
            val values = android.content.ContentValues().apply {
                put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, "cuerpo_neutro_${if(isDark) "oscuro" else "claro"}.png")
                put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ReperaVerification")
            }
            val uri = context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)!!
            context.contentResolver.openOutputStream(uri)!!.use { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        }
    }
}
