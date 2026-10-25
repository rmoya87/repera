package dev.repera.mobile
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.Assert.*
class CenterDirectoryInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun linkingWaitsForExplicitChoiceAndSendsSelectedKindAndNote() {
  val org=BusinessCenterStore.Organization("org","Centro sintético","gym",null,null,"Solo pruebas")
  var count=0;var kind="";var note:String?=null
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {
   CenterDirectoryDialog(true,listOf(org),false,false,emptySet(),{}, {_,k,n ->count++;kind=k;note=n},{})
  }}
  compose.onNodeWithText("Centro sintético").performClick()
  compose.runOnIdle {assertEquals(0,count)}
  compose.onNodeWithText("Entrenador personal").performClick()
  compose.onNodeWithText("Nota para el centro (opcional)").performTextInput("Turno tarde")
  capture("centro_solicitud_vinculo_sintetica.png")
  compose.onNodeWithText("Vincularme y continuar").performClick()
  compose.runOnIdle {assertEquals(1,count);assertEquals("appointment",kind);assertEquals("Turno tarde",note)}
 }
 @Test fun leavingRequiresSeparateConfirmationAndCancelDoesNothing() {
  val org=BusinessCenterStore.Organization("org","Centro sintético","gym",null,null,null)
  var count=0
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {
   LinkedCenterDialog(org,BusinessCenterStore.Snapshot(),false,{count++},{})
  }}
  compose.onNodeWithText("Desvincularme").performClick()
  compose.onNodeWithText("Cancelar").performClick()
  compose.runOnIdle {assertEquals(0,count)}
  compose.onNodeWithText("Desvincularme").performClick()
  compose.onAllNodesWithText("Desvincularme").onLast().performClick()
  compose.runOnIdle {assertEquals(1,count)}
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
