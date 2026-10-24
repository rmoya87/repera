package dev.repera.wear

import android.content.Context
import androidx.health.services.client.ExerciseClient
import androidx.health.services.client.ExerciseUpdateCallback
import androidx.health.services.client.HealthServices
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.ExerciseConfig
import androidx.health.services.client.data.ExerciseState
import androidx.health.services.client.data.ExerciseType
import androidx.health.services.client.data.ExerciseUpdate
import androidx.health.services.client.endExercise
import androidx.health.services.client.pauseExercise
import androidx.health.services.client.resumeExercise
import androidx.health.services.client.startExercise

/**
 * Registro del entreno en el reloj con Health Services (equivalente a
 * WatchHealthKitSession de watchOS): pulso y kcal en vivo mientras la
 * sesión está activa. La sesión grabada por Repera queda excluida de la
 * actividad "externa" en el teléfono (mismo package), igual que iOS
 * excluye los HKWorkout propios.
 */
class WearHealthSession(private val context: Context) {

    var heartRateBpm: Int? = null
        private set
    var energyKcal: Double? = null
        private set
    var recording: Boolean = false
        private set
    var paused: Boolean = false
        private set
    var onUpdate: (() -> Unit)? = null

    private val client: ExerciseClient by lazy {
        HealthServices.getClient(context).exerciseClient
    }

    private val callback = object : ExerciseUpdateCallback {
        override fun onExerciseUpdateReceived(update: ExerciseUpdate) {
            val hr = update.latestMetrics.getData(DataType.HEART_RATE_BPM)
                .lastOrNull()?.value
            heartRateBpm = hr?.toInt()
            energyKcal = update.latestMetrics.getData(DataType.CALORIES_TOTAL)
                ?.total
            onUpdate?.invoke()
        }

        override fun onAvailabilityChanged(
            dataType: DataType<*, *>, availability: Availability
        ) = Unit

        override fun onLapSummaryReceived(
            lapSummary: androidx.health.services.client.data.ExerciseLapSummary
        ) = Unit

        override fun onRegistered() = Unit

        override fun onRegistrationFailed(throwable: Throwable) = Unit
    }

    /** Empieza a registrar fuerza si aún no hay ejercicio en curso. */
    suspend fun start() {
        if (recording) return
        client.setUpdateCallback(callback)
        val config = ExerciseConfig.Builder(ExerciseType.STRENGTH_TRAINING)
            .setDataTypes(setOf(DataType.HEART_RATE_BPM, DataType.CALORIES_TOTAL))
            .setIsAutoPauseAndResumeEnabled(false)
            .setIsGpsEnabled(false)
            .build()
        client.startExercise(config)
        recording = true
    }

    /** Pausa el registro (play/pausa del reloj, igual que watchOS). */
    suspend fun pause() {
        if (!recording || paused) return
        runCatching { client.pauseExercise() }
        paused = true
    }

    /** Reanuda el registro tras una pausa. */
    suspend fun resume() {
        if (!paused) return
        runCatching { client.resumeExercise() }
        paused = false
    }

    /** Termina el registro conservando las últimas lecturas en pantalla. */
    suspend fun stop() {
        if (!recording) return
        runCatching { client.endExercise() }
        recording = false
        paused = false
        onUpdate?.invoke()
    }
}
