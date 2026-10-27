package dev.repera.mobile

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import dev.repera.domain.ProgressTimeRange
import dev.repera.domain.RecoveryEngine
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Apple 188624cc: tiles del ultimo dia registrado (SpO2, T nocturna,
 *  Recuperacion cardiaca 1 min) bajo las graficas de constantes. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class RecoveryLastDayTilesTest {

    @get:Rule val composeRule = createComposeRule()

    private fun state(vitals: List<RecoveryEngine.DailyVitals>) = RecoveryState(
        readiness = null, sleepIndex = null, lastNightHours = null,
        recentAverageSleepHours = null, vitals = vitals)

    @Test fun latestDayTilesShownWithRecordedValues() {
        val today = LocalDate.now()
        composeRule.setContent {
            MaterialTheme {
                RecoveryHistoryCards(state(listOf(
                    RecoveryEngine.DailyVitals(today.minusDays(2),
                        oxygenSaturationPercent = 97.0),
                    RecoveryEngine.DailyVitals(today,
                        oxygenSaturationPercent = 98.4,
                        wristTemperatureCelsius = 33.25,
                        heartRateRecoveryBpm = 27.6))),
                    ProgressTimeRange.WEEK, true)
            }
        }
        composeRule.onNodeWithTag("recovery_tile_spo2", useUnmergedTree = true).assertExists()
        composeRule.onNodeWithTag("recovery_tile_temp", useUnmergedTree = true).assertExists()
        composeRule.onNodeWithTag("recovery_tile_hr_recovery", useUnmergedTree = true).assertExists()
        composeRule.onNodeWithText("T nocturna", useUnmergedTree = true).assertExists()
        composeRule.onNodeWithText("28 lpm", useUnmergedTree = true).assertExists()
    }

    @Test fun absentValuesPaintNoTiles() {
        val today = LocalDate.now()
        composeRule.setContent {
            MaterialTheme {
                RecoveryHistoryCards(state(listOf(
                    RecoveryEngine.DailyVitals(today, hrvMilliseconds = 42.0))),
                    ProgressTimeRange.WEEK, true)
            }
        }
        composeRule.onNodeWithTag("recovery_tile_spo2", useUnmergedTree = true).assertDoesNotExist()
        composeRule.onNodeWithTag("recovery_tile_temp", useUnmergedTree = true).assertDoesNotExist()
        composeRule.onNodeWithTag("recovery_tile_hr_recovery", useUnmergedTree = true).assertDoesNotExist()
    }

    @Test fun noVitalsPaintNoTiles() {
        composeRule.setContent {
            MaterialTheme {
                RecoveryHistoryCards(state(emptyList()), ProgressTimeRange.WEEK, true)
            }
        }
        composeRule.onNodeWithTag("recovery_tile_spo2", useUnmergedTree = true).assertDoesNotExist()
        composeRule.onNodeWithTag("recovery_tile_hr_recovery", useUnmergedTree = true).assertDoesNotExist()
    }
    @Test fun historicalExtrasDoNotLeakIntoLatestDayTilesOrGraphs() {
        val today=LocalDate.now()
        composeRule.setContent {MaterialTheme {RecoveryHistoryCards(state(listOf(
            RecoveryEngine.DailyVitals(today.minusDays(2),oxygenSaturationPercent=97.0,wristTemperatureCelsius=33.0),
            RecoveryEngine.DailyVitals(today,hrvMilliseconds=42.0))),ProgressTimeRange.WEEK,true)}}
        composeRule.onNodeWithTag("recovery_tile_spo2",useUnmergedTree=true).assertDoesNotExist()
        composeRule.onNodeWithTag("recovery_tile_temp",useUnmergedTree=true).assertDoesNotExist()
        composeRule.onNodeWithText("Saturación de oxígeno").assertDoesNotExist()
        composeRule.onNodeWithText("Temperatura de muñeca durante sueño registrado").assertDoesNotExist()
    }
    @Test fun latestTilesRemainIndependentOfSelectedChartRange() {
        val today=LocalDate.now()
        composeRule.setContent {MaterialTheme {RecoveryHistoryCards(state(listOf(
            RecoveryEngine.DailyVitals(today.minusDays(40),oxygenSaturationPercent=98.0,wristTemperatureCelsius=33.0))),ProgressTimeRange.WEEK,true)}}
        composeRule.onNodeWithTag("recovery_tile_spo2",useUnmergedTree=true).assertExists()
        composeRule.onNodeWithTag("recovery_tile_temp",useUnmergedTree=true).assertExists()
        composeRule.onNodeWithText("98 %",useUnmergedTree=true).assertExists()
    }
}
