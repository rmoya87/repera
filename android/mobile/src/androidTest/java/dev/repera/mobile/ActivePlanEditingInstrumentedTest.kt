package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.Rule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class ActivePlanEditingInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun activeEditorUiCancelsWithoutWritesAndSavesPlanWithoutLosingFailureSet() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-active-editor-ui-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(context,account)
  local.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","a").put("name","Sentadilla")))
   .put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray())
  val repo=WorkoutRepository(context,account);val r=repo.createRoutine("Pierna","strength",listOf(RoutineDraftEntry("a",5)))
  var active by mutableStateOf(repo.startRoutine(r));repo.logCurrentSet(5,40.0,toFailure=true);active=repo.active()!!
  var draft by mutableStateOf<RoutineEntry?>(null)
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.fillMaxSize().safeDrawingPadding()) {
   val editing=draft
   if(editing==null) Column {
    ActiveSessionControls(active,false,{},{},onEdit={draft=repo.activeRoutineForEditing()})
    Text("${active.sets.size} series conservadas")
   } else RoutineBlocksEditorScreen(editing,listOf(ExerciseEntry("a","Sentadilla",true,true)),false,
    onReplace={blocks ->active=repo.updateActiveSessionPlan(editing.id,blocks);draft=null},onBack={draft=null})
  }}}
  val before=local.read()!!
  compose.onNodeWithText("Editar entreno").performClick()
  compose.onNodeWithText("Título del bloque").performTextReplacement("Cambio descartado")
  compose.onNodeWithText("Volver").performScrollTo().performClick()
  compose.runOnIdle {assertArrayEquals(before,local.read()!!)}
  compose.onNodeWithText("Editar entreno").performClick()
  compose.onNodeWithText("Título del bloque").performTextReplacement("Fuerza ajustada")
  // Remove keyboard and wait for a complete rendered editor viewport before taking evidence.
  compose.activity.runOnUiThread {compose.activity.currentFocus?.let {v ->
   (compose.activity.getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager).hideSoftInputFromWindow(v.windowToken,0)}}
  compose.onNodeWithText("Guardar").performScrollTo().assertIsDisplayed()
  compose.waitForIdle();compose.mainClock.advanceTimeBy(500);compose.waitForIdle()
  val instrument=InstrumentationRegistry.getInstrumentation();instrument.waitForIdleSync()
  Thread.sleep(300)
  val root=instrument.uiAutomation.rootInActiveWindow
  org.junit.Assert.assertEquals("Screenshot must show the app, not a system overlay",instrument.targetContext.packageName,root?.packageName?.toString())
  val bitmap=instrument.uiAutomation.takeScreenshot()!!
  val values=android.content.ContentValues().apply {
   put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,"entreno_editor_activo.png")
   put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
   put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
  }
  val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
  context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
  compose.onNodeWithText("Guardar").performClick()
  compose.onNodeWithText("1 series conservadas").assertIsDisplayed()
  compose.runOnIdle {
   assertTrue(active.sets.single().toFailure);assertEquals(5,active.sets.single().reps)
   assertEquals("Fuerza ajustada",JSONObject(String(local.read()!!)).getJSONObject("activeSession").getJSONArray("routineBlocks").getJSONObject(0).getString("title"))
  }
 }

 @Test fun editorDraftIsReadOnlyAndSavedReorderKeepsSessionAndLoggedSets() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-active-editor-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(context,account)
  local.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","a").put("name","Sentadilla"))
   .put(JSONObject().put("id","b").put("name","Press banca"))).put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray())
  val repo=WorkoutRepository(context,account);val routine=repo.createRoutine("Dos","strength",listOf(RoutineDraftEntry("a",5),RoutineDraftEntry("b",8)))
  val started=repo.startRoutine(routine);repo.logCurrentSet(5,40.0,toFailure=true);repo.selectActiveExercise(1);repo.logCurrentSet(8,50.0)
  val before=local.read()!!;val draft=repo.activeRoutineForEditing();assertArrayEquals(before,local.read()!!)
  val saved=repo.updateActiveSessionPlan(draft.id,listOf(RoutineBlockDraft(title="Cambio",format="strength",
   entries=listOf(RoutineDraftEntry("b",10),RoutineDraftEntry("a",12)),blockId=draft.blocks.single().id)))
  assertEquals(started.id,saved.id);assertEquals(0,saved.index);assertEquals("Press banca",saved.exerciseName)
  assertEquals(8,saved.sets.single().reps)
  repo.selectActiveExercise(1);assertTrue(repo.active()!!.sets.single().toFailure)
  val after=JSONObject(String(local.read()!!)).getJSONObject("activeSession")
  assertEquals(JSONObject(String(before)).getJSONObject("activeSession").getString("startedAt"),after.getString("startedAt"))
  assertEquals(12,after.getJSONArray("exercises").getJSONObject(1).getJSONArray("plannedSets").getJSONObject(0).getInt("targetReps"))
 }
 @Test fun abandonedStandaloneEditorCreatesNothingAndInvalidSaveIsAtomic() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-active-editor-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(context,account)
  local.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","a").put("name","Sentadilla")))
   .put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray())
  val repo=WorkoutRepository(context,account);repo.startQuickLog("a");val before=local.read()!!
  val draft=repo.activeRoutineForEditing();assertArrayEquals(before,local.read()!!);assertEquals(1,draft.blocks.size)
  assertThrows(IllegalArgumentException::class.java) {repo.updateActiveSessionPlan(draft.id,emptyList())}
  assertArrayEquals(before,local.read()!!)
 }
 @Test fun standaloneActiveEditorChecksTemplateQuotaBeforeCreatingAnythingAndRejectsStaleSession() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="active-plan-gate-"+java.util.UUID.randomUUID()
  val storage=LocalSnapshotStore(context,account)
  storage.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","a").put("name","Sentadilla")))
   .put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray())
  val repo=WorkoutRepository(context,account);val active=repo.startQuickLog("a");val draft=repo.activeRoutineForEditing()
  assertEquals(draft.id,repo.activeRoutineForEditing().id)
  val blocks=listOf(RoutineBlockDraft(format="strength",entries=listOf(RoutineDraftEntry("a",5))))
  val before=storage.read()!!
  assertThrows(IllegalStateException::class.java) {repo.updateActiveSessionPlan(draft.id,blocks,expectedSessionId=active.id,canCreateTemplate={false})}
  assertArrayEquals(before,storage.read()!!)
  assertThrows(IllegalStateException::class.java) {repo.updateActiveSessionPlan(draft.id,blocks,expectedSessionId="other")}
  assertArrayEquals(before,storage.read()!!)
  repo.updateActiveSessionPlan(draft.id,blocks,expectedSessionId=active.id,canCreateTemplate={true})
  assertEquals(draft.id,JSONObject(String(storage.read()!!)).getJSONObject("activeSession").getString("routineId"))
  repo.updateActiveSessionPlan(draft.id,blocks,expectedSessionId=active.id,canCreateTemplate={false})
  assertEquals(1,JSONObject(String(storage.read()!!)).getJSONArray("routines").length())
 }
 @Test fun activeEditorCannotOverwriteAnotherExistingRoutineWithUnrelatedDraftId() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="active-plan-unrelated-"+java.util.UUID.randomUUID();val local=LocalSnapshotStore(context,account)
  local.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","a").put("name","Sentadilla")))
   .put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray())
  val repo=WorkoutRepository(context,account)
  val unrelated=repo.createRoutine("No tocar","strength",listOf(RoutineDraftEntry("a",5)))
  val active=repo.startQuickLog("a");val before=local.read()!!
  assertThrows(IllegalStateException::class.java) {repo.updateActiveSessionPlan(unrelated,
   listOf(RoutineBlockDraft(format="strength",entries=listOf(RoutineDraftEntry("a",8)))),expectedSessionId=active.id)}
  assertArrayEquals(before,local.read()!!)
 }
}
