package dev.repera.mobile

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import dev.repera.domain.WeeklyWorkoutDay
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test

class HomeWeeklyProgressInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    private val monday=LocalDate.of(2026,10,26)
    @Test fun weeklySummaryDistinguishesWorkoutsFromDaysAndAnnouncesPlanState() {
        val days=(0L..6L).map {offset -> WeeklyWorkoutDay(monday.plusDays(offset),if(offset==0L) 2 else 0,offset==1L)}
        compose.setContent {MaterialTheme {HomeWeeklyProgressCard(days,3)}}
        compose.onNodeWithText("2 de 3 entrenos").assertIsDisplayed()
        compose.onNodeWithContentDescription("LU 26: entrenamiento completado").assertExists()
        compose.onNodeWithContentDescription("MA 27: entrenamiento planificado").assertExists()
        compose.onNodeWithContentDescription("MI 28: sin entrenamiento").assertExists()
    }
    @Test fun missingGoalSummarizesTrainedDaysWithoutInventingTarget() {
        val days=(0L..6L).map {offset -> WeeklyWorkoutDay(monday.plusDays(offset),if(offset==0L) 2 else 0,false)}
        compose.setContent {MaterialTheme {HomeWeeklyProgressCard(days,null)}}
        compose.onNodeWithText("1 día entrenado").assertIsDisplayed()
        compose.onAllNodesWithText("de",substring=true).assertCountEquals(0)
    }
}
