package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
class CompleteHistoryInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun fullHistoryRendersOlderThanTwentyAndExternalReadOnlyDetail() {
  val workouts=JSONArray()
  for(i in 0..24) {
   val start=java.time.LocalDate.of(2026,10,25).minusDays(i.toLong()).atTime(10,0).atZone(java.time.ZoneId.systemDefault()).toInstant()
   workouts.put(JSONObject().put("id","s$i").put("title","Registro $i").put("phase","finished")
    .put("startedAt",start.toString()).put("finishedAt",start.plusSeconds(3600).toString()).put("exercises",JSONArray()))
  }
  val state=JSONObject().put("exercises",JSONArray()).put("routines",JSONArray()).put("workouts",workouts)
  val external=ExternalHealthHistoryEntry("external","Paseo sintético",java.time.Instant.parse("2026-10-25T15:00:00Z").toEpochMilli(),0,35.0,"paquete.sintetico")
  val overview=StateOverview.fromBytes(state.toString().toByteArray())!!.copy(externalHealthHistory=listOf(external))
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Box(Modifier.fillMaxSize().safeDrawingPadding()) {
   CompleteHistoryScreen(overview,false,"synthetic-account",{_,_,_,_,_,_->},{_,_,_->},{},{_,_->},{emptyList()},onOpenExercise={_,_,_->})
  }}}
  compose.onNodeWithText("Paseo sintético").performClick()
  compose.onNodeWithText("35 min registrados",substring=true).assertIsDisplayed()
  compose.onNodeWithText("Fuente: paquete.sintetico").assertIsDisplayed()
  capture("historial_salud_externo_sintetico.png")
  compose.onNodeWithText("Cerrar").performClick()
  compose.onNodeWithTag("complete_history_list").performScrollToNode(hasText("Registro 24"))
  compose.onNodeWithText("Registro 24").assertIsDisplayed()
  capture("historial_completo_registro25.png")
 }
 private fun capture(name:String) {
  compose.waitForIdle();val context=InstrumentationRegistry.getInstrumentation().targetContext
  val bitmap=InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()!!
  val values=android.content.ContentValues().apply {
   put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,name);put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
   put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
  }
  val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
  context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
 }
}
