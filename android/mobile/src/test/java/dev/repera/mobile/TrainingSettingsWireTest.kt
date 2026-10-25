package dev.repera.mobile
import org.json.JSONObject
import org.junit.Test
import org.junit.Assert.*
class TrainingSettingsWireTest {
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
