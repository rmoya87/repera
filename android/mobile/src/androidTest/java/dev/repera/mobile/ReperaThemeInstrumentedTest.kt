package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.assertIsDisplayed
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.json.JSONObject
import org.json.JSONArray
import java.time.LocalDate

/** Pantallas reales, esquema real, fixtures locales y capturas de ventana completa. */
@RunWith(AndroidJUnit4::class)
class ReperaThemeInstrumentedTest {
    @get:Rule val compose = createAndroidComposeRule<androidx.activity.ComponentActivity>()
    private fun estadoSinteticoOverview(): StateOverview {
        val today = LocalDate.now()
        fun exercise(id: String, name: String, muscle: String, equipment: String?) =
            JSONObject().put("id", id).put("name", name).put("muscleGroup", muscle)
                .put("equipment", equipment ?: JSONObject.NULL).put("targetMuscle", muscle)
        val squat = exercise("ex-sentadilla", "Sentadilla", "Piernas", "Barra")
        val bench = exercise("ex-banca", "Press banca", "Pecho", "Barra")
        val run = exercise("ex-carrera", "Carrera", "Cardio", null)
        val workouts = JSONArray()
        val days = listOf(0L, 1L, 3L, 4L, 7L, 8L, 10L, 11L, 14L, 15L, 17L, 18L)
        days.forEachIndexed { i, d ->
            val date = today.minusDays(d)
            val ex = when (i % 3) { 0 -> squat; 1 -> bench; else -> squat }
            val sets = JSONArray()
            repeat(4) { n ->
                sets.put(JSONObject()
                    .put("id", java.util.UUID.randomUUID().toString())
                    .put("reps", 5).put("weightKg", 80.0 + i * 2.5 - n)
                    .put("rir", 2.0).put("phase", "work"))
            }
            val entry = JSONObject()
                .put("id", java.util.UUID.randomUUID().toString())
                .put("exercise", JSONObject(ex.toString()))
                .put("plannedSets", JSONArray())
                .put("loggedSets", sets)
                .put("completedReps", 20).put("isCompleted", true)
                .put("blockId", "b1").put("blockKind", "strength")
            val session = JSONObject()
                .put("id", java.util.UUID.randomUUID().toString())
                .put("title", if (i % 3 == 1) "Empuje" else "Pierna")
                .put("startedAt", date.atTime(18, 0)
                    .atZone(java.time.ZoneId.systemDefault()).toInstant().toString())
                .put("finishedAt", date.atTime(19, 0)
                    .atZone(java.time.ZoneId.systemDefault()).toInstant().toString())
                .put("phase", "finished")
                .put("exercises", JSONArray().put(entry))
            workouts.put(session)
        }
        val weights = JSONArray()
        (20L downTo 0 step 2).forEach { d ->
            weights.put(JSONObject()
                .put("date", today.minusDays(d).toString())
                .put("weightKg", 83.5 - (20 - d) * 0.05))
        }
        val state = JSONObject()
            .put("exercises", JSONArray().put(squat).put(bench).put(run))
            .put("routines", JSONArray())
            .put("workouts", workouts)
            .put("bodyWeights", weights)
            .put("favoriteTimers", JSONArray())
            .put("exerciseLoadPrefs", JSONObject())
            .put("settings",JSONObject().put("dailyStepsGoal",10000).put("dailyActiveEnergyGoalKcal",500).put("dailyWorkoutMinutesGoal",45).put("weeklyWorkoutGoal",4).put("bodyWeightGoalKg",80.0))
            .put("syncRevision", 1)
            .put("lastWriterDeviceId", "visual-test")
        return StateOverview.fromBytes(
            state.toString().toByteArray(Charsets.UTF_8))!!
    }

