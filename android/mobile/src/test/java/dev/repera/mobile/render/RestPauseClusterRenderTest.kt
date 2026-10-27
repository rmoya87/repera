package dev.repera.mobile.render
import android.graphics.Bitmap
import androidx.compose.runtime.*
import androidx.compose.material3.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
@Config(sdk=[35],qualifiers="w360dp-h900dp")
class RestPauseClusterRenderTest {
 @get:Rule val rule=createComposeRule()
 @Test fun clustersRetainIndividualRestAndRequireValidInput() {
  var reps by mutableStateOf("8")
  var rest by mutableStateOf("15")
  var clusters by mutableStateOf<List<Pair<Int,Int>>>(emptyList())
  rule.setContent {MaterialTheme {Surface(Modifier.testTag("cluster-root")) {
   Column(Modifier.padding(18.dp)) {
    RestPauseClusterEditor(clusters,reps,rest,false,{reps=it},{rest=it}) {r,s ->clusters=clusters+(r to s);reps=""}
   }
  }}}
  rule.onNodeWithText("Añadir cluster").performClick()
  rule.onNodeWithText("Añadir cluster").assertIsNotEnabled()
  rule.onNodeWithText("REPS").performTextReplacement("5")
  rule.onNodeWithText("DESCANSO").performTextReplacement("31")
  rule.onNodeWithText("Añadir cluster").assertIsNotEnabled()
  rule.onNodeWithText("DESCANSO").performTextReplacement("20")
  rule.onNodeWithText("Añadir cluster").performClick()
  rule.runOnIdle {assertEquals(listOf(8 to 15,5 to 20),clusters)}
  rule.onNodeWithText("1. 8 reps · descanso 15 s").assertIsDisplayed()
  rule.onNodeWithText("2. 5 reps · descanso 20 s").assertIsDisplayed()
  val bmp=rule.onNodeWithTag("cluster-root").captureToImage().asAndroidBitmap()
  File("build/reports/render").mkdirs()
  FileOutputStream("build/reports/render/restpause-clusters.png").use {bmp.compress(Bitmap.CompressFormat.PNG,100,it)}
 }
 @Test fun singleClusterCanSaveWithoutUnrelatedBaseReps() {
  var saved:List<Pair<Int,Int>>?=null
  val active=ActiveWorkout("fixture","Prueba",0,1,"Back squat",0,null,null,allowsWeight=true,sets=emptyList())
  rule.setContent {MaterialTheme {Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
   ActiveWorkoutCard(active,false,onLogSet={_,_,_,_,_,_,_,_->},onReviseSet={_,_,_,_,_,_->},onDeleteSet={},onNext={},onFinish={},
    onLogRestPauseSet={c,_,_,_->saved=c})
  }}}
  rule.onNodeWithText("Rest-pause").performScrollTo().performClick()
  rule.onNodeWithText("REPS").performScrollTo().performTextReplacement("8")
  rule.onNodeWithText("Añadir cluster").performScrollTo().performClick()
  rule.onNodeWithText("Registrar serie").performScrollTo().assertIsEnabled().performClick()
  rule.runOnIdle {assertEquals(listOf(8 to 15),saved)}
 }

}
