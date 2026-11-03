package dev.repera.mobile
import org.json.JSONObject
import org.junit.Test
import org.junit.Assert.*
class TrainingSettingsWireTest {
 @Test fun optionalHeartRateMaximumRoundTrip() {
  val state = org.json.JSONObject()
  val customized = TrainingSettings(heartRateMaxBpm = 175)
  TrainingSettings.apply(state, customized)
  assertEquals(175, TrainingSettings.read(state).heartRateMaxBpm)
  TrainingSettings.apply(state, customized.copy(heartRateMaxBpm = null))
  assertNull(TrainingSettings.read(state).heartRateMaxBpm)
 }


    @Test fun effortPreferenceAndLegacyWeightChoicePreserveUnknownKeys() {
        val state=JSONObject().put("settings",JSONObject().put("weightUnit","lb").put("effortUnit","rpe").put("future",true))
        val value=TrainingSettings.read(state)
        assertEquals("lb",value.weightUnit);assertEquals("rpe",value.effortUnit)
        TrainingSettings.apply(state,value.copy(defaultRestSeconds=120))
        val reread=TrainingSettings.read(state)
        assertEquals("lb",reread.weightUnit);assertEquals("rpe",reread.effortUnit)
        assertTrue(state.getJSONObject("settings").getBoolean("future"))
    }
}
