package dev.repera.mobile

import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
import org.junit.Assert.*

class ActiveSessionControlsInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun navigationNeverConfirmsAndNotesPersistAcrossReloadAndFinish() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val account="test-active-nav-${java.util.UUID.randomUUID()}"
        val local=LocalSnapshotStore(context,account)
        local.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","ex").put("name","Sentadilla").put("muscleGroup","Piernas")))
            .put("workouts",JSONArray()).put("routines",JSONArray()).toString().toByteArray())
        val repo=WorkoutRepository(context,account)
        val routine=repo.createRoutine("Dos ejercicios","strength",listOf(RoutineDraftEntry("ex",5),RoutineDraftEntry("ex",8)))
        var active by mutableStateOf(repo.startRoutine(routine))
        compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {
            androidx.compose.foundation.layout.Column {
                ActiveSessionControls(active,false,{active=repo.selectActiveExercise(it)},{repo.updateActiveSessionNotes(it);active=repo.active()!!})
            }
        }}
        compose.onNodeWithTag("active_navigate_next").performClick()
        compose.runOnIdle {assertEquals(1,active.index)}
        compose.onNodeWithTag("active_previous").performClick()
        compose.runOnIdle {
            assertEquals(0,active.index)
            val session=JSONObject(String(local.read()!!)).getJSONObject("activeSession")
            assertEquals("ready",session.getString("phase"))
            val ex=session.getJSONArray("exercises")
            for(i in 0 until ex.length()) {
                assertFalse(ex.getJSONObject(i).optBoolean("isCompleted"))
                assertEquals(0,ex.getJSONObject(i).getJSONArray("loggedSets").length())
            }
        }
        compose.onNodeWithText("Añadir notas").performClick()
        compose.onNodeWithTag("active_notes_input").performTextInput("  Rodilla sin molestias  ")
        compose.onNodeWithText("Guardar notas").performClick()
        compose.runOnIdle {assertEquals("Rodilla sin molestias",WorkoutRepository(context,account).active()!!.notes)}
        capture("entreno_navegacion_notas.png")
        compose.runOnIdle {
            repo.logCurrentSet(5,40.0);repo.next();repo.selectActiveExercise(0)
            // Revisiting a completed exercise does not destroy prior sets and can add an actual set.
            repo.logCurrentSet(4,42.0)
            assertEquals(2,repo.active()!!.sets.size)
            repo.finish()
            assertEquals("Rodilla sin molestias",JSONObject(String(local.read()!!)).getJSONArray("workouts").getJSONObject(0).getString("notes"))
        }
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
