package dev.repera.mobile
import androidx.compose.material3.MaterialTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.requiredWidth
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.*
class WodLibraryInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun catalogDetailFavoriteDoesNotStartSession() {
  var toggled:String?=null
  compose.setContent {MaterialTheme {WodLibraryScreen("fixture",false,emptySet(),{toggled=it},{})}}
  compose.onNodeWithTag("wod_catalog_fran").performScrollTo().performClick()
  compose.onNodeWithTag("wod_toggle_favorite").performClick()
  compose.runOnIdle {Assert.assertEquals("fran",toggled)}
  compose.onNodeWithText("Empezar ahora").assertDoesNotExist()
 }
 @Test fun freeHistoryShowsRankedEndpointsButHidesMiddleResult() {
  val rows=listOf(WodLibraryResult("best","fran",100,null,null,"forTime"),
   WodLibraryResult("middle","fran",200,null,null,"forTime"),WodLibraryResult("last","fran",300,null,null,"forTime"))
  compose.setContent {MaterialTheme {WodLibraryScreen("fixture",false,emptySet(),{},{},history=mapOf("fran" to rows))}}
  compose.onNodeWithTag("wod_catalog_fran").performScrollTo().performClick()
  compose.onNodeWithTag("wod_result_best").performScrollTo().assertExists()
  compose.onNodeWithTag("wod_result_last").performScrollTo().assertExists()
  compose.onNodeWithTag("wod_result_middle").assertDoesNotExist()
  compose.onNodeWithText("Supera tus marcas · ver historial completo").performScrollTo().assertExists()
 }
 @Test fun unmatchedWodSearchCanOpenAnExerciseWithoutCreatingAWod() {
  var opened:String?=null
  compose.setContent {MaterialTheme {WodLibraryScreen("fixture",false,emptySet(),{},{},
   exercises=listOf(ExerciseEntry("exercise","Ejercicio singular zzzz",true,false)),onExercise={opened=it})}}
  compose.onNodeWithText("Nombre o formato").performTextInput("zzzz")
  compose.onNodeWithTag("wod_fallback_exercise").performScrollTo().performClick()
  compose.runOnIdle {Assert.assertEquals("exercise",opened)}
 }
 @Test fun wideFallbackKeepsExerciseDetailInLibraryInsteadOfExternalNavigation() {
  var opened=false
  compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(800.dp)) {
   WodLibraryScreen("fixture",false,emptySet(),{},{},
    exercises=listOf(ExerciseEntry("exercise","Ejercicio singular zzzz",true,false)),
    onExercise={opened=true},exerciseDetail={entry,close ->
     TextButton(onClick=close,modifier=Modifier.testTag("fixture_detail")) {Text(entry.id)}
    })
  }}}
  compose.onNodeWithText("Nombre o formato").performTextInput("zzzz")
  compose.onNodeWithTag("wod_fallback_split").assertExists()
  compose.onNodeWithTag("wod_fallback_exercise").performScrollTo().performClick()
  compose.onNodeWithTag("fixture_detail").assertExists().performClick()
  compose.onNodeWithTag("fixture_detail").assertDoesNotExist()
  compose.runOnIdle {Assert.assertFalse(opened)}
 }
 @Test fun wideCatalogDoesNotSplitUntilUnmatchedQueryAndRestoresAfterClearingIt() {
  compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(800.dp)) {
   WodLibraryScreen("fixture",false,emptySet(),{},{},exerciseDetail={_,_->Text("detail")})
  }}}
  compose.onNodeWithTag("wod_fallback_split").assertDoesNotExist()
  compose.onNodeWithText("Nombre o formato").performTextInput("zzzz")
  compose.onNodeWithTag("wod_fallback_split").assertExists()
  compose.onNodeWithText("Nombre o formato").performTextClearance()
  compose.onNodeWithTag("wod_fallback_split").assertDoesNotExist()
  compose.onNodeWithTag("wod_catalog_fran").performScrollTo().assertExists()
 }
}