    @Test fun representativeScreensLight() = inspectScreens(false)
    @Test fun representativeScreensDark() = inspectScreens(true)
    private fun inspectScreens(dark: Boolean) {
        val overview = estadoSinteticoOverview()
        var screen by mutableStateOf(0)
        var focusedDay by mutableStateOf<java.time.LocalDate?>(null)
        val account = "test-theme-${java.util.UUID.randomUUID()}"
        LiveActivityRuntime.forAccount(compose.activity,account).choose(dev.repera.domain.LiveSport.PADEL)
        compose.setContent {
            MaterialTheme(colorScheme = reperaColorScheme(dark)) {
                Surface(Modifier.fillMaxSize()) {
                    when(screen) {
                    0 -> HomeTab(
                        focusDay=focusedDay,
                        displayName = "Deportista", busy = false, syncing = false,
                        status = null, overview = overview, todayHealth = null,
                        onHealthConnect = {}, activeWorkout = null, wodTimer = null,
                        onWodTimerAction = {}, onWodTimerTick = {},
                        onStartRoutine = {}, onWodScore = { _, _, _ -> },
                        onWodMovement = { _, _, _, _ -> },
                        onCompleteWodBlock = {},
                        onReviseWodMovement = { _, _, _ -> },
                        onDeleteWodMovement = {},
                        onLogSet = { _, _, _, _, _, _, _ -> },
                        onLogDropSet = { _, _, _ -> },
                        onLogRestPauseSet = { _, _ -> },
                        onReviseSet = { _, _, _, _, _, _ -> },
                        onDeleteSet = {},
                        onReviseFinishedSet = { _, _, _, _, _, _ -> },
                        onDeleteFinishedSet = { _, _, _ -> },
                        onNext = {}, onFinish = {},
                        onInitializeLocal = {}, onImportJson = {},
                        onDriveSync = {}, onExportJson = {}, onSignOut = {},
                        onNavigateCreate = {}, onOpenClock = {})
                    1 -> ProgressTab(busy=false,syncing=false,status=null,overview=overview,
                        onInitializeLocal={},onImportJson={},onDriveSync={},onExportJson={},onSignOut={},
                        onReviseFinishedSet={_,_,_,_,_,_->},onDeleteFinishedSet={_,_,_->},onLogBodyWeight={})
                    2 -> ExercisesTab(busy=false,syncing=false,status=null,overview=overview,activeWorkout=null,
                        onQuickLog={},onOpenExercise={},onInitializeLocal={},onImportJson={},onDriveSync={},
                        onExportJson={},onSignOut={},onNavigateHome={})
                    3 -> LiveActivityScreen(account,{},{})
                    4 -> LiveSportHistoryScreen(dev.repera.domain.LiveSport.RUNNING,listOf(
                        dev.repera.domain.LiveSportHistory.LiveSession("theme-run","Carrera medida","running",
                            1792918800000L,1792922400000L,1800.0,5000.0,140.0,250.0)),{})
                    6 -> DiaryTab(busy=false,syncing=false,status=null,overview=overview,activeWorkout=null,
                        onStartRoutine={},onEditRoutine={_,_,_->},onDeleteRoutine={},onInitializeLocal={},
                        onImportJson={},onDriveSync={},onExportJson={},onSignOut={},onNavigateHome={})
                    7 -> SettingsTab(false,{},{},{},overview)
                    8 -> LiveSportsCatalogScreen(listOf(dev.repera.domain.LiveSportHistory.LiveSession(
                        "theme-run","Carrera medida","running",1792918800000L,1792922400000L,1800.0,5000.0,null,null)),"",{})
                    9 -> CreateTab(busy=false,syncing=false,status=null,overview=overview,
                        onCreateRoutine={_,_,_,_,_,_,_,_,_,_->},onAddWodTemplate={},onOpenBoardScan={},
                        onOpenTimer={},onInitializeLocal={},onImportJson={},onDriveSync={},onExportJson={},onSignOut={})
                    10 -> ActiveWorkoutScreen(
                        ActiveWorkout(id="theme-active",title="Pierna",index=0,total=1,
                            exerciseName="Sentadilla",completedSets=0,prescribedQuantity=5,
                            prescribedWeightKg=80.0,allowsWeight=true,sets=emptyList()),
                        false,null,{},{},{_,_,_->},{_,_,_,_->},{},{_,_,_->},{},
                        {_,_,_,_,_,_,_->},{_,_,_->},{_,_->},{_,_,_,_,_,_->},{},{},{},{},{},{},null,account,{})
                    5 -> Column(Modifier.padding(16.dp)) {
                        FinishedWorkoutEditorSection(overview.completeHistory.first(),account,false) {}
                    }
                    }
                }
            }
        }
        val names = listOf("inicio","progreso","ejercicios","comenzar_padel","historial_deporte","editor_terminado","diario","ajustes","catalogo_deportes","crear","entreno_activo")
        names.forEachIndexed { index,name ->
            compose.runOnIdle { screen=index }
            compose.waitForIdle()
            if(index==5) { compose.onNodeWithTag("edit_finished_workout").performClick();compose.waitForIdle() }
            Thread.sleep(800)
            val bitmap = InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()!!
            val context=InstrumentationRegistry.getInstrumentation().targetContext
            val values=android.content.ContentValues().apply {
                put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,"tema_${if(dark) "oscuro" else "claro"}_$name.png")
                put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
                put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
            }
            val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
            context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
        }
        compose.runOnIdle { screen=0;focusedDay=java.time.LocalDate.of(2026,10,7) }
        compose.onNodeWithText("Entrenamientos · " + focusedDay!!.format(reperaDayFormatter))
            .performScrollTo().assertIsDisplayed()
        compose.runOnIdle {screen=1}
        compose.onNodeWithTag("progress_list").performScrollToNode(hasText("Peso corporal"))
        compose.onNodeWithText("Peso corporal").assertIsDisplayed()
        Thread.sleep(500)
        val finalBitmap=InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()!!
        val finalContext=InstrumentationRegistry.getInstrumentation().targetContext
        val finalValues=android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,"objetivo_peso_${if(dark) "oscuro" else "claro"}.png")
            put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
        }
        val finalUri=finalContext.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,finalValues)!!
        finalContext.contentResolver.openOutputStream(finalUri)!!.use {finalBitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
        compose.runOnIdle { LiveActivityRuntime.stopAll() }
    }
}
