package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.Assert.*
import dev.repera.domain.*
class ProgressRecordsScoreInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun allRecordsRevealSixthExerciseAndNavigateWithoutTruncation() {
  var selected:String?=null
  val records=(0..5).map {PersonalRecord("e$it","Ejercicio $it",60.0,5,1792918800000L+it*1000)}
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Box(Modifier.fillMaxSize().safeDrawingPadding()) {
   LazyColumn {item {ProgressRecordsCard(records) {selected=it}}}
  }}}
  compose.onNodeWithText("Ejercicio 0").assertDoesNotExist()
  compose.onNodeWithText("Ver todos los récords (6)").performScrollTo().performClick()
  compose.onNodeWithText("Ejercicio 0").performScrollTo().assertIsDisplayed()
  capture("progreso_todos_records.png")
  compose.onNodeWithText("Ejercicio 0").performClick();compose.runOnIdle {assertEquals("e0",selected)}
 }
 @Test fun allPeriodExercisesRevealSixthWithoutFallingBackToFullCatalog() {
  var selected:String?=null
  val exercises=(0..5).map {ProgressExerciseRow("e$it","Ejercicio $it",60.0)}
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Box(Modifier.fillMaxSize().safeDrawingPadding()) {
   LazyColumn {item {ProgressExercisesCard(exercises) {selected=it}}}
  }}}
  compose.onNodeWithText("Ejercicio 5").assertDoesNotExist()
  compose.onNodeWithText("Ver más").performScrollTo().performClick()
  compose.onNodeWithText("Ejercicio 5").performScrollTo().performClick()
  compose.runOnIdle {assertEquals("e5",selected)}
 }
 @Test fun verifiedScoresAndEmptyAxesAreRenderedWithoutMadeUpMeasurements() {
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Box(Modifier.fillMaxSize().safeDrawingPadding()) {
   SessionScoreProgressCard(listOf(ProgressDayPoint(java.time.LocalDate.of(2026,10,24),6.0),ProgressDayPoint(java.time.LocalDate.of(2026,10,25),8.0)))
  }}}
  compose.onNodeWithText("7/10").assertIsDisplayed();capture("progreso_puntuaciones.png")
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
