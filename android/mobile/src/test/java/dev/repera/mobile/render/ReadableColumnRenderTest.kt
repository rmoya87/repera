package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.requiredWidth
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.dp
import dev.repera.mobile.ReadableColumn
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

/**
 * Prueba JVM del tope 790dp centrado de ReadableColumn (Apple
 * OG.contentColumnMaxWidth). NO es validacion de dispositivo: las cotas se
 * miden sobre un fixture de ancho fijo; la captura es inspeccion visual
 * auxiliar en build/reports/render/.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35])
class ReadableColumnRenderTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun capsAt790AndCentersOnWideParent() {
        composeRule.setContent {
            MaterialTheme {
                Surface {
                    Box(Modifier.requiredWidth(1000.dp).height(400.dp)
                        .background(Color(0xFFDDDDDD)).testTag("outer")) {
                        ReadableColumn {
                            Box(Modifier.fillMaxWidth().height(120.dp)
                                .background(Color(0xFF2E7D32)).testTag("inner"))
                        }
                    }
                }
            }
        }
        // Cotas relativas al contenedor: el viewport de Robolectric es 320dp
        // y centra el contenido desbordado, asi que la posicion absoluta varia.
        val outer = composeRule.onNodeWithTag("outer").getUnclippedBoundsInRoot()
        val inner = composeRule.onNodeWithTag("inner").getUnclippedBoundsInRoot()
        org.junit.Assert.assertEquals(790f, (inner.right - inner.left).value, 0.6f)
        // Centrado: (1000 - 790) / 2 = 105dp de margen izquierdo.
        org.junit.Assert.assertEquals(105f, (inner.left - outer.left).value, 0.6f)
    }

    /** Hoja visual auxiliar (sin aserciones): el fixture de 1000dp escalado
     *  0.32x cabe en el viewport y muestra el centrado completo. La prueba de
     *  cotas es capsAt790AndCentersOnWideParent. */
    @Test
    @Config(sdk = [35], qualifiers = "w1000dp-h600dp")
    fun wideSheetCaptureForVisualReview() {
        composeRule.setContent {
            MaterialTheme {
                Surface {
                    Box(Modifier.requiredWidth(1000.dp).height(400.dp)
                        .background(Color(0xFFDDDDDD)).testTag("sheet")) {
                        ReadableColumn {
                            Box(Modifier.fillMaxWidth().height(120.dp)
                                .background(Color(0xFF2E7D32))
                                .testTag("sheetInner"))
                        }
                    }
                }
            }
        }
        // Sincronizar composicion/layout antes de capturar (sin asercion el
        // idle puede no esperar al contenido escalado).
        composeRule.waitUntil(timeoutMillis = 10000) {
            runCatching {
                composeRule.onNodeWithTag("sheetInner").fetchSemanticsNode()
            }.isSuccess
        }
        composeRule.waitForIdle()
        val bitmap = composeRule.onNodeWithTag("sheet").captureToImage().asAndroidBitmap()
        val dir = File("build/reports/render").apply { mkdirs() }
        FileOutputStream(File(dir, "readable_column_wide.png")).use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }

    @Test
    fun doesNotRestrictNarrowParent() {
        composeRule.setContent {
            MaterialTheme {
                Surface {
                    Box(Modifier.requiredWidth(400.dp).height(300.dp).testTag("outer")) {
                        ReadableColumn {
                            Box(Modifier.fillMaxWidth().height(100.dp).testTag("inner"))
                        }
                    }
                }
            }
        }
        val outer = composeRule.onNodeWithTag("outer").getUnclippedBoundsInRoot()
        val inner = composeRule.onNodeWithTag("inner").getUnclippedBoundsInRoot()
        org.junit.Assert.assertEquals(400f, (inner.right - inner.left).value, 0.6f)
        org.junit.Assert.assertEquals(outer.left.value, inner.left.value, 0.6f)
    }
}
