package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.Assert.*
class FailureControlInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun failureIsExplicitAndWarmupCannotInheritFailureOrHiddenTechnique() {
  var failure:Boolean?=null;var warmup:Boolean?=null;var effort:Double?=null;var drops=0
  val active=ActiveWorkout("failure","Fuerza",0,1,"Press banca",0,5,60.0,allowsWeight=true,sets=emptyList())
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.fillMaxSize().safeDrawingPadding()) {
   LazyColumn {item {ActiveWorkoutCard(active,false,
    {_,_,r,w,_,_,_,f->effort=r;warmup=w;failure=f},{_,_,_,_,_,_->},{},{},{},
    onLogDropSet={_,_,_,_,_->drops++})}}
  }}}
  compose.onNodeWithTag("set_to_failure").performScrollTo().performClick()
  compose.onNodeWithText("Al fallo").assertIsDisplayed()
  capture("entreno_al_fallo.png")
  compose.onNodeWithText("Registrar serie").performScrollTo().performClick()
  compose.runOnIdle {assertEquals(true,failure);assertEquals(false,warmup);assertEquals(0.0,effort!!,0.0)}
  compose.onNodeWithText("Dropset").performScrollTo().performClick()
  compose.onNodeWithText("Serie de calentamiento").performScrollTo()
  compose.onNode(isToggleable() and hasAnySibling(hasText("Serie de calentamiento"))).performClick()
  compose.onNodeWithTag("set_to_failure").assertDoesNotExist()
  compose.onNodeWithText("Registrar serie").performScrollTo().performClick()
  compose.runOnIdle {assertEquals(false,failure);assertEquals(true,warmup);assertNull(effort);assertEquals(0,drops)}
 }
 private fun capture(name:String) {
  compose.waitForIdle();val instrument=InstrumentationRegistry.getInstrumentation();val context=instrument.targetContext
  val bitmap=instrument.uiAutomation.takeScreenshot()!!
  val values=android.content.ContentValues().apply {
   put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,name);put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
   put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
  }
  val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
  context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
 }
}
