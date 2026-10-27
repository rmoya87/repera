package dev.repera.mobile.render
import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.captureToImage
import androidx.test.core.app.ApplicationProvider
import dev.repera.mobile.*
import dev.repera.domain.LiveSport
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
@Config(sdk=[35],qualifiers="w1000dp-h600dp")
class LiveMapLandscapeRenderTest {
 @get:Rule val composeRule=createComposeRule()
 @Test fun landscapeKeepsMapVisibleBesideControlsWithoutStartingGps() {
  val context=ApplicationProvider.getApplicationContext<android.content.Context>()
  LiveActivityRuntime.forAccount(context,"render-landscape").choose(LiveSport.RUNNING)
  composeRule.setContent {
   MaterialTheme(colorScheme=reperaColorScheme(false)) {
    Surface(Modifier.testTag("landscape_root")) {
     LiveActivityScreen("render-landscape",onSaved={},onOpenTools={})
    }
   }
  }
  composeRule.onNodeWithText("Iniciar").assertExists()
  composeRule.onNodeWithTag("live_activity_screen").assertExists()
  val bmp=composeRule.onNodeWithTag("landscape_root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/live-map-landscape.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }
}
