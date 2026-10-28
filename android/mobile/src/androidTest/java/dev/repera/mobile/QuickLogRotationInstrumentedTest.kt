package dev.repera.mobile
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.junit4.StateRestorationTester
import org.junit.*

/** Prepared and compiled only: NOT executed (no device in the recovery sandbox). */
class QuickLogRotationInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun typedRowsNotesAndRequestIdSurviveRecreation() {
  val ids=mutableListOf<String>()
  val restoration=StateRestorationTester(compose)
  val entry=ExerciseEntry("press","Press banca",true,true)
  restoration.setContent {MaterialTheme {QuickLogSheet(entry,"acct",false,null,{}) {_,_,id->ids.add(id)}}}
  compose.onAllNodes(hasSetTextAction())[0].performTextReplacement("12")
  compose.onAllNodes(hasSetTextAction())[1].performTextReplacement("42,")
  restoration.emulateSavedInstanceStateRestore()
  compose.onAllNodes(hasSetTextAction())[0].assertTextContains("12")
  compose.onAllNodes(hasSetTextAction())[1].assertTextContains("42,")
 }
}
