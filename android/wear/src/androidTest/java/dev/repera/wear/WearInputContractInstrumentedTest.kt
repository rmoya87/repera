package dev.repera.wear
import org.json.*
import org.junit.*
import org.junit.Assert.*
class WearInputContractInstrumentedTest {
 private fun summary(name:String,equipment:String="",sport:String="",catalog:String=""):WatchSessionSummary {
  val exercise=JSONObject().put("id","a").put("name",name).put("equipment",equipment).put("sportTag",sport).put("catalogId",catalog)
  val entry=JSONObject().put("exercise",exercise).put("plannedSets",JSONArray().put(JSONObject().put("targetReps",8).put("targetDurationSeconds",45).put("targetRir",2.0)))
  return WatchSessionSummary.fromJson(JSONObject().put("id","s").put("title","Plan").put("currentIndex",0).put("exercises",JSONArray().put(entry)))
 }
 @Test fun runUsesMetersWithoutInvalidRepsToggleAndMachineHasDurationTarget() {
  val run=summary("Running")
  assertEquals("machineWork",run.inputMode);assertEquals("meters",run.quantityUnit);assertFalse(run.allowsUnitToggle)
  assertEquals(45,run.prescribedDurationSeconds)
  val bike=summary("Air Bike")
  assertEquals("calories",bike.quantityUnit);assertTrue(bike.allowsUnitToggle)
 }
 @Test fun mobilityHoldAndRirPrescriptionsAreReadFromExactExercise() {
  val hold=summary("Postura del niño",sport="Movilidad",catalog="mobility-20")
  assertTrue(hold.mobilityHold);assertEquals("repsAndTime",hold.inputMode)
  assertEquals(2.0,summary("Sentadilla").prescribedRir!!,0.001)
 }
 @Test fun loadedHyroxDistanceAndBodyweightAreNotMisclassifiedAsStrengthReps() {
  val carry=summary("Farmer carry","Mancuernas")
  assertEquals("loadDistance",carry.inputMode);assertEquals("meters",carry.quantityUnit)
  assertTrue(carry.canLogOnWatch);assertTrue(carry.allowsWeight);assertFalse(carry.allowsUnitToggle)
  val burpee=summary("Burpee","Peso corporal")
  assertEquals("repsOnly",burpee.inputMode);assertFalse(burpee.allowsWeight)
 }
 @Test fun hspuTargetIsDeficitAndMissingRepsRemainUnprescribed() {
  val exercise=JSONObject().put("id","h").put("name","HSPU").put("equipment","Pared")
  val entry=JSONObject().put("exercise",exercise).put("plannedSets",JSONArray().put(JSONObject().put("targetWeightKg",12.0)))
  val parsed=WatchSessionSummary.fromJson(JSONObject().put("id","s").put("title","Plan").put("currentIndex",0).put("exercises",JSONArray().put(entry)))
  assertNull(parsed.prescribedReps);assertNull(parsed.prescribedWeightKg)
  assertEquals(12,parsed.prescribedDeficitCm)
 }
 @Test fun warmupChangesDraftCursorWithoutConsumingWorkPrescription() {
  val exercise=JSONObject().put("id","e").put("name","Sentadilla").put("equipment","Barra")
  val entry=JSONObject().put("exercise",exercise)
   .put("plannedSets",JSONArray().put(JSONObject().put("targetReps",8)).put(JSONObject().put("targetReps",6)))
   .put("loggedSets",JSONArray().put(JSONObject().put("phase","warmup")))
  val parsed=WatchSessionSummary.fromJson(JSONObject().put("id","s").put("title","Plan").put("currentIndex",0).put("exercises",JSONArray().put(entry)))
  assertEquals(0,parsed.recordedSets);assertEquals(1,parsed.recordedTotalSets)
  assertEquals(8,parsed.prescribedReps)
 }
}
