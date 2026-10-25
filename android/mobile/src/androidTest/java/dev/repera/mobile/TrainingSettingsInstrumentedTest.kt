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
        compose.onNodeWithText("Domingo").performScrollTo().performClick()
        compose.onNodeWithText("Añadir 15 s").performScrollTo().performClick()
        compose.runOnIdle {
            val saved=JSONObject(String(store.read()!!));val settings=saved.getJSONObject("settings")
            assertEquals("sunday",settings.getString("weekStartsOn"))
            assertEquals(105,settings.getInt("defaultRestSeconds"))
            assertEquals("lb",settings.getString("weightUnit"));assertEquals("preserved",settings.getString("futureKey"))
            val overview=StateOverview.fromBytes(store.read())!!
            assertFalse(overview.trainingSettings.weekStartsOnMonday)
            assertEquals(105,overview.trainingSettings.defaultRestSeconds)
            repo.updateTrainingSettings(value.copy(defaultProgression="double",weightIncrementKg=3.0))
            val reread=TrainingSettings.read(JSONObject(String(store.read()!!)))
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
