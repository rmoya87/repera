package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class StrengthBenchmarkProfileSettingsTest {
    @Test fun persistsInSingleSettingsSnapshot() {
        val state = JSONObject()
        TrainingSettings.apply(state, TrainingSettings(
            competitionSex = "female", birthYear = 1987, strengthReferenceFrame = "elite"
        ))
        assertEquals("female", TrainingSettings.read(state).competitionSex)
        assertEquals(1987, TrainingSettings.read(state).birthYear)
        assertEquals("elite", TrainingSettings.read(state).strengthReferenceFrame)
        assertNull(state.optJSONObject("settings")?.opt("bodyWeightKg"))
    }

    @Test fun missingLegacyFieldsStayOptional() {
        val legacy = JSONObject().put("settings", JSONObject()
            .put("heartRateMaxBpm", 175))
        val read = TrainingSettings.read(legacy)
        assertNull(read.competitionSex)
        assertNull(read.birthYear)
        assertEquals("amateur", read.strengthReferenceFrame)
    }

    @Test fun clearingProfileDoesNotKeepStaleBirthYear() {
        val state = JSONObject()
        TrainingSettings.apply(state, TrainingSettings(competitionSex = "male", birthYear = 1990))
        TrainingSettings.apply(state, TrainingSettings(competitionSex = null, birthYear = null))
        assertNull(TrainingSettings.read(state).competitionSex)
        assertNull(TrainingSettings.read(state).birthYear)
    }
}
