package dev.repera.mobile
import dev.repera.domain.RoutineBlock
import dev.repera.domain.RoutineBlockKind
import dev.repera.domain.WODMovement
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class LoadPercentApplyTest {
 private fun root(tested:Double?=null,increment:Double=2.5):JSONObject {
  val prefs=JSONObject()
  if(tested!=null) prefs.put("ex1",JSONObject().put("testedOneRMKg",tested))
  return JSONObject()
   .put("settings",JSONObject().put("weightIncrementKg",increment))
   .put("exerciseLoadPrefs",prefs)
   .put("workouts",JSONArray())
   .put("exercises",JSONArray().put(JSONObject().put("id","ex1").put("name","Back squat")))
 }
 private fun block(vararg m:WODMovement)=RoutineBlock(id="b1",kind=RoutineBlockKind.WOD,title="WOD",movements=m.toList())

 @Test fun fillsKgFromPercentWithTestedOneRMAndKeepsSource() {
  val out=ExerciseLoadGuide.applyPercentLoads(
   listOf(block(WODMovement(name="Back squat",exerciseId="ex1",reps=5,notes="#70%"))),root(tested=100.0))
  val m=out[0].movements[0]
  assertEquals(70.0,m.weightMaleKg!!,0.0001)
  assertEquals("#70% · ~70% 1RM → 70 kg",m.notes)
 }
 @Test fun resolvesExerciseFromCatalogByNormalizedName() {
  val out=ExerciseLoadGuide.applyPercentLoads(
   listOf(block(WODMovement(name="back squat",notes="70%"))),root(tested=100.0))
  assertEquals(70.0,out[0].movements[0].weightMaleKg!!,0.0001)
 }
 @Test fun leavesAloneWeightRestAndUnknownOneRM() {
  val weighted=WODMovement(name="Back squat",exerciseId="ex1",weightMaleKg=60.0,notes="70%")
  val rest=WODMovement(name="Descanso",isRest=true,restSeconds=60)
  val unknown=WODMovement(name="Muscle-up",notes="70%")
  val out=ExerciseLoadGuide.applyPercentLoads(listOf(block(weighted,rest,unknown)),root(tested=100.0))
  assertEquals(60.0,out[0].movements[0].weightMaleKg!!,0.0001)
  assertNull(out[0].movements[1].weightMaleKg)
  assertNull(out[0].movements[2].weightMaleKg)
  assertNull(out[0].movements[2].notes?.takeIf{it.contains("→")})
 }
 @Test fun doesNotDuplicateAnExistingPercentNote() {
  val out=ExerciseLoadGuide.applyPercentLoads(
   listOf(block(WODMovement(name="Back squat",exerciseId="ex1",notes="70% 1RM previo"))),root(tested=100.0))
  assertEquals(70.0,out[0].movements[0].weightMaleKg!!,0.0001)
  assertEquals("70% 1RM previo",out[0].movements[0].notes)
 }
}
