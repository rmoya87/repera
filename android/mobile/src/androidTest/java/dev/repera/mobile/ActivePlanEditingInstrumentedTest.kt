package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class ActivePlanEditingInstrumentedTest {
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
}
