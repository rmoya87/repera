package dev.repera.mobile.render
import android.graphics.Bitmap
import androidx.compose.runtime.*
import androidx.compose.material3.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.unit.dp
import dev.repera.mobile.*
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk=[35],qualifiers="w360dp-h1000dp")
class PlayUnitsRenderTest {
 @get:Rule val rule=createComposeRule()
 @Test fun liveRowsToggleUnitOnlyOnExplicitTapWithoutConvertingQuantity() {
  var savedUnit:String?=null
  var savedRows:List<ActiveSessionDraft.Row> = emptyList()
  val rows=listOf(LiveRowSummary("row",20,16.0,null,null,null,false))
  val active=ActiveWorkout("fixture","Prueba",0,1,"Walking lunge",0,20,16.0,allowsWeight=true,sets=emptyList(),
   repsMetersToggle=true,liveRows=rows,quantityCap=100000)
  rule.setContent {MaterialTheme {Surface(Modifier.testTag("units-root")) {
   CompositionLocalProvider(LocalPersistLiveRows provides {_,_,r,u ->savedRows=r;savedUnit=u}) {
    Column(Modifier.padding(16.dp)) {Text("Walking lunge · ejemplo de prueba");LiveSetRows(active,rows,"rir")}
   }
  }}}
  rule.runOnIdle {assertNull(savedUnit)}
  rule.onNodeWithText("Metros").performClick()
  rule.waitForIdle()
  rule.runOnIdle {assertEquals("meters",savedUnit);assertEquals(20,savedRows.single().reps);assertEquals(16.0,savedRows.single().weightKg!!,0.0)}
  rule.onNodeWithText("Calorías").assertDoesNotExist()
  val bmp=rule.onNodeWithTag("units-root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/play-units.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }
}
