package dev.repera.mobile
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.*
import androidx.compose.runtime.*
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
class QuickNumericDraftInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun decimalSeparatorAndClearingRemainVisibleUntilValidation() {
  var last=""
  compose.setContent {MaterialTheme {QuickNumericField("40.0","Peso",true,decimal=true) {last=it}}}
  compose.onNode(hasSetTextAction()).performTextReplacement("42,")
  compose.onNode(hasSetTextAction()).assertTextContains("42,")
  Assert.assertEquals("42,",last)
  compose.onNode(hasSetTextAction()).performTextReplacement("42,5")
  compose.onNode(hasSetTextAction()).assertTextContains("42,5")
  Assert.assertEquals("42,5",last)
  compose.onNode(hasSetTextAction()).performTextClearance()
  Assert.assertEquals("",last)
 }
 @Test fun removingFirstRowDoesNotMoveItsDraftIntoNextRow() {
  compose.setContent {
   val ids=remember {mutableStateListOf("a","b")}
   MaterialTheme {Column {
    ids.forEach {id ->key(id) {QuickNumericField(if(id=="a") "10" else "20","Fila $id",true) {}}}
    Button(onClick={ids.remove("a")}) {Text("Quitar primera")}
   }}
  }
  compose.onAllNodes(hasSetTextAction())[1].performTextReplacement("27")
  compose.onNodeWithText("Quitar primera").performClick()
  compose.onAllNodes(hasSetTextAction()).assertCountEquals(1)
  compose.onNode(hasSetTextAction()).assertTextContains("27")
 }
}
