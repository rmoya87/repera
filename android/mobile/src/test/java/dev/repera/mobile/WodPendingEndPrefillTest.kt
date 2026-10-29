package dev.repera.mobile
import androidx.compose.runtime.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTextReplacement
import org.junit.Rule
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
@RunWith(RobolectricTestRunner::class)
@Config(sdk=[35])
class WodPendingEndPrefillTest {
 @get:Rule val rule=createComposeRule()
 @Test fun prefillDoesNotConsumeBeforeSaveAndSurvivesLeavingCard() {
  var visible by mutableStateOf(true)
  val actions=mutableListOf<String>()
  var timer by mutableStateOf(WodTimerState(65000,false,"userFinished",65))
  val active=ActiveWorkout("s","For Time",0,1,exerciseName="WOD",completedSets=0,prescribedQuantity=null,prescribedWeightKg=null,
   allowsWeight=false,sets=emptyList(),wod=WodExecution("forTime","ELAPSED_TIME",false,"WOD",emptyList()))
  rule.setContent {MaterialTheme {
   if(visible) WodScoreCard(active,false,timer,
    onTimerAction={actions.add(it)},onTimerTick={},onSave={_,_,_->},onMovement={_,_,_,_->},
    onCompleteBlock={},onReviseMovement={_,_,_->},onDeleteMovement={},onFinish={},onOpenClock={})
  }}
  rule.onNodeWithText("05").assertExists()
  rule.runOnIdle {visible=false}
  rule.waitForIdle()
  rule.runOnIdle {visible=true}
  rule.waitForIdle()
  rule.onNodeWithText("05").assertExists()
  rule.onNodeWithText("05").performTextReplacement("17")
  rule.runOnIdle {timer=WodTimerState(125000,false,"userFinished",125)}
  rule.waitForIdle()
  rule.onNodeWithText("17").assertExists()
  rule.runOnIdle {assertFalse(actions.contains("consumePendingEnd"))}
 }
}
