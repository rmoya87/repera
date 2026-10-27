package dev.repera.wear

import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.ExerciseCapabilities
import androidx.health.services.client.data.ExerciseType

/** Never request unsupported metrics or substitute another exercise type. */
internal object WearExerciseCapabilities {
    fun strengthMetrics(capabilities:ExerciseCapabilities):Set<DataType<*,*>> {
        check(ExerciseType.STRENGTH_TRAINING in capabilities.supportedExerciseTypes) {
            "Este reloj no admite registro de fuerza con Health Services. Tus series siguen disponibles."
        }
        val supported=capabilities.getExerciseTypeCapabilities(ExerciseType.STRENGTH_TRAINING).supportedDataTypes
        return setOf<DataType<*,*>>(DataType.HEART_RATE_BPM,DataType.CALORIES_TOTAL).intersect(supported).also {
            check(it.isNotEmpty()) {"El reloj no ofrece pulso ni energía para fuerza. Tus series siguen disponibles."}
        }
    }
}
