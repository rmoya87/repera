package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.RoutineBlock
import org.json.*
import org.junit.Assert.*
import org.junit.Test

/** Prepared and compiled only: NOT executed (no device in the recovery sandbox). */
class RoutineBlockCountContractInstrumentedTest {
 private fun fixture():Pair<WorkoutRepository,LocalSnapshotStore> {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-block-count-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(context,account)
  local.write(JSONObject().put("exercises",JSONArray().put(JSONObject().put("id","a").put("name","Sentadilla")))
   .put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray())
  return WorkoutRepository(context,account) to local
 }
 private fun drafts(n:Int)=List(n) {RoutineBlockDraft("B$it","strength",listOf(RoutineDraftEntry("a",5)))}
 @Test fun draftsAndEditAcceptElevenAndTwelveBlocksAndStillRequireOne() {
  val (repo,local)=fixture()
  val id=repo.createRoutineFromDrafts("Larga",drafts(12))
  assertEquals(12,JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0).getJSONArray("blocks").length())
  repo.replaceRoutineBlocks(id,drafts(11))
  assertEquals(11,JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0).getJSONArray("blocks").length())
  val before=local.read()!!
  assertTrue(runCatching {repo.replaceRoutineBlocks(id,emptyList())}.isFailure)
  assertArrayEquals(before,local.read()!!)
 }
 @Test fun scannerAcceptsMoreThanTenBlocks() {
  val (repo,local)=fixture()
  repo.createRoutineFromScan("Escaneada",List(11) {RoutineBlock.strength("F$it")})
  assertEquals(11,JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0).getJSONArray("blocks").length())
  assertTrue(runCatching {repo.createRoutineFromScan("Vacía",emptyList())}.isFailure)
 }
 @Test fun aiPathKeepsItsExplicitTwelveBlockCap() {
  val (repo,local)=fixture()
  val schedule=RoutineSchedule(scheduledDate="2026-10-26")
  fun plan(n:Int,resolve:(String,String?)->String)=List(n) {RoutineBlock.strength("B$it",listOf(dev.repera.domain.RoutineExercise(exerciseId=resolve("Synthetic new",null),plannedSets=listOf(dev.repera.domain.PlannedSet(targetReps=5)))))}
  assertTrue(runCatching {repo.importAiRoutine("plan13",schedule) {r->"Plan" to plan(13,r)}}.isFailure)
  assertEquals(0,JSONObject(String(local.read()!!)).getJSONArray("routines").length())
  repo.importAiRoutine("plan12",schedule) {r->"Plan" to plan(12,r)}
  assertEquals(12,JSONObject(String(local.read()!!)).getJSONArray("routines").getJSONObject(0).getJSONArray("blocks").length())
 }
}
