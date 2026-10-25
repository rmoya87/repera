package dev.repera.mobile
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
import org.junit.Assert.*

class BodyWeightHistoryInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun emptyAccountCanRecordFirstWeightReplaceTodayAndDeleteOnlyAfterConfirming() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val account="test-weight-${java.util.UUID.randomUUID()}"
        val local=LocalSnapshotStore(context,account)
        local.write(JSONObject().put("exercises",JSONArray()).put("workouts",JSONArray()).put("routines",JSONArray()).toString().toByteArray())
        val repo=WorkoutRepository(context,account)
        fun read()=BodyWeightHistory.entries(JSONObject(String(local.read()!!)))
        var entries by mutableStateOf(read())
        compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {
            BodyWeightHistoryScreen(entries,false,{repo.logBodyWeight(it);entries=read()},{repo.deleteBodyWeight(it);entries=read()})
        }}
        compose.onNodeWithText("Aún no hay pesos registrados.").assertIsDisplayed()
        compose.onNodeWithTag("weight_history_input").performTextInput("82,5")
        compose.onNodeWithText("Añadir").performClick()
        compose.runOnIdle {assertEquals(82.5,entries.single().kg,0.0)}
        compose.onNodeWithTag("weight_history_input").performTextInput("81")
        compose.onNodeWithText("Añadir").performClick()
        compose.runOnIdle {assertEquals(81.0,entries.single().kg,0.0)}
        compose.onNodeWithTag("delete_weight_${entries.single().id}").performClick()
        compose.onNodeWithText("Cancelar").performClick()
        compose.runOnIdle {assertEquals(1,read().size)}
        capture("peso_historial_primera_medicion.png")
        compose.onNodeWithTag("delete_weight_${entries.single().id}").performClick()
        compose.onNode(hasText("Borrar") and hasAnyAncestor(isDialog()),useUnmergedTree=true).performClick()
        compose.onNodeWithText("Aún no hay pesos registrados.").assertIsDisplayed()
        compose.runOnIdle {assertTrue(read().isEmpty())}
    }
    private fun capture(name:String) {
        compose.waitForIdle()
        val instrument=InstrumentationRegistry.getInstrumentation();val context=instrument.targetContext
        val bitmap=instrument.uiAutomation.takeScreenshot()!!
        val values=android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,name)
            put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
        }
        val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
        context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
    }
}
