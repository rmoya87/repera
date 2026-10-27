package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import dev.repera.mobile.WeightStatTiles
import org.junit.Assert.assertEquals
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
@Config(sdk=[35],qualifiers="w360dp-h900dp")
class WeightTilesRenderTest {
 @get:Rule val rule=createComposeRule()
 @Test fun centeredPresentAndMissingWeights() {
  rule.setContent {MaterialTheme {Surface(Modifier.testTag("weight-root")) {
   Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
    Text("Peso corporal · ejemplo de prueba")
    WeightStatTiles(78.4,75.0)
    Text("Sin mediciones · ejemplo de prueba")
    WeightStatTiles(null,null)
   }
  }}}
  val title=rule.onAllNodesWithText("Actual")[0].fetchSemanticsNode().boundsInRoot
  val goal=rule.onAllNodesWithText("Objetivo")[0].fetchSemanticsNode().boundsInRoot
  val values=rule.onAllNodes(hasText("78,4 kg")).fetchSemanticsNodes()
  assertEquals(1,values.size)
  assertEquals(title.center.x,values.single().boundsInRoot.center.x,1f)
  val actual=rule.onAllNodesWithText("Actual")[1].fetchSemanticsNode().boundsInRoot
  assertEquals(title.center.x,actual.center.x,1f)
  val target=rule.onAllNodesWithText("75 kg")[0].fetchSemanticsNode().boundsInRoot
  assertEquals(goal.center.x,target.center.x,1f)
  val bmp=rule.onNodeWithTag("weight-root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/weight-tiles.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }
 @Test fun freePreviewUsesSameTilesWithExplicitExampleLabel() {
  rule.setContent {MaterialTheme {Surface(Modifier.testTag("preview-root")) {
   dev.repera.mobile.WeightPreviewCard(java.time.LocalDate.of(2026,10,27))
  }}}
  rule.onNodeWithText("Peso corporal · ejemplo").assertExists()
  rule.onNodeWithText("Datos ficticios. Objetivo de ejemplo: 74 kg").assertExists()
  rule.onNodeWithText("Actual").assertExists()
  rule.onNodeWithText("Objetivo").assertExists()
  rule.onNodeWithText("Δ").assertExists()
  val bmp=rule.onNodeWithTag("preview-root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/weight-preview.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }

 @Test fun emptyWeightAxesKeepChartHeightWithoutInventingSamples() {
  rule.setContent {MaterialTheme {Surface(Modifier.testTag("empty-weight-root")) {Column {dev.repera.mobile.EmptyHealthChartAxes(60.0,90.0,210.dp)}}}}
  val axes=rule.onNodeWithTag("empty_health_chart_axes").fetchSemanticsNode().boundsInRoot
  assertEquals(210f,axes.height,1f)
  rule.onNodeWithText("60").assertExists()
  rule.onNodeWithText("90").assertExists()
  rule.onNodeWithTag("day_point_line_chart").assertDoesNotExist()
  val bmp=rule.onNodeWithTag("empty-weight-root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/weight-empty.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }

}
