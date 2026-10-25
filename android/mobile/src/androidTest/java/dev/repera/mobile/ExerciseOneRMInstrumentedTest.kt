package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
import org.junit.Assert.*
class ExerciseOneRMInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun editorPersistsTestedPriorityAndClearFallsBackToEstimated() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-onerm-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(context,account)
  local.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","bench").put("name","Press banca")))
   .put("workouts",JSONArray()).put("routines",JSONArray()).toString().toByteArray())
  val repo=WorkoutRepository(context,account)
  var tested by mutableStateOf<Double?>(null)
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Column(Modifier.fillMaxSize().safeDrawingPadding()) {
   TestedOneRMEditor(tested,false) {repo.setTestedOneRM("bench",it);tested=ExerciseLoadPreference.tested(JSONObject(String(local.read()!!)),"bench")}
   SuggestedExerciseLoadCard(tested,80.0,2.5)
  }}}
  compose.onNodeWithTag("suggested_load_value").assertTextContains("e1RM")
  compose.onNodeWithTag("tested_onerm_edit").performClick()
  compose.onNodeWithTag("tested_onerm_input").performTextInput("100,04")
  compose.onNodeWithText("Guardar tope").performClick()
  compose.runOnIdle {assertEquals(100.0,tested!!,0.0)}
  compose.onNodeWithTag("suggested_load_value").assertTextContains("70% 1RM")
  val instrument=InstrumentationRegistry.getInstrumentation();val bitmap=instrument.uiAutomation.takeScreenshot()!!
  val values=android.content.ContentValues().apply {
   put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,"ejercicio_tope_carga.png")
   put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
   put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
  }
  val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
  context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
  compose.onNodeWithTag("tested_onerm_edit").performClick()
  compose.onNodeWithTag("tested_onerm_input").performTextClearance()
  compose.onNodeWithText("Guardar tope").performClick()
  compose.onNodeWithTag("suggested_load_value").assertTextContains("e1RM")
  compose.runOnIdle {assertNull(ExerciseLoadPreference.tested(JSONObject(String(local.read()!!)),"bench"))}
 }
}
