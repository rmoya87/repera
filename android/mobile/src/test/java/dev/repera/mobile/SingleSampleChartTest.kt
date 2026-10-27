package dev.repera.mobile

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.assertCountEquals
import dev.repera.domain.ProgressDayPoint
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[35])
class SingleSampleChartTest {
 @get:Rule val composeRule=createComposeRule()
 @Test fun oneSampleHasOneDateAndNoInventedTrend() {
  val day=LocalDate.of(2026,10,27)
  composeRule.setContent { MaterialTheme {
   DayPointLineChart(listOf(ProgressDayPoint(day,98.4)))
  } }
  composeRule.onNodeWithTag("day_point_single_sample").assertExists()
  composeRule.onNodeWithTag("day_point_line_chart").assertDoesNotExist()
  composeRule.onAllNodesWithText(day.format(reperaDayFormatter)).assertCountEquals(1)
  composeRule.onAllNodesWithText("Una medición; aún no hay tendencia.").assertCountEquals(1)
 }
 @Test fun twoConsecutiveDaysDoNotRepeatMidpointDate() {
  val day=LocalDate.of(2026,10,26)
  composeRule.setContent { MaterialTheme {
   DayPointLineChart(listOf(ProgressDayPoint(day,97.0),ProgressDayPoint(day.plusDays(1),98.4)))
  } }
  composeRule.onAllNodesWithText("26 oct",useUnmergedTree=true).assertCountEquals(1)
  composeRule.onAllNodesWithText("27 oct",useUnmergedTree=true).assertCountEquals(1)
 }
}
