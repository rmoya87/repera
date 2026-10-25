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
import dev.repera.mobile.monetization.*
class ProgressTopicsInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 private fun show(free:Boolean) {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val state=JSONObject().put("exercises",JSONArray()).put("routines",JSONArray()).put("workouts",JSONArray())
   .put("bodyWeights",JSONArray().put(JSONObject().put("id","private-weight").put("date",java.time.Instant.now().toString()).put("weightKg",123.4)))
  val overview=StateOverview.fromBytes(state.toString().toByteArray())!!
  val manager=if(free) SubscriptionManager(freeUsage=FreeUsageStore(java.io.File(context.cacheDir,"topics-${java.util.UUID.randomUUID()}.json"))) else null
  compose.setContent {CompositionLocalProvider(LocalSubscriptions provides manager) {MaterialTheme(colorScheme=reperaColorScheme(false)) {
   Box(Modifier.fillMaxSize().safeDrawingPadding()) {ProgressTab(false,false,null,overview,{},{},{},{},{},{_,_,_,_,_,_->},{_,_,_->})}
  }}}
 }
 @Test fun proTopicsSeparateTrainingActivityAndRecoveryWithEmptyAxesAndRealWeight() {
  show(false)
  compose.onNodeWithTag("progress_topic_1").performClick()
  compose.onNodeWithTag("progress_list").performScrollToNode(hasText("Todavía no hay puntuaciones basadas en tu historial."))
  compose.onNodeWithText("Todavía no hay puntuaciones basadas en tu historial.").assertIsDisplayed()
  capture("progreso_actividad_sin_puntuaciones.png")
  compose.onNodeWithTag("progress_list").performScrollToNode(hasText("Peso corporal"))
  compose.onNodeWithText("Último:",substring=true).assertIsDisplayed()
  capture("progreso_actividad_peso_real.png")
  compose.onNodeWithTag("progress_list").performScrollToIndex(0)
  compose.onNodeWithTag("progress_topic_2").performClick()
  compose.onNodeWithText("Sin datos de recuperación.",substring=true).assertIsDisplayed()
  compose.onNodeWithText("Resultados recientes").assertDoesNotExist()
  capture("progreso_recuperacion_vacio.png")
 }
 @Test fun freeActivityIsExplicitExampleAndNeverRendersPrivateWeight() {
  show(true)
  compose.onNodeWithTag("progress_topic_1").performClick()
  compose.onNodeWithTag("progress_list").performScrollToNode(hasText("Peso corporal · ejemplo"))
  compose.onNodeWithText("Peso corporal · ejemplo").assertIsDisplayed()
  compose.onNodeWithText("Datos ficticios. Objetivo de ejemplo:74kg").assertIsDisplayed()
  compose.onNodeWithText("Último:",substring=true).assertDoesNotExist()
  capture("progreso_actividad_gratis_ejemplo.png")
 }
 private fun capture(name:String) {
  compose.waitForIdle();val instrument=InstrumentationRegistry.getInstrumentation();val context=instrument.targetContext
  instrument.waitForIdleSync()
  Thread.sleep(300)
  val root=instrument.uiAutomation.rootInActiveWindow
  org.junit.Assert.assertEquals("Screenshot must show the app, not a system overlay",instrument.targetContext.packageName,root?.packageName?.toString())
  val bitmap=instrument.uiAutomation.takeScreenshot()!!
  val values=android.content.ContentValues().apply {
   put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,name);put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
   put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
  }
  val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
  context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
 }
}
