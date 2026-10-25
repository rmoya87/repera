package dev.repera.mobile
import org.json.JSONObject
import org.junit.Test
import org.junit.Assert.*
class ExerciseLoadPreferenceTest {
 @Test fun testedPreferenceRoundsAndClearsWithoutErasingOtherMetadata() {
  val state=JSONObject("""{"exerciseLoadPrefs":{"bench":{"testedOneRMKg":100,"other":"kept"},"squat":{"testedOneRMKg":150}}}""")
  ExerciseLoadPreference.setTested(state,"bench",101.24)
  assertEquals(101.2,ExerciseLoadPreference.tested(state,"bench")!!,0.0001)
  assertEquals("kept",state.getJSONObject("exerciseLoadPrefs").getJSONObject("bench").getString("other"))
  ExerciseLoadPreference.setTested(state,"bench",101.25)
  assertEquals(101.3,ExerciseLoadPreference.tested(state,"bench")!!,0.0001)
  ExerciseLoadPreference.setTested(state,"bench",null)
  assertNull(ExerciseLoadPreference.tested(state,"bench"))
  assertEquals(mapOf("squat" to 150.0),ExerciseLoadPreference.all(state))
 }
 @Test fun invalidValuesAreRejectedNotStored() {
  val state=JSONObject()
  for(v in listOf(-1.0,0.0,Double.NaN,Double.POSITIVE_INFINITY)) {
   var failed=false;try {ExerciseLoadPreference.setTested(state,"x",v)} catch (_:IllegalArgumentException) {failed=true}
   assertTrue(failed)
  }
 }
}
