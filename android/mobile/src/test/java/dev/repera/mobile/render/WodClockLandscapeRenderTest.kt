package dev.repera.mobile.render
import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.graphics.asAndroidBitmap
import dev.repera.mobile.*
import org.junit.Assert.assertTrue
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
@Config(sdk=[35],qualifiers="w620dp-h360dp")
class WodClockLandscapeRenderTest {
 @get:Rule val rule=createComposeRule()
 @Test fun intervalClockFitsCompactLandscape() {
  val active=ActiveWorkout("fixture","EMOM de prueba",0,1,"WOD",0,null,null,
   allowsWeight=false,sets=emptyList(),wod=WodExecution("emom","PER_MOVEMENT_SETS",false,"Intervalos de prueba",emptyList(),intervalSeconds=60,rounds=12))
  rule.setContent {MaterialTheme {Box(Modifier.fillMaxSize().testTag("clock-root")) {
   WodClockScreen(active,false,WodTimerState(65000,false),{}, {}, {},requestNotificationPermission=false)
  }}}
  rule.onNodeWithText("Reanudar").assertIsDisplayed()
  val clock=rule.onNodeWithContentDescription("Ronda 2, 0 minutos 55 segundos")
  clock.assertIsDisplayed()
  val bounds=clock.fetchSemanticsNode().boundsInRoot
  val root=rule.onNodeWithTag("clock-root").fetchSemanticsNode().boundsInRoot
  assertTrue(bounds.left>=root.left && bounds.right<=root.right)
  val control=rule.onNodeWithText("Reanudar").fetchSemanticsNode().boundsInRoot
  assertTrue(control.top>bounds.bottom)
  val bmp=rule.onNodeWithTag("clock-root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/wod-clock-landscape.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }
}
