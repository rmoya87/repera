package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
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
    fun readinessMultidayCurve() {
        val today=LocalDate.of(2026,10,27)
        composeRule.setContent {
            MaterialTheme(colorScheme=reperaColorScheme(false)) {
                Surface(Modifier.testTag("readiness_curve_fixture")) {
                    androidx.compose.foundation.layout.Column {
                        androidx.compose.material3.Text("Recuperación · ejemplo de prueba")
                        dev.repera.mobile.DayPointLineChart(
                            listOf(2.0,4.0,7.0,9.0,6.0,3.0,8.0).mapIndexed {i,v ->
                                dev.repera.domain.ProgressDayPoint(today.minusDays((6-i).toLong()),v)
                            },valueFormat={"${it.toInt()}/10"},bounds=0.0..10.0,readinessStyle=true)
                    }
                }
            }
        }
        save(composeRule.onNodeWithTag("readiness_curve_fixture").captureToImage().asAndroidBitmap(),
            "readiness-multiday-curve.png")
    }

    @Test
    fun routeLibraryHeaderAndClose() {
        var closed=false
        composeRule.setContent {
            MaterialTheme(colorScheme=reperaColorScheme(false)) {
                Surface(Modifier.testTag("route_library_header")) {
                    dev.repera.mobile.RouteLibraryHeader {closed=true}
                }
            }
        }
        save(composeRule.onNodeWithTag("route_library_header").captureToImage().asAndroidBitmap(),
            "route-library-header.png")
        composeRule.onNodeWithContentDescription("Cerrar Mis rutas").performClick()
        org.junit.Assert.assertTrue(closed)
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
    @Test fun readinessPreviewUsesPlainAccentAtSameHeight() {
        composeRule.setContent {MaterialTheme {Surface(Modifier.testTag("readiness_plain_fixture")) {
            dev.repera.mobile.DayPointLineChart(listOf(5.0,6.0,7.0,6.0,8.0,7.0,9.0).mapIndexed {i,v ->
                dev.repera.domain.ProgressDayPoint(LocalDate.of(2026,10,21).plusDays(i.toLong()),v)
            },bounds=0.0..10.0,interactive=false,readinessStyle=true,readinessGradient=false)
        }}}
        save(composeRule.onNodeWithTag("readiness_plain_fixture").captureToImage().asAndroidBitmap(),"readiness-preview-plain.png")
    }

 @Test @Config(sdk=[35],qualifiers="w1000dp-h1400dp")
    fun recoveryExpandedHeight() {
        composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {
            Surface(Modifier.testTag("recovery_expanded_fixture")) {
                RecoveryHistoryCards(RecoveryState(readiness=null,sleepIndex=null,lastNightHours=null,
                    recentAverageSleepHours=null),ProgressTimeRange.WEEK,true,pro=false)
            }
        }}
        composeRule.onNodeWithTag("recovery_columns_2").assertExists()
        save(composeRule.onNodeWithTag("recovery_expanded_fixture").captureToImage().asAndroidBitmap(),"recovery-expanded-height.png")
    }
 @Test fun exercisePreviewUsesSessionsNotDates() {
        composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.testTag("exercise_preview_fixture")) {
            dev.repera.mobile.ProgressExerciseTrendPreview(LocalDate.of(2026,10,27))
        }}}
        composeRule.onNodeWithText("1").assertExists()
        composeRule.onNodeWithText("7").assertExists()
        save(composeRule.onNodeWithTag("exercise_preview_fixture").captureToImage().asAndroidBitmap(),"exercise-preview-sessions.png")
    }
 @Test fun sleepNightSkyObservedCurve() {
        val today=LocalDate.of(2026,10,27)
        composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.testTag("sleep_fixture")) {
            dev.repera.mobile.RecoverySleepChart(listOf(6.0,7.2,6.7,8.0,7.5).mapIndexed {i,h ->
                dev.repera.domain.RecoverySleepNight(today.minusDays((4-i).toLong()),h,1.0,1.0)
            },220.dp)
        }}}
        save(composeRule.onNodeWithTag("sleep_fixture").captureToImage().asAndroidBitmap(),"sleep-night-sky.png")
        composeRule.onNodeWithTag("recovery_sleep_chart").performClick()
        composeRule.onNodeWithText("25 oct 2026 · 6,7 h").assertExists()
    }
 @Test fun physiologyPreviewShowsOrdinalDaysAndCurved128Plot() {
        composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.testTag("physiology_fixture")) {
            dev.repera.mobile.RecoveryPhysiologyPreviewCard(LocalDate.of(2026,10,27))
        }}}
        composeRule.onNodeWithText("1").assertExists()
        val chart=composeRule.onNodeWithTag("physiology_preview_curve").captureToImage().asAndroidBitmap()
        org.junit.Assert.assertEquals(128,chart.height)
        save(composeRule.onNodeWithTag("physiology_fixture").captureToImage().asAndroidBitmap(),"physiology-preview-ordinal.png")
    }
 @Test fun physiologyObservedLinearAndEmptyAxes() {
        val today=LocalDate.of(2026,10,27)
        composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.testTag("physiology_observed_fixture")) {
            androidx.compose.foundation.layout.Column {
                dev.repera.mobile.RecoveryVitalTrend(listOf(45.0,62.0,49.0).mapIndexed {i,v ->dev.repera.domain.ProgressDayPoint(today.minusDays((2-i).toLong()),v)})
                dev.repera.mobile.RecoveryVitalTrend(listOf(dev.repera.domain.ProgressDayPoint(today,51.0)))
                dev.repera.mobile.RecoveryVitalTrend(emptyList())
            }
        }}}
        composeRule.onNodeWithText("51 ms").assertExists()
        val plot=composeRule.onNodeWithTag("physiology_observed_plot",useUnmergedTree=true).captureToImage().asAndroidBitmap()
        org.junit.Assert.assertEquals(128,plot.height)
        save(composeRule.onNodeWithTag("physiology_observed_fixture").captureToImage().asAndroidBitmap(),"physiology-observed-linear-empty.png")
        composeRule.onNodeWithTag("physiology_observed_plot",useUnmergedTree=true).performClick()
        composeRule.onNodeWithText("26 oct 2026: 62 ms",useUnmergedTree=true).assertExists()
    }
 @Test @Config(sdk=[35],qualifiers="w1000dp-h1400dp") fun physiologyObservedExpandedHeight() {
        composeRule.setContent {MaterialTheme {Surface(Modifier.testTag("physiology_observed_expanded")) {
            dev.repera.mobile.RecoveryVitalTrend(listOf(45.0,62.0,49.0).mapIndexed {i,v ->dev.repera.domain.ProgressDayPoint(LocalDate.of(2026,10,21+i),v)},dev.repera.mobile.physiologyChartHeightDp(492f,true,true).dp)
        }}}
        org.junit.Assert.assertEquals(162,composeRule.onNodeWithTag("physiology_observed_plot",useUnmergedTree=true).captureToImage().asAndroidBitmap().height)
        save(composeRule.onNodeWithTag("physiology_observed_expanded").captureToImage().asAndroidBitmap(),"physiology-observed-expanded.png")
    }
 @Test fun physiologyBarsShareSelectedDayAcrossIndependentScales() {
        val day=LocalDate.of(2026,10,21)
        val rest=listOf(0L to 66.0,2L to 60.0,6L to 58.0).map {dev.repera.domain.ProgressDayPoint(day.plusDays(it.first),it.second)}
        val breathing=listOf(0L to 16.0,3L to 13.0,6L to 14.0).map {dev.repera.domain.ProgressDayPoint(day.plusDays(it.first),it.second)}
        composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.testTag("physiology_bars_fixture")) {
            androidx.compose.foundation.layout.Column {
                dev.repera.mobile.RecoveryVitalBars(rest,breathing)
                dev.repera.mobile.RecoveryVitalBars(listOf(rest.last()),emptyList())
            }
        }}}
        save(composeRule.onNodeWithTag("physiology_bars_fixture").captureToImage().asAndroidBitmap(),"physiology-bars-observed.png")
        composeRule.onNodeWithTag("physiology_bar_breathing").performClick()
        composeRule.onNodeWithText("23 oct 2026: 60 lpm").assertExists()
        composeRule.onNodeWithText("24 oct 2026: 13 resp/min").assertExists()
        save(composeRule.onNodeWithTag("physiology_bars_fixture").captureToImage().asAndroidBitmap(),"physiology-bars-selected.png")
    }
 @Test fun caloriesCurveAndSelection() {
        val day=LocalDate.of(2026,10,27)
        composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.testTag("calories_fixture")) {
            dev.repera.mobile.ProgressCaloriesPlot(dev.repera.mobile.ProgressPreview.charts(day,true),preview=true,today=day)
        }}}
        org.junit.Assert.assertEquals(210,composeRule.onNodeWithTag("calories_observed_plot",useUnmergedTree=true).captureToImage().asAndroidBitmap().height)
        save(composeRule.onNodeWithTag("calories_fixture").captureToImage().asAndroidBitmap(),"calories-preview-curve.png")
        composeRule.onNodeWithTag("calories_observed_plot",useUnmergedTree=true).performClick()
        composeRule.onNodeWithText("24 oct 2026: 721 kcal",useUnmergedTree=true).assertExists()
    }
 @Test fun caloriesEmptyKeepsAxesWithoutFabricatedSamples() {
        val day=LocalDate.of(2026,10,27)
        composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.testTag("calories_empty_fixture")) {
            dev.repera.mobile.ProgressCaloriesPlot(dev.repera.mobile.ProgressPreview.charts(day,true).copy(calories=emptyList(),caloriesTotal=0.0),today=day)
        }}}
        org.junit.Assert.assertEquals(210,composeRule.onNodeWithTag("empty_health_chart_axes",useUnmergedTree=true).captureToImage().asAndroidBitmap().height)
        composeRule.onNodeWithTag("calories_observed_plot",useUnmergedTree=true).assertDoesNotExist()
        save(composeRule.onNodeWithTag("calories_empty_fixture").captureToImage().asAndroidBitmap(),"calories-empty-axes.png")
    }
}
