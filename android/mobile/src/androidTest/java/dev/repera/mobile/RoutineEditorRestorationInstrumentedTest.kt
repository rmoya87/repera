package dev.repera.mobile
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.junit4.StateRestorationTester
import org.junit.*
class RoutineEditorRestorationInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun editorRestoresUnsavedTitleAndBlockTitleWithoutSaving() {
  var saved=false
  val restoration=StateRestorationTester(compose)
  restoration.setContent {MaterialTheme {
   RoutineBlocksEditorScreen(RoutineEntry("draft","Nueva rutina",true),emptyList(),false,
    onReplace={saved=true},onBack={},editableTitle=true,accountId="fixture")
  }}
  compose.onNodeWithTag("new_template_title").performTextReplacement("Mi borrador")
  compose.onNodeWithText("Título del bloque").performTextReplacement("Bloque sin guardar")
  restoration.emulateSavedInstanceStateRestore()
  compose.onNodeWithTag("new_template_title").assertTextContains("Mi borrador")
  compose.onNodeWithText("Título del bloque").assertTextContains("Bloque sin guardar")
  compose.runOnIdle {Assert.assertFalse(saved)}
 }
 @Test fun restoredEditorStateDoesNotCrossAccountAtSameCompositionSlot() {
  var account="accountA"
  val restoration=StateRestorationTester(compose)
  restoration.setContent {MaterialTheme {
   RoutineBlocksEditorScreen(RoutineEntry("same-routine","Original",true),emptyList(),false,
    onReplace={},onBack={},editableTitle=true,accountId=account)
  }}
  compose.onNodeWithTag("new_template_title").performTextReplacement("Privado A")
  account="accountB"
  restoration.emulateSavedInstanceStateRestore()
  compose.onNodeWithTag("new_template_title").assertTextContains("Original")
  compose.onNodeWithText("Privado A").assertDoesNotExist()
 }
}
