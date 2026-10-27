package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollToNode
import dev.repera.domain.ProgressTimeRange
import dev.repera.domain.RecoveryEngine
import dev.repera.mobile.HomeTab
import dev.repera.mobile.ProgressTab
import dev.repera.mobile.RecoveryHistoryCards
import dev.repera.mobile.RecoveryState
import dev.repera.mobile.RoutineBlocksEditorScreen
import dev.repera.mobile.RoutineEntry
import dev.repera.mobile.reperaColorScheme
import java.io.File
import java.io.FileOutputStream
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/** Capturas JVM de las correcciones del 27oct (tema claro, 360dp):
 *  188624cc tiles ultimo dia recuperacion, 160f304c separacion boton añadir,
 *  040227d5 Volver neutral vs Guardar verde, 2ac224f5 historial bajo Entreno.
 *  Previsualizacion de fixtures, NO validacion de dispositivo. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w360dp-h900dp")
class ReviewSpacingRenderTest {

    @get:Rule
    val composeRule = createComposeRule()

    private fun save(bmp: Bitmap, name: String) {
        File("build/reports/render").mkdirs()
        FileOutputStream("build/reports/render/$name").use {
            bmp.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }

    // La columna de recuperacion no es scrollable: alto amplio para que los
    // tiles queden dentro de la ventana y tengan bounds capturables.
    @Test
    @Config(sdk = [35], qualifiers = "w360dp-h3400dp")
    fun recoveryLastDayTiles() {
        val today = LocalDate.now()
        composeRule.setContent {
            MaterialTheme(colorScheme = reperaColorScheme(false)) {
                Surface(Modifier.testTag("recoverywrap")) {
                    RecoveryHistoryCards(
                        RecoveryState(readiness = null, sleepIndex = null,
                            lastNightHours = null, recentAverageSleepHours = null,
                            vitals = listOf(
                                RecoveryEngine.DailyVitals(today.minusDays(2),
                                    oxygenSaturationPercent = 97.0),
                                RecoveryEngine.DailyVitals(today,
                                    oxygenSaturationPercent = 98.4,
                                    wristTemperatureCelsius = 33.25,
                                    heartRateRecoveryBpm = 27.6))),
                        ProgressTimeRange.WEEK, true)
                }
            }
        }
        composeRule.onNodeWithText("T nocturna", useUnmergedTree = true).assertExists()
        save(composeRule.onNodeWithTag("recovery_tile_spo2", useUnmergedTree = true)
            .captureToImage().asAndroidBitmap(), "recovery-tile-spo2.png")
        save(composeRule.onNodeWithTag("recovery_tile_temp", useUnmergedTree = true)
            .captureToImage().asAndroidBitmap(), "recovery-tile-temp.png")
        save(composeRule.onNodeWithTag("recovery_tile_hr_recovery", useUnmergedTree = true)
            .captureToImage().asAndroidBitmap(), "recovery-tile-hr.png")
        save(composeRule.onNodeWithTag("recoverywrap").captureToImage().asAndroidBitmap(),
            "recovery-last-day-tiles.png")
    }

    @Test
    fun importedActivityIcons() {
        composeRule.setContent {
            MaterialTheme(colorScheme = reperaColorScheme(false)) {
                Surface(Modifier.testTag("externalicons")) {
                    androidx.compose.foundation.layout.Column {
                        listOf("surfingSports","paddleSports","sailing","downhillSkiing",
                            "crossCountrySkiing","snowboarding","skatingSports","volleyball","climbing","other").forEach { key ->
                            androidx.compose.foundation.layout.Row(
                                modifier=Modifier.then(Modifier),
                                verticalAlignment=androidx.compose.ui.Alignment.CenterVertically) {
                                dev.repera.mobile.ExternalHealthActivityIcon(key)
                                androidx.compose.material3.Text(key)
                            }
                        }
                    }
                }
            }
        }
        save(composeRule.onNodeWithTag("externalicons").captureToImage().asAndroidBitmap(),
            "external-activity-icons.png")
    }

    @Test
    fun homeAddWorkoutButtonSeparated() {
        composeRule.setContent {
            MaterialTheme(colorScheme = reperaColorScheme(false)) {
                Surface(Modifier.testTag("homewrap")) {
                    HomeTab(displayName = "Ramón", busy = false, syncing = false,
                        status = null, overview = null, todayHealth = null,
                        onHealthConnect = {}, activeWorkout = null, wodTimer = null,
                        onWodTimerAction = {}, onWodTimerTick = {},
                        onStartRoutine = {}, onWodScore = { _, _, _ -> },
                        onWodMovement = { _, _, _, _ -> }, onCompleteWodBlock = {},
                        onReviseWodMovement = { _, _, _ -> }, onDeleteWodMovement = { },
                        onLogSet = { _, _, _, _, _, _, _, _ -> },
                        onLogDropSet = { _, _, _, _, _ -> },
                        onLogRestPauseSet = { _, _, _, _ -> },
                        onReviseSet = { _, _, _, _, _, _ -> }, onDeleteSet = {},
                        onNext = {}, onFinish = {},
                        onInitializeLocal = {}, onImportJson = {}, onDriveSync = {},
                        onExportJson = {}, onSignOut = {},
                        onReviseFinishedSet = { _, _, _, _, _, _ -> },
                        onDeleteFinishedSet = { _, _, _ -> },
                        onNavigateCreate = {}, onOpenClock = {})
                }
            }
        }
        composeRule.onNodeWithTag("homewrap")
            .performScrollToNode(hasText("Añadir nuevo entrenamiento"))
        composeRule.waitForIdle()
        composeRule.onNodeWithText("Añadir nuevo entrenamiento").assertExists()
        save(composeRule.onNodeWithTag("homewrap").captureToImage().asAndroidBitmap(),
            "home-add-workout-button.png")
    }

    @Test
    fun routineEditorBackNeutralConfirmGreen() {
        composeRule.setContent {
            MaterialTheme(colorScheme = reperaColorScheme(false)) {
                Surface(Modifier.testTag("editorwrap")) {
                    RoutineBlocksEditorScreen(
                        routine = RoutineEntry("r1", "Pierna pesada", true),
                        exercises = emptyList(), busy = false,
                        onReplace = {}, onBack = {})
                }
            }
        }
        composeRule.onNodeWithText("Volver").assertExists()
        composeRule.onNodeWithText("Guardar").assertExists()
        save(composeRule.onNodeWithTag("editorwrap").captureToImage().asAndroidBitmap(),
            "routine-editor-topbar.png")
    }

    @Test
    fun progressHistoryUnderTrainingTopic() {
        composeRule.setContent {
            MaterialTheme(colorScheme = reperaColorScheme(false)) {
                Surface(Modifier.testTag("progresswrap")) {
                    ProgressTab(busy = false, syncing = false, status = null,
                        overview = null, onInitializeLocal = {}, onImportJson = {},
                        onDriveSync = {}, onExportJson = {}, onSignOut = {},
                        onReviseFinishedSet = { _, _, _, _, _, _ -> },
                        onDeleteFinishedSet = { _, _, _ -> })
                }
            }
        }
        composeRule.onNodeWithTag("progress_list")
            .performScrollToNode(hasText("Ver historial completo"))
        composeRule.waitForIdle()
        save(composeRule.onNodeWithTag("progresswrap").captureToImage().asAndroidBitmap(),
            "progress-history-training.png")
    }
}
