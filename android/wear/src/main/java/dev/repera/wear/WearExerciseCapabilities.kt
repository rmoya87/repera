package dev.repera.wear

import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.ExerciseCapabilities
import androidx.health.services.client.data.ExerciseType

/** Never request unsupported metrics or substitute another exercise type. */
internal object WearExerciseCapabilities {
    fun strengthMetrics(capabilities:ExerciseCapabilities):Set<DataType<*,*>> =
        metricsFor(capabilities, ExerciseType.STRENGTH_TRAINING)

    fun metricsFor(
        capabilities: ExerciseCapabilities,
        type: ExerciseType,
        includeDistance: Boolean = false
    ): Set<DataType<*, *>> {
        check(type in capabilities.supportedExerciseTypes) {
            "Este reloj no permite medir este deporte con Health Services."
        }
        val supported = capabilities.getExerciseTypeCapabilities(type).supportedDataTypes
        // Pedir TOTAL y deltas: algunos relojes solo exponen CALORIES.
        val wanted = buildSet {
            add(DataType.HEART_RATE_BPM)
            add(DataType.CALORIES_TOTAL)
            add(DataType.CALORIES)
            if (includeDistance) add(DataType.DISTANCE_TOTAL)
        }
        return wanted.intersect(supported).also {
            check(it.isNotEmpty()) { "El reloj no ofrece pulso ni energía para este deporte." }
        }
    }
}
