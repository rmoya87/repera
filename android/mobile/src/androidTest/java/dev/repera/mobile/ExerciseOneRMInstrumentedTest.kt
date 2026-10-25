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
 @Test fun chartCeilingAndActualGestureSelectHistoricalPoint() {
  val entry=ExerciseEntry("bench","Press banca",true,true,muscleGroup="Pecho")
  val dates=listOf("2026-10-20T09:00:00Z","2026-10-22T09:00:00Z","2026-10-25T09:00:00Z").map {java.time.Instant.parse(it).toEpochMilli()}
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Column(Modifier.fillMaxSize().safeDrawingPadding()) {
   ExerciseEvolutionSection(entry,{_,_,_->dates.mapIndexed {i,d ->ExerciseProgressPoint(d,60.0+i*5,60.0+i*5,5)}},100.0,{},false)
  }}}
  compose.onAllNodesWithText("Tope 1RM · 100.0 kg").assertCountEquals(2)
  compose.onAllNodesWithText("Tope 1RM · 100.0 kg")[0].assertIsDisplayed()
  compose.onNodeWithTag("exercise_evolution_chart").performTouchInput {click(androidx.compose.ui.geometry.Offset(1f,center.y))}
  compose.onNodeWithText("Seleccionado:",substring=true).assertIsDisplayed()
  val expectedDate=java.time.Instant.ofEpochMilli(dates.first()).atZone(java.time.ZoneId.systemDefault()).format(java.time.format.DateTimeFormatter.ofPattern("d MMM yyyy",java.util.Locale.forLanguageTag("es")))
  compose.onNodeWithText(expectedDate).assertIsDisplayed()
  compose.onNodeWithTag("exercise_evolution_chart").performTouchInput {swipeLeft()}
  compose.onNodeWithText("Seleccionado:",substring=true).assertIsDisplayed()
  capture("ejercicio_evolucion_tope_cursor.png")
 }
 private fun capture(name:String) {
  compose.waitForIdle()
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val bitmap=InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()!!
  val values=android.content.ContentValues().apply {
   put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,name)
   put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
   put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
  }
  val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
  context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
 }
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
  compose.onNodeWithTag("suggested_load_value").assertTextContains("e1RM",substring=true)
  compose.onNodeWithTag("tested_onerm_edit").performClick()
  compose.onNodeWithTag("tested_onerm_input").performTextInput("100,04")
  compose.onNodeWithText("Guardar tope").performClick()
  compose.runOnIdle {assertEquals(100.0,tested!!,0.0)}
  compose.onNodeWithTag("suggested_load_value").assertTextContains("70% 1RM",substring=true)
  compose.onNodeWithTag("suggested_load_percent").performSemanticsAction(androidx.compose.ui.semantics.SemanticsActions.SetProgress) {it(95f)}
  compose.onNodeWithTag("suggested_load_value").assertTextContains("95% 1RM",substring=true)
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
  compose.onNodeWithTag("suggested_load_value").assertTextContains("e1RM",substring=true)
  compose.runOnIdle {assertNull(ExerciseLoadPreference.tested(JSONObject(String(local.read()!!)),"bench"))}
 }
}
