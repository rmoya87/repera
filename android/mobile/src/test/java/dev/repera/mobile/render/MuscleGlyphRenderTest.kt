package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.dp
import dev.repera.mobile.MuscleChipGlyph
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

/**
 * Render headless inspeccionable (Robolectric graficos nativos, JVM): rasteriza
 * los glifos de musculo a PNGs revisables en build/reports/render/.
 * NO es validacion de dispositivo: acredita solo que el composable rasteriza
 * pixeles no vacios y permite inspeccion visual del resultado.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35])
class MuscleGlyphRenderTest {

    @get:Rule
    val composeRule = createComposeRule()

    private val outDir = File("build/reports/render").apply { mkdirs() }

    private fun saveBitmap(name: String, bitmap: Bitmap): File {
        val out = File(outDir, name + ".png")
        FileOutputStream(out).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        return out
    }

    private fun inkPixels(bitmap: Bitmap): Int {
        val px = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(px, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        var n = 0
        for (p in px) if ((p ushr 24) > 0 && p != -1) n++
        return n
    }

    @Test
    fun glyphAreasRenderNonBlankPixels() {
        // Etiquetas reales de catalogo (displayNameES) + Cardio + desconocido.
        val muscles = listOf("Pecho", "Espalda", "Hombros", "Bíceps", "Antebrazo",
            "Abdominales", "Glúteo", "Cuádriceps", "Gemelos", "Cardio", "desconocidoX")
        composeRule.setContent {
            MaterialTheme {
                Surface {
                    // Dos filas: 11x48dp en vertical excede el alto raiz del
                    // entorno headless y el ultimo nodo queda con bounds 0.
                    androidx.compose.foundation.layout.Column {
                        for (chunk in muscles.chunked(6)) {
                            androidx.compose.foundation.layout.Row {
                                for (muscle in chunk) {
                                    androidx.compose.foundation.layout.Box(
                                        modifier = Modifier.size(48.dp)
                                            .testTag("glyph_" + muscle)) {
                                        MuscleChipGlyph(muscle, emphasized = false)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        val rendered = mutableListOf<String>()
        for (muscle in muscles) {
            val bitmap = composeRule.onNodeWithTag("glyph_" + muscle)
                .captureToImage().asAndroidBitmap()
            val out = saveBitmap("glyph_" + muscle.replace(" ", "_"), bitmap)
            val ink = inkPixels(bitmap)
            assert(ink > 8) {
                "Glifo '$muscle' renderizo vacio ($ink px) en ${out.absolutePath}" }
            rendered.add(out.absolutePath + ":" + ink)
        }
        println("RENDERED_GLYPHS=" + rendered.joinToString(","))
    }

    @Test
    fun glyphEmphasizedVariantRenders() {
        composeRule.setContent {
            MaterialTheme {
                Surface {
                    androidx.compose.foundation.layout.Box(
                        modifier = Modifier.size(48.dp).testTag("emph")
                            .background(MaterialTheme.colorScheme.primary)) {
                        MuscleChipGlyph("Pecho", emphasized = true)
                    }
                }
            }
        }
        val bitmap = composeRule.onNodeWithTag("emph").captureToImage().asAndroidBitmap()
        val out = saveBitmap("glyph_pecho_emphasized", bitmap)
        assert(inkPixels(bitmap) > 8) { "PNG emphasized vacio: ${out.absolutePath}" }
    }
}
