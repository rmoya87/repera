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
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.performScrollToNode
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

    private fun scrollHastaTexto(texto: String) {
        compose.onNode(hasScrollToIndexAction())
            .performScrollToNode(androidx.compose.ui.test.hasText(texto))
        compose.waitForIdle()
    }

    @Composable
    private fun WearFrame(content: @Composable () -> Unit) {
        MaterialTheme(colorScheme = MaterialTheme.colorScheme.copy(
            primary = Color(0xFF30D158), onPrimary = Color.Black)) {
            Box(modifier = Modifier.size(320.dp)
                .clip(androidx.compose.foundation.shape.CircleShape)
                .background(Color.Black)) {
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
            wodMovements = emptyList(), inputMode = "strength",
            plannedWorkSets = 3, phase = "counting",
            blockHeader = "Bloque 1")
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
                        sendStatus = null, elapsedSeconds = 12),
                    callbacks = WearHomeCallbacks(),
                    modifier = Modifier.fillMaxSize())
            }
        }
        compose.waitForIdle()
        compose.onNodeWithText("Back Squat", substring = true).assertExists()
        compose.onNodeWithText("♥ 145 lpm", substring = true).assertExists()
        compose.onAllNodesWithText("WearHomeState(", substring = true).assertCountEquals(0)
        save("wear_sesion_fuerza_inicio", compose.onRoot().captureToImage())
        scrollHastaTexto("Reps")
        compose.onNodeWithText("Reps").assertIsDisplayed()
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
        compose.onNodeWithText("Empuje", substring = true).assertExists()
        compose.onAllNodesWithText("WearHomeState(", substring = true).assertCountEquals(0)
        compose.onNodeWithText("Reintentar", substring = true).assertIsDisplayed()
        save("wear_entreno_de_hoy", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaWearResultadoSinBugDuracion() {
        val finished = FinishedSummary(
            sessionId = "fin-1",
            title = "Entreno · Viernes",
            durationLabel = "33:00",
            exercises = 6,
            sets = 13,
            reps = 104,
            volumeKg = 40,
            kcal = 120,
            avgHr = 110
        )
        compose.setContent {
            WearFrame {
                WearHomeContent(
                    state = WearHomeState(
                        session = null, showingCachedSession = false,
                        finishedSummary = finished, todayPlan = null,
                        syncProblem = false, health = null,
                        wodTimerJson = null, wodTickSeconds = 0,
                        sessionPaused = false, restRemaining = 0,
                        repsInput = 0, weightInput = null, rirInput = null,
                        durationInput = 30, unitInput = "reps", deficitInput = 5,
                        pendingCount = 0, confirmDiscardPending = false,
                        sendStatus = null),
                    callbacks = WearHomeCallbacks(),
                    modifier = Modifier.fillMaxSize())
            }
        }
        compose.waitForIdle()
        compose.onNodeWithText("¡Bien hecho!").assertExists()
        compose.onNodeWithText("33:00").assertExists()
        compose.onAllNodesWithText("5865", substring = true).assertCountEquals(0)
        scrollHastaTexto("Volver al inicio")
        compose.onNodeWithText("Volver al inicio").assertIsDisplayed()
        save("wear_resultado_w01", compose.onRoot().captureToImage())
    }

    @Test fun wodFinishUsesCommonConsumerWithoutInventingScore() {
        val session = WatchSessionSummary(
            "wod-session", "WOD", false, false, "Remo", 1, 1, 0, null, null,
            "AMRAP", globalScore = true, wodMovements = listOf("500 m Remo"),
            phase = "counting", wodFormatWire = "amrap"
        )
        var reviewed = false
        compose.setContent {
            WearFrame {
                WearHomeContent(
                    WearHomeState(
                        session, false, null, null, false, null, null, 0, false, 0,
                        0, null, null, 60, "meters", 0, 0, false, null
                    ),
                    WearHomeCallbacks(onReviewBlock = { reviewed = true }),
                    Modifier.fillMaxSize()
                )
            }
        }
        scrollHastaTexto("Terminar bloque")
        compose.onNodeWithText("Terminar bloque").performClick()
        org.junit.Assert.assertTrue(reviewed)
        save("wear_wod_finish_consumer", compose.onRoot().captureToImage())
    }

    @Test fun pausedStrengthCannotConfirmSet() {
        val session = WatchSessionSummary(
            "pause-session", "Fuerza", true, true, "Sentadilla", 1, 1, 0, 5, 20.0,
            null, globalScore = false, wodMovements = emptyList(),
            plannedWorkSets = 3, phase = "counting", inputMode = "strength"
        )
        compose.setContent {
            WearFrame {
                WearHomeContent(
                    WearHomeState(
                        session, false, null, null, false, null, null, 0, true, 0,
                        5, 20.0, 2.0, 60, "reps", 0, 0, false, null,
                        elapsedSeconds = 8
                    ),
                    WearHomeCallbacks(),
                    Modifier.fillMaxSize()
                )
            }
        }
        compose.waitForIdle()
        // El botón → / confirmar queda deshabilitado en pausa.
        compose.onNodeWithText("→").assertIsNotEnabled()
        save("wear_paused_confirmation", compose.onRoot().captureToImage())
    }

    @Test fun emptyShowsSinPlanDescargado() {
        compose.setContent {
            WearFrame {
                WearHomeContent(
                    WearHomeState(
                        null, false, null, null, false, null, null, 0, false, 0,
                        0, null, null, 30, "reps", 5, 0, false, null
                    ),
                    WearHomeCallbacks(),
                    Modifier.fillMaxSize()
                )
            }
        }
        compose.onNodeWithText("Carrera", substring = true).assertExists()
        compose.onNodeWithText("Sincronizar").assertDoesNotExist()
    }
}
