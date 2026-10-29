package dev.repera.mobile.render
import android.graphics.Bitmap
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import dev.repera.domain.*
import dev.repera.mobile.*
import java.io.File
import java.io.FileOutputStream
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk=[35],qualifiers="w360dp-h1000dp")
class BoardClassicReviewRenderTest {
 @get:Rule val composeRule=createComposeRule()
 @Test fun editableDefaultsReachWireOnlyOnExplicitConfirmation() {
  val catalog=listOf(CatalogExercise("squat","Sentadilla trasera",listOf("BSQ","Back squat")))
  assertEquals(RoutineBlockKind.WOD,prepareBoardReview("Back squat",catalog,emptyMap()).lite.blocks.single().kind)
  var sent:List<RoutineBlock>?=null
  composeRule.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.testTag("classic_review_fixture")) {
   var drafts by remember {mutableStateOf(prepareBoardReview("Back squat",catalog,emptyMap()).classic)}
   Column(Modifier.verticalScroll(rememberScrollState())) {
    BoardClassicReviewEditor(drafts,false) {i,d ->drafts=drafts.mapIndexed {j,old ->if(i==j) d else old}}
    BoardScanReviewConfirm("Revisada",emptyList(),true,drafts,catalog,false,"request-1",
     onConfirm={title,blocks,request ->
      assertEquals("Revisada",title);assertEquals("request-1",request);sent=blocks
     })
   }
  }}}
  composeRule.onNodeWithText("3",useUnmergedTree=true).assertExists()
  composeRule.onNodeWithText("8",useUnmergedTree=true).assertExists()
  assertNull(sent)
  composeRule.onNodeWithText("Series 1").performTextReplacement("4")
  composeRule.onNodeWithText("Repeticiones 1").performTextReplacement("6")
  composeRule.onNodeWithText("Carga propuesta 1").performTextReplacement("60,5")
  assertNull(sent)
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/classic-review-editable.png").use {out ->composeRule.onNodeWithTag("classic_review_fixture").captureToImage().asAndroidBitmap().compress(Bitmap.CompressFormat.PNG,100,out)}
  composeRule.onNodeWithText("Crear rutina").performScrollTo().performClick()
  val wire=BoardScanImport.wireBlock(sent!!.single())
  val exercise=wire.getJSONArray("exercises").getJSONObject(0)
  assertEquals("squat",exercise.getString("exerciseId"))
  val sets=exercise.getJSONArray("plannedSets");assertEquals(4,sets.length())
  assertEquals(6,sets.getJSONObject(0).getInt("targetReps"));assertEquals(60.5,sets.getJSONObject(0).getDouble("targetWeightKg"),0.001)
  assertEquals("Back squat",wire.getString("wodNotes"))
 }
 @Test fun invalidOrUnresolvedDraftCannotConfirmAndExcludedLineDoesNotWrite() {
  val catalog=listOf(CatalogExercise("squat","Sentadilla trasera",listOf("Back squat")))
  var calls=0
  composeRule.setContent {MaterialTheme {Surface {
   var drafts by remember {mutableStateOf(BoardClassicReview.drafts("Unknown",catalog))}
   Column {
    BoardClassicReviewEditor(drafts,false) {i,d ->drafts=drafts.mapIndexed {j,old ->if(i==j) d else old}}
    BoardScanReviewConfirm("Review",emptyList(),true,drafts,catalog,false,"request",
     onConfirm={_,_,_ ->calls++})
   }
  }}}
  composeRule.onNodeWithText("Crear rutina").assertIsNotEnabled()
  composeRule.onNodeWithText("Ejercicio 1").performTextReplacement("Back squat")
  composeRule.onNodeWithText("Crear rutina").assertIsEnabled()
  composeRule.onNodeWithText("Series 1").performTextReplacement("0")
  composeRule.onNodeWithText("Crear rutina").assertIsNotEnabled()
  assertEquals(0,calls)
 }
}
