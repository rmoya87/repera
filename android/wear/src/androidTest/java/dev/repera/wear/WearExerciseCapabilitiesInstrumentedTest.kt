package dev.repera.wear

import androidx.health.services.client.data.*
import org.junit.Assert.*
import org.junit.Test

/** Compiled only until a device is available; does not contact a provider. */
class WearExerciseCapabilitiesInstrumentedTest {
    private fun capabilities(type:ExerciseType,metrics:Set<DataType<*,*>>) = ExerciseCapabilities(mapOf(
        type to ExerciseTypeCapabilities(metrics,emptyMap(),emptyMap(),false)))
    @Test fun partialSupportRequestsOnlyTheSupportedMetric() {
        val selected=WearExerciseCapabilities.strengthMetrics(capabilities(ExerciseType.STRENGTH_TRAINING,
            setOf(DataType.HEART_RATE_BPM)))
        assertEquals(setOf(DataType.HEART_RATE_BPM),selected)
    }
    @Test fun unavailableStrengthOrMetricsNeverSubstitutesRunningOrEmptyConfig() {
        assertThrows(IllegalStateException::class.java) {
            WearExerciseCapabilities.strengthMetrics(capabilities(ExerciseType.RUNNING,setOf(DataType.HEART_RATE_BPM)))
        }
        assertThrows(IllegalStateException::class.java) {
            WearExerciseCapabilities.strengthMetrics(capabilities(ExerciseType.STRENGTH_TRAINING,emptySet()))
        }
    }
}
