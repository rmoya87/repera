package dev.repera.mobile
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawingPadding

import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
import org.junit.Assert.*
import java.time.LocalDate

class WeeklyScheduleInstrumentedTest {
    @get:Rule val compose = createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun copyPersistsAndClearRequiresConfirmationKeepsAllTrainingData() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val account="test-schedule-${java.util.UUID.randomUUID()}"
        val local=LocalSnapshotStore(context,account)
        val lastSunday=LocalDate.of(2026,10,18)
        val state=JSONObject().put("exercises",JSONArray()).put("workouts",JSONArray().put(JSONObject().put("id","history")))
            .put("routines",JSONArray()
                .put(JSONObject().put("id","weekly").put("title","Semanal").put("weekday",1).put("blocks",JSONArray()))
                .put(JSONObject().put("id","past").put("title","Anterior").put("scheduledDate",lastSunday.toString()).put("blocks",JSONArray())))
        local.write(state.toString().toByteArray())
        val repo=WorkoutRepository(context,account)
        var overview by mutableStateOf(StateOverview.fromBytes(local.read()))
        var copied=0
        compose.setContent { MaterialTheme(colorScheme=reperaColorScheme(false)) {
            androidx.compose.foundation.layout.Box(androidx.compose.ui.Modifier.fillMaxSize().safeDrawingPadding()) {
            DiaryTab(busy=false,syncing=false,status=null,overview=overview,activeWorkout=null,
                onStartRoutine={},onEditRoutine={_,_,_->},onDeleteRoutine={},
                onCopyPreviousWeek={copied=repo.copyPreviousWeekSchedule(LocalDate.of(2026,10,25));overview=StateOverview.fromBytes(local.read())},
                onClearWeeklySchedule={repo.clearWeeklySchedule();overview=StateOverview.fromBytes(local.read())},
                onInitializeLocal={},onImportJson={},onDriveSync={},onExportJson={},onSignOut={},onNavigateHome={})
            }
        }}
        compose.onNodeWithTag("diary_schedule_menu").performClick()
        compose.onNodeWithText("Copiar semana anterior").performClick()
        compose.runOnIdle {assertEquals(1,copied);assertEquals(3,JSONObject(String(local.read()!!)).getJSONArray("routines").length())}
        compose.onNodeWithTag("diary_schedule_menu").performClick()
        compose.onNodeWithText("Vaciar programación").performClick()
        compose.onNodeWithText("¿Vaciar programación?").assertIsDisplayed()
        compose.onNodeWithText("Cancelar").performClick()
        assertEquals(1,JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0).getInt("weekday"))
        compose.onNodeWithTag("diary_schedule_menu").performClick()
        compose.onNodeWithText("Vaciar programación").performClick()
        capture("diario_vaciar_confirmacion.png")
        compose.onNodeWithText("Vaciar",useUnmergedTree=true).performClick()
        compose.runOnIdle {
            val saved=JSONObject(String(local.read()!!))
            assertTrue(saved.getJSONArray("routines").getJSONObject(0).isNull("weekday"))
            assertEquals(3,saved.getJSONArray("routines").length())
            assertEquals("history",saved.getJSONArray("workouts").getJSONObject(0).getString("id"))
            assertEquals(0,repo.copyPreviousWeekSchedule(LocalDate.of(2026,10,25)))
        }
        capture("diario_programacion_vaciada.png")
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
