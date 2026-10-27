package dev.repera.mobile
import androidx.compose.material3.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
import org.junit.Assert.*

/** Synthetic read/send callback fixtures only. No network, real messages or account. */
class BusinessProjectionInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun professionalPlanProjectsWithoutMutatingPrivateSnapshot() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val id="professional-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(ctx,id)
        local.write(JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray()).toString().toByteArray())
        val before=local.read()!!
        val payload=JSONObject().put("schemaVersion",1).put("blocks",JSONArray().put(JSONObject().put("id","b").put("title","Fuerza prescrita").put("kind","strength")
            .put("exercises",JSONArray().put(JSONObject().put("id","e").put("name","Sentadilla").put("source","catalog")
                .put("plannedSets",JSONArray().put(JSONObject().put("targetReps",5).put("targetWeightKg",80).put("targetRir",2)))))))
        val session=BusinessCenterStore.ProfessionalSession("p","org","client","coach","2026-10-25","Plan entrenador","Técnica controlada","scheduled",payload)
        compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.fillMaxSize()) {Column(Modifier.padding(16.dp)) {ProfessionalSessionCard(session,"Centro sintético",false)}}}}
        compose.onNodeWithText("Fuerza prescrita").assertIsDisplayed()
        compose.onNodeWithText("Sentadilla").assertIsDisplayed()
        compose.onNodeWithText("5 rep · 80 kg · RIR 2").assertIsDisplayed()
        assertArrayEquals(before,local.read())
        capture("profesional_solo_lectura")
    }
    @Test fun messagesSelectLinkedRecipientAndOnlyExplicitSendCallsCallback() {
        var sent:Triple<String,String,String>?=null
        val snapshot=BusinessCenterStore.Snapshot(centers=listOf(
            BusinessCenterStore.Organization("org","Centro sintético","gym",null,null,null)),athleteCenterIds=setOf("org"),
            notices=listOf(BusinessCenterStore.Notice("m","org","c","Aviso sintético","Hola","2026-10-25T20:00:00Z")))
        compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.fillMaxSize()) {CenterMessagesScreen(true,false,false,null,snapshot,{}, {org,title,body -> sent=Triple(org,title,body)})}}}
        compose.onNodeWithText("Aviso sintético").assertIsDisplayed()
        capture("mensajes_bandeja")
        compose.onNodeWithText("Escribir mensaje").performClick()
        compose.onNodeWithText("Enviar").assertIsNotEnabled()
        compose.onNodeWithText("Asunto").performTextInput("Consulta")
        compose.onNodeWithText("Mensaje").performTextInput("Prueba local")
        capture("mensajes_borrador")
        assertNull(sent)
        compose.onNodeWithText("Enviar").performClick()
        assertEquals(Triple("org","Consulta","Prueba local"),sent)
    }
    @Test fun professionalWearPlanIsFallbackAndNeverPersistsCatalogOrRoutine() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val id="professional-watch-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(ctx,id)
        val state=JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray())
        local.write(state.toString().toByteArray());val repo=WorkoutRepository(ctx,id)
        val prescription=JSONObject().put("schemaVersion",1).put("blocks",JSONArray().put(JSONObject()
            .put("id","block").put("kind","strength").put("title","Fuerza")
            .put("exercises",JSONArray().put(JSONObject().put("id","entry").put("name","Sentadilla libre")
                .put("plannedSets",JSONArray().put(JSONObject().put("id","set").put("targetReps",5).put("targetWeightKg",30)))))))
        val session=BusinessCenterStore.ProfessionalSession("coach-plan","org","client","coach","2026-10-25","Sesión profesional","","scheduled",prescription)
        val date=java.time.LocalDate.of(2026,10,25)
        val before=local.read()!!
        val plan=repo.todayPlanSession(date,listOf(session))!!
        assertEquals("coach-plan",plan.getString("routineId"))
        val exercise=plan.getJSONArray("exercises").getJSONObject(0)
        assertEquals("Sentadilla libre",exercise.getJSONObject("exercise").getString("name"))
        assertEquals(5,exercise.getJSONArray("plannedSets").getJSONObject(0).getInt("targetReps"))
        assertEquals(0,exercise.getJSONArray("loggedSets").length())
        assertArrayEquals(before,local.read())
        assertNull(repo.todayPlanSession(date.plusDays(1),listOf(session)))
        assertNull(repo.todayPlanSession(date,listOf(session.copy(status="completed"))))
        // Personal plan takes priority; professional entries do not enter the library.
        val personalExercise=JSONObject().put("id","personal-ex").put("name","Press banca").put("muscleGroup","Pecho")
        state.getJSONArray("exercises").put(personalExercise)
        val personalBlock=JSONObject().put("id","personal-block").put("kind","strength").put("title","Personal")
            .put("exercises",JSONArray().put(JSONObject().put("id","personal-entry").put("exerciseId","personal-ex")
                .put("plannedSets",JSONArray().put(JSONObject().put("id","personal-set").put("targetReps",8)))))
        state.getJSONArray("routines").put(JSONObject().put("id","personal").put("title","Rutina propia")
            .put("scheduledDate","2026-10-25").put("blocks",JSONArray().put(personalBlock)))
        local.write(state.toString().toByteArray())
        assertEquals("personal",repo.todayPlanSession(date,listOf(session))!!.getString("routineId"))
        val stored=local.read()!!
        state.put("activeSession",plan);local.write(state.toString().toByteArray())
        assertNull(repo.todayPlanSession(date,listOf(session)))
        local.write(stored)
    }
    @Test fun malformedProfessionalWatchPrescriptionDoesNotAbortRefreshOrMutatePrivateData() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val owner="malformed-professional-${java.util.UUID.randomUUID()}"
        val local=LocalSnapshotStore(ctx,owner)
        local.write(JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray()).toString().toByteArray())
        val before=local.read()!!
        val date=java.time.LocalDate.of(2026,10,26)
        val missingId=JSONObject().put("schemaVersion",1).put("blocks",JSONArray().put(JSONObject()
            .put("kind","strength").put("exercises",JSONArray())))
        val session=BusinessCenterStore.ProfessionalSession("plan","org","client","coach",date.toString(),"Plan","","scheduled",missingId)
        assertNull(WorkoutRepository(ctx,owner).todayPlanSession(date,listOf(session)))
        val wrongBlock=JSONObject().put("schemaVersion",1).put("blocks",JSONArray().put("not-an-object"))
        assertNull(WorkoutRepository(ctx,owner).todayPlanSession(date,listOf(session.copy(prescription=wrongBlock))))
        assertArrayEquals(before,local.read())
    }
    @Test fun rpeInputAndHistoryUseRirOnWire() {
        var logged:Double?=null
        val workout=ActiveWorkout(id="rpe",title="Fuerza",index=0,total=1,exerciseName="Sentadilla",completedSets=0,
            prescribedQuantity=5,prescribedWeightKg=80.0,allowsWeight=true,sets=emptyList())
        compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.fillMaxSize()) {
            androidx.compose.foundation.lazy.LazyColumn { item {
                ActiveWorkoutCard(workout,false,{_,_,rir,_,_,_,_,_->logged=rir},{_,_,_,_,_,_->},{},{},{},effortUnit="rpe")
            } }
        }}}
        compose.onNodeWithText("RPE opcional (0–10)").performScrollTo().performTextInput("8")
        compose.activity.runOnUiThread {val view=compose.activity.currentFocus; if(view!=null) (compose.activity.getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager).hideSoftInputFromWindow(view.windowToken,0)}
        compose.onNodeWithText("RPE opcional (0–10)").performScrollTo()
        capture("registro_esfuerzo_rpe")
        compose.onNodeWithText("Registrar serie").performScrollTo().performClick()
        assertEquals(2.0,logged!!,0.00001)
    }
    private fun capture(name:String) {
        compose.waitForIdle()
        Thread.sleep(700) // Semantic assertions can precede the committed window frame.
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val bitmap=InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()!!
        val values=android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,"$name.png")
            put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
        }
        val uri=ctx.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
        ctx.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
    }
}
