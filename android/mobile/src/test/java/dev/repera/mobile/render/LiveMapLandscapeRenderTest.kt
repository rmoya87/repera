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
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.assertIsDisplayed
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
 @Test
 @Config(sdk=[35],qualifiers="w360dp-h900dp")
 fun routeLibraryEmptyScreenAndCloseReturnToMap() {
  val context=ApplicationProvider.getApplicationContext<android.content.Context>()
  LiveActivityRuntime.forAccount(context,"render-empty-library").choose(LiveSport.RUNNING)
  composeRule.setContent {
   MaterialTheme(colorScheme=reperaColorScheme(false)) {
    Surface(Modifier.testTag("library_root")) {
     LiveActivityScreen("render-empty-library",onSaved={},onOpenTools={})
    }
   }
  }
  composeRule.onNodeWithText("Rutas").performClick()
  composeRule.onNodeWithText("Mis rutas").assertExists()
  composeRule.onNodeWithText("Todavía no hay rutas").assertExists()
  val bmp=composeRule.onNodeWithTag("library_root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/route-library-empty-screen.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
  composeRule.onNodeWithContentDescription("Cerrar Mis rutas").performClick()
  composeRule.onNodeWithText("Mis rutas").assertDoesNotExist()
  composeRule.onNodeWithText("Mapa del recorrido · guía GPX orientativa").assertExists()
 }
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
 @Test fun pausedLandscapeKeepsMetricsAndStatusSeparateWithoutGps() {
  val context=ApplicationProvider.getApplicationContext<android.content.Context>()
  val runtime=LiveActivityRuntime.forAccount(context,"render-paused-landscape")
  // Pure state fixture only: do not call runtime.start(), service or sensors.
  runtime.state.choose(LiveSport.RUNNING)
  val now=System.currentTimeMillis()
  runtime.state.start(now-90_000,"fake-fixture")
  runtime.state.pause(now)
  composeRule.setContent {
   MaterialTheme(colorScheme=reperaColorScheme(false)) {
    Surface(Modifier.testTag("paused_root")) {
     LiveActivityScreen("render-paused-landscape",onSaved={},onOpenTools={})
    }
   }
  }
  composeRule.onNodeWithText("Reanudar").assertExists()
  val bmp=composeRule.onNodeWithTag("paused_root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/live-map-landscape-paused.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }
 @Test fun recordingLandscapeKeepsMetricsAndStatusSeparateWithoutGps() {
  val context=ApplicationProvider.getApplicationContext<android.content.Context>()
  val runtime=LiveActivityRuntime.forAccount(context,"render-recording-landscape")
  // Pure state fixture only: do not call runtime.start(), service or sensors.
  runtime.state.choose(LiveSport.RUNNING)
  val now=System.currentTimeMillis()
  runtime.state.start(now-90_000,"fake-fixture")
  composeRule.setContent {
   MaterialTheme(colorScheme=reperaColorScheme(false)) {
    Surface(Modifier.testTag("recording_root")) {
     LiveActivityScreen("render-recording-landscape",onSaved={},onOpenTools={})
    }
   }
  }
  composeRule.onNodeWithText("Pausar").assertExists()
  val bmp=composeRule.onNodeWithTag("recording_root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/live-map-landscape-recording.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }
 @Test
 @Config(sdk=[35],qualifiers="w620dp-h360dp")
 fun compactPausedLandscapeKeepsMetricsAndStatusSeparateWithoutGps() {
  val context=ApplicationProvider.getApplicationContext<android.content.Context>()
  val runtime=LiveActivityRuntime.forAccount(context,"render-compact-paused-landscape")
  // Pure state fixture only: do not call runtime.start(), service or sensors.
  runtime.state.choose(LiveSport.RUNNING)
  val now=System.currentTimeMillis()
  runtime.state.start(now-90_000,"fake-fixture")
  runtime.state.pause(now)
  composeRule.setContent {
   MaterialTheme(colorScheme=reperaColorScheme(false)) {
    Surface(Modifier.testTag("compact_root")) {
     LiveActivityScreen("render-compact-paused-landscape",onSaved={},onOpenTools={})
    }
   }
  }
  composeRule.onNodeWithText("Reanudar").assertExists()
  val bmp=composeRule.onNodeWithTag("compact_root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/live-map-landscape-compact.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
  composeRule.onNodeWithText("Descartar").performScrollTo().assertIsDisplayed()
  composeRule.onNodeWithText("Voz activada").performScrollTo().assertIsDisplayed()
 }
}
