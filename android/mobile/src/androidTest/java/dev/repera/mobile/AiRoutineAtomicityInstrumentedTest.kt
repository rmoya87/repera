package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.*
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class AiRoutineAtomicityInstrumentedTest {
 private fun fixture():Triple<WorkoutRepository,LocalSnapshotStore,String> {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-ai-atomic-"+java.util.UUID.randomUUID()
  val store=LocalSnapshotStore(context,account)
  store.write(JSONObject().put("exercises",JSONArray()).put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray())
  return Triple(WorkoutRepository(context,account),store,account)
 }
 private val schedule=RoutineSchedule(scheduledDate="2026-10-26")
 private fun blocks(id:String,count:Int=1)=List(count) {RoutineBlock.strength("Bloque",listOf(RoutineExercise(exerciseId=id,plannedSets=listOf(PlannedSet(targetReps=5)))))}
 @Test fun failedBuildOrFinalValidationLeavesNoCatalogOrRoutine() {
  val (repo,store)=fixture();val before=store.read()!!
  assertTrue(runCatching {repo.importAiRoutine("failed",schedule) {resolve ->resolve("Synthetic new",null);error("late error")}}.isFailure)
  assertArrayEquals(before,store.read())
  assertTrue(runCatching {repo.importAiRoutine("invalid",schedule) {resolve ->"" to blocks(resolve("Synthetic new",null))}}.isFailure)
  assertArrayEquals(before,store.read())
 }
 @Test fun twelveBlockPlanSavesOnceAndRetryKeepsEditsWithoutRebuilding() {
  val (repo,store)=fixture()
  repo.importAiRoutine("plan",schedule) {resolve ->"Plan" to blocks(resolve("Synthetic new",null),12)}
  val saved=JSONObject(String(store.read()!!));assertEquals(1,saved.getInt("syncRevision"))
  assertEquals(1,saved.getJSONArray("exercises").length());assertEquals(12,saved.getJSONArray("routines").getJSONObject(0).getJSONArray("blocks").length())
  val before=store.read()!!
  repo.importAiRoutine("plan",schedule) {error("idempotent retry must not rebuild")}
  assertArrayEquals(before,store.read())
 }
 @Test fun concurrentEditOrRevocationCannotLeaveHalfImportedCatalog() {
  val (repo,store,account)=fixture();var allowed=true
  val before=store.read()!!
  assertTrue(runCatching {repo.importAiRoutine("revoked",schedule,stillAuthorized={allowed}) {resolve ->
   val id=resolve("Synthetic new",null);allowed=false;"Plan" to blocks(id)
  }}.isFailure);assertArrayEquals(before,store.read())
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  assertTrue(runCatching {repo.importAiRoutine("stale",schedule) {resolve ->
   val id=resolve("Synthetic new",null)
   WorkoutRepository(context,account).resolveOrCreateCatalogExercise("Other saved",null)
   "Plan" to blocks(id)
  }}.isFailure)
  val after=JSONObject(String(store.read()!!))
  assertEquals(0,after.getJSONArray("routines").length())
  assertEquals("Other saved",after.getJSONArray("exercises").getJSONObject(0).getString("name"))
  assertEquals(1,after.getJSONArray("exercises").length())
 }
 @Test fun scannerRetryWithStableIdKeepsSingleEditedRoutine() {
  val (repo,store)=fixture()
  val empty=listOf(RoutineBlock.strength("Fuerza"))
  repo.createRoutineFromScan("Escaneada",empty,routineId="scan-request")
  repo.updateRoutineDetails("scan-request","Editada",RoutineSchedule())
  val before=store.read()!!
  repo.createRoutineFromScan("Escaneada",empty,routineId="scan-request")
  assertArrayEquals(before,store.read())
  assertEquals(1,JSONObject(String(store.read()!!)).getJSONArray("routines").length())
 }
}
