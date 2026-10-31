package dev.repera.wear

import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.ExerciseCapabilities
import androidx.health.services.client.data.ExerciseType

/** Never request unsupported metrics or substitute another exercise type. */
internal object WearExerciseCapabilities {
    fun strengthMetrics(capabilities:ExerciseCapabilities):Set<DataType<*,*>> =
        healthMetrics(capabilities,ExerciseType.STRENGTH_TRAINING)

    /** Only subscribe to metrics supported for the exact sport on this device. */
    fun healthMetrics(capabilities:ExerciseCapabilities,type:ExerciseType):Set<DataType<*,*>> {
        check(type in capabilities.supportedExerciseTypes) {
            "Este reloj no admite el tipo de actividad seleccionado en Health Services."
        }
        val supported=capabilities.getExerciseTypeCapabilities(type).supportedDataTypes
        return setOf<DataType<*,*>>(DataType.HEART_RATE_BPM,DataType.CALORIES_TOTAL).intersect(supported).also {
            check(it.isNotEmpty()) {"El reloj no ofrece pulso ni energía para esta actividad."}
        }
    }
}
