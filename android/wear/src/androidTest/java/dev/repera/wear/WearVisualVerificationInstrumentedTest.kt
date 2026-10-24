package dev.repera.wear

import android.content.ContentValues
import android.graphics.Bitmap
import android.provider.MediaStore
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.wear.compose.material3.MaterialTheme
import org.json.JSONObject
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Capturas visuales de la pantalla del reloj con el tema de marca.
 * Comprobación de contenido real (WearHomeContent) en emulador;
 * la revisión de UX en pantalla redonda física queda pendiente.
 */
@RunWith(AndroidJUnit4::class)
class WearVisualVerificationInstrumentedTest {

    @get:Rule val compose = createComposeRule()

    private fun save(name: String, image: androidx.compose.ui.graphics.ImageBitmap) {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ReperaVerification")
        }
        val uri = ctx.contentResolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)!!
        ctx.contentResolver.openOutputStream(uri)!!.use { out ->
            image.asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, out)
        }
    }

    @Composable
    private fun WearFrame(content: @Composable () -> Unit) {
        MaterialTheme(colorScheme = MaterialTheme.colorScheme.copy(
            primary = Color(0xFF30D158), onPrimary = Color.Black)) {
            // Viewport REDONDO y oscuro como un reloj real: recorta esquinas
            // y fuerza a verificar que todo el contenido es accesible con
            // scroll, no solo visible en un marco cuadrado.
            Box(modifier = Modifier.size(320.dp)
                .clip(androidx.compose.foundation.shape.CircleShape)
                .background(Color(0xFF121212))) {
                content()
            }
        }
    }

    @Test
    fun capturaWearSesionFuerza() {
        val session = WatchSessionSummary(
            sessionId = "s1", title = "Pierna", canLogOnWatch = true,
            allowsWeight = true, exerciseName = "Back Squat",
            exerciseIndex = 1, exerciseCount = 3, recordedSets = 2,
            prescribedReps = 5, prescribedWeightKg = 100.0,
            wodFormatLabel = null, globalScore = false,
            wodMovements = emptyList(), inputMode = "reps")
        compose.setContent {
            WearFrame {
                WearHomeContent(
                    state = WearHomeState(
                        session = session, showingCachedSession = false,
                        finishedSummary = null, todayPlan = null,
                        syncProblem = false, health = 145 to 210.0,
                        wodTimerJson = null, wodTickSeconds = 0,
                        sessionPaused = false, restRemaining = 0,
                        repsInput = 5, weightInput = 100.0, rirInput = 2.0,
                        durationInput = 30, unitInput = "reps", deficitInput = 5,
                        pendingCount = 0, confirmDiscardPending = false,
                        sendStatus = null),
                    callbacks = WearHomeCallbacks(),
                    modifier = Modifier.fillMaxSize())
            }
        }
        compose.waitForIdle()
        // Dos nodos contienen "5 reps" (prescripción cabecera y entrada de
        // registro): coincidencias exactas para no ambiguar el matcher.
        compose.onNodeWithText("5 reps · 100.0 kg").assertExists()
        compose.onAllNodesWithText("WearHomeState(", substring = true).assertCountEquals(0)
        // Todos los controles alcanzables con scroll en el viewport redondo.
        compose.onNodeWithText("Registrar serie").performScrollTo().assertIsDisplayed()
        compose.onNodeWithText("5 reps").assertIsDisplayed()
        save("wear_sesion_fuerza", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaWearEntrenoDeHoy() {
        val plan = JSONObject()
            .put("title", "Empuje + acondicionamiento")
            .put("exercises", org.json.JSONArray().put(JSONObject()).put(JSONObject()))
        compose.setContent {
            WearFrame {
                WearHomeContent(
                    state = WearHomeState(
                        session = null, showingCachedSession = false,
                        finishedSummary = null, todayPlan = plan,
                        syncProblem = false, health = null,
                        wodTimerJson = null, wodTickSeconds = 0,
                        sessionPaused = false, restRemaining = 0,
                        repsInput = 0, weightInput = null, rirInput = null,
                        durationInput = 30, unitInput = "reps", deficitInput = 5,
                        pendingCount = 1, confirmDiscardPending = false,
                        sendStatus = null),
                    callbacks = WearHomeCallbacks(),
                    modifier = Modifier.fillMaxSize())
            }
        }
        compose.waitForIdle()
        compose.onNodeWithText("Entreno de hoy", substring = true).assertExists()
        compose.onAllNodesWithText("WearHomeState(", substring = true).assertCountEquals(0)
        compose.onNodeWithText("Reintentar sincronización").performScrollTo().assertIsDisplayed()
        save("wear_entreno_de_hoy", compose.onRoot().captureToImage())
    }

}
