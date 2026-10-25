package dev.repera.mobile

import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TrainingSettingsInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    private fun capture(name:String) {
        compose.waitForIdle();Thread.sleep(600)
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
    @Test fun rotationAdvancesOnlyAfterFinishingNextRoutineAndNeverOnDiscard() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val account="test-rotation-${java.util.UUID.randomUUID()}"
        val exercise=JSONObject().put("id","ex").put("name","Sentadilla").put("muscleGroup","Piernas")
        val state=JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray().put(exercise))
        val local=LocalSnapshotStore(context,account);local.write(state.toString().toByteArray())
        val repo=WorkoutRepository(context,account)
        repo.createRoutine("A","strength",listOf(RoutineDraftEntry("ex",5)))
        repo.createRoutine("B","strength",listOf(RoutineDraftEntry("ex",5)))
        val ids=JSONObject(String(local.read()!!)).getJSONArray("routines").let { a -> (0 until a.length()).map {a.getJSONObject(it).getString("id")} }
        repo.updateTrainingSettings(TrainingSettings(scheduleMode="rotation"))
        assertEquals(ids[0],repo.todayPlanSession()!!.getString("routineId"))
        val initialOverview=StateOverview.fromBytes(local.read())!!
        assertEquals(ids[0],initialOverview.rotationPlan!!.nextRoutineId)
        repo.startRoutine(ids[1]);repo.finish()
        assertEquals(ids[0],repo.todayPlanSession()!!.getString("routineId"))
        repo.startRoutine(ids[0]);repo.discardActiveSession()
        assertEquals(ids[0],repo.todayPlanSession()!!.getString("routineId"))
        repo.startRoutine(ids[0]);repo.finish()
        assertEquals(ids[1],repo.todayPlanSession()!!.getString("routineId"))
        repo.startRoutine(ids[1]);repo.finish()
        assertEquals(ids[0],repo.todayPlanSession()!!.getString("routineId"))
        assertEquals("rotation",StateOverview.fromBytes(local.read())!!.trainingSettings.scheduleMode)
        repo.updateTrainingSettings(TrainingSettings(scheduleMode="fixedWeek"))
        assertNull(repo.todayPlanSession())
        assertNotNull(RotationSettings.read(JSONObject(String(local.read()!!))))
    }
    @Test fun settingsPersistPreserveUnknownFieldsAndDriveWeekAndRest() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val account="test-settings-${java.util.UUID.randomUUID()}"
        val initial=JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray())
            .put("settings",JSONObject().put("weightUnit","lb").put("futureKey","preserved"))
        val store=LocalSnapshotStore(context,account);store.write(initial.toString().toByteArray())
        val repo=WorkoutRepository(context,account)
        var value by mutableStateOf(TrainingSettings.read(initial))
        compose.setContent { MaterialTheme(colorScheme=reperaColorScheme(false)) {
            SettingsTab(false,{},{},{},StateOverview.fromBytes(store.read())?.copy(trainingSettings=value),{ next ->
                repo.updateTrainingSettings(next);value=next
            })
        } }
        capture("ajustes_entrenamiento_completo.png")
        compose.onNodeWithText("Domingo").performScrollTo().performClick()
        compose.onNodeWithText("Añadir 15 s").performScrollTo().performClick()
        compose.onNodeWithText("Abrir Ajustes del sistema").performScrollTo().assertIsDisplayed()
        capture("ajustes_permisos_datos.png")
        compose.runOnIdle {
            val saved=JSONObject(String(store.read()!!));val settings=saved.getJSONObject("settings")
            assertEquals("sunday",settings.getString("weekStartsOn"))
            assertEquals(105,settings.getInt("defaultRestSeconds"))
            assertEquals("lb",settings.getString("weightUnit"));assertEquals("preserved",settings.getString("futureKey"))
            val overview=StateOverview.fromBytes(store.read())!!
            assertFalse(overview.trainingSettings.weekStartsOnMonday)
            assertEquals(105,overview.trainingSettings.defaultRestSeconds)
            repo.updateTrainingSettings(value.copy(defaultProgression="double",weightIncrementKg=3.0,restSoundEnabled=false,restHapticEnabled=false))
            val reread=TrainingSettings.read(JSONObject(String(store.read()!!)))
            assertFalse(reread.restSoundEnabled);assertFalse(reread.restHapticEnabled)
            assertEquals("double",reread.defaultProgression);assertEquals(3.0,reread.weightIncrementKg,0.0)
            assertEquals(java.time.LocalDate.of(2026,10,25),dev.repera.domain.StatsEngine.startOfWeek(java.time.LocalDate.of(2026,10,28),reread.weekStartsOnMonday))
            val savedAgain=JSONObject(String(store.read()!!))
            val exercise=JSONObject().put("exercise",JSONObject().put("name","Sentadilla"))
            savedAgain.put("activeSession",JSONObject().put("currentIndex",0).put("exercises",JSONArray().put(exercise)))
            store.write(savedAgain.toString().toByteArray())
            assertEquals(105,repo.restInfoForExercise()!!.second)
            exercise.put("restSeconds",60)
            savedAgain.put("activeSession",JSONObject().put("currentIndex",0).put("exercises",JSONArray().put(exercise)))
            store.write(savedAgain.toString().toByteArray())
            assertEquals(60,repo.restInfoForExercise()!!.second)
        }

    }
}
