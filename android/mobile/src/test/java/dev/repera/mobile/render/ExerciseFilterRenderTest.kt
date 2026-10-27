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
class ExerciseFilterRenderTest {
 @get:Rule val rule=createComposeRule()
 @Test fun optionsStayOpenAndIndependentInAlphabeticOrder() {
  var filter by mutableStateOf("Todos")
  var sort by mutableStateOf("Alfabético")
  var closed=false
  val filters=listOf("Todos","Hyrox","Cardio","Favoritos","Halterofilia","Movilidad")
  assertEquals(listOf("Cardio","Favoritos","Halterofilia","Hyrox","Movilidad","Todos"),alphabeticExerciseFacets(filters))
  rule.setContent {MaterialTheme {Surface(Modifier.fillMaxWidth().testTag("filter-root")) {
   ExerciseFilterContent(filters,filter,sort,{filter=it},{sort=it},{closed=true})
  }}}
  rule.onNodeWithText("Material").performClick()
  rule.onNodeWithText("Favoritos").performClick()
  rule.runOnIdle {assertEquals("Material",sort);assertEquals("Favoritos",filter);assertFalse(closed)}
  val ys=alphabeticExerciseFacets(filters).map {rule.onNodeWithText(it).fetchSemanticsNode().boundsInRoot.top}
  assertTrue(ys.zipWithNext().all {it.first<it.second})
  val bmp=rule.onNodeWithTag("filter-root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/exercise-filters.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
  rule.onNodeWithContentDescription("Cerrar filtros").performClick()
  rule.runOnIdle {assertTrue(closed)}
 }
}
