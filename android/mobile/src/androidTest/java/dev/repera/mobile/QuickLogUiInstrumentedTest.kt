package dev.repera.mobile
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.*
import org.junit.Assert.*
class QuickLogUiInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun cancelNeverSavesAndConfirmedRowsCarryPerRowValuesAndNote() {
  var rows:List<QuickLogRow>?=null;var note:String?=null;var open by mutableStateOf(true)
  compose.setContent {MaterialTheme {if(open) QuickLogSheet(ExerciseEntry("a","Sentadilla",true,true),"fixture",false,LoadGuideSet(40.0,8,null,null,"reps"),{open=false}) {r,n,_ ->rows=r;note=n;open=false}}}
  compose.onNodeWithText("Cancelar").performScrollTo().performClick()
  compose.runOnIdle {assertNull(rows);open=true}
  compose.onNodeWithText("Eliminar serie 3").performScrollTo().performClick()
  compose.onNodeWithText("Guardar").performScrollTo().performClick()
  compose.runOnIdle {assertEquals(2,rows!!.size);assertEquals(40.0,rows!!.first().weightKg!!,0.001);assertNull(note)}
 }
}
