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
import androidx.health.services.client.getCurrentExerciseInfo
import androidx.health.services.client.getCapabilities
import androidx.health.services.client.clearUpdateCallback
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
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

    private val operations=Mutex()
    private val binding=context.getSharedPreferences("repera.wear.sensor-session",Context.MODE_PRIVATE)
    var problem:String?=null
        private set
    private var terminalObserved=false
    val ended:Boolean get()=terminalObserved
    fun belongsTo(sessionId:String?):Boolean=sessionId!=null && binding.getString("sessionId",null)==sessionId

    private val client: ExerciseClient by lazy {
        HealthServices.getClient(context).exerciseClient
    }

    private var callback:ExerciseUpdateCallback?=null
    @Volatile private var callbackRevision=0L
    private fun newCallback(token:Long) = object : ExerciseUpdateCallback {
        override fun onExerciseUpdateReceived(update: ExerciseUpdate) {
            if(token!=callbackRevision) return
            val state=update.exerciseStateInfo.state
            terminalObserved=state.isEnded
            recording=!state.isEnded && state!=ExerciseState.PREPARING
            paused=state.isPaused
            if(state.isEnded) problem="El registro de sensores ha terminado. Tus series siguen guardadas."
            val hr = update.latestMetrics.getData(DataType.HEART_RATE_BPM)
                .lastOrNull()?.value
            if(hr!=null) heartRateBpm = hr.takeIf {it.isFinite() && it in 25.0..250.0}?.toInt()
            update.latestMetrics.getData(DataType.CALORIES_TOTAL)?.total
                ?.takeIf {it.isFinite() && it>=0}?.let {energyKcal=it}
            onUpdate?.invoke()
        }

        override fun onAvailabilityChanged(
            dataType: DataType<*, *>, availability: Availability
        ) = Unit

        override fun onLapSummaryReceived(
            lapSummary: androidx.health.services.client.data.ExerciseLapSummary
        ) = Unit

        override fun onRegistered() = Unit

        override fun onRegistrationFailed(throwable: Throwable) {
            if(token!=callbackRevision) return
            problem="No se pudo conectar con los sensores del reloj"
            onUpdate?.invoke()
        }
    }

    /** Invalidate before awaiting clear: already queued callbacks cannot mutate the next owner. */
    private suspend fun registerCallback() {
        callbackRevision++
        callback?.let {client.clearUpdateCallback(it)}
        val next=newCallback(callbackRevision)
        callback=next
        client.setUpdateCallback(next)
    }

    /** Empieza a registrar fuerza si aún no hay ejercicio en curso. */
    suspend fun start(sessionId:String,exerciseType:ExerciseType=ExerciseType.STRENGTH_TRAINING,stillAuthorized:()->Boolean={true}) = operations.withLock {
        check(stillAuthorized()) {"La sesión cambió antes de iniciar sensores"}
        require(sessionId.isNotBlank())
        if (recording) {
            check(binding.getString("sessionId",null)==sessionId) {"Los sensores pertenecen a otra sesión de Repera"}
            return@withLock
        }
        val info=client.getCurrentExerciseInfo()
        check(stillAuthorized()) {"La sesión cambió durante la consulta de sensores"}
        if(info.exerciseTrackedStatus==ExerciseOwnership.OTHER) {
            problem="Otra app está registrando un ejercicio. No se ha interrumpido."
            onUpdate?.invoke()
            return@withLock
        }
        check(info.exerciseTrackedStatus in setOf(ExerciseOwnership.NONE,ExerciseOwnership.OWNED)) {"No se pudo verificar el ejercicio del reloj"}
        if(info.exerciseTrackedStatus==ExerciseOwnership.OWNED && binding.getString("sessionId",null)!=sessionId) {
            problem="Hay otro registro de Repera en curso. No se ha reiniciado ni asociado a esta sesión."
            onUpdate?.invoke()
            return@withLock
        }
        val metrics=if(info.exerciseTrackedStatus==ExerciseOwnership.NONE) {
            val capabilities=client.getCapabilities()
            check(stillAuthorized()) {"La sesión cambió durante la consulta de capacidades"}
            WearExerciseCapabilities.healthMetrics(capabilities,exerciseType)
        } else emptySet()
        terminalObserved=false
        problem=null
        // Reattach awaits fresh provider samples, never show readings retained by a previous registration.
        heartRateBpm=null
        energyKcal=null
        paused=false
        check(stillAuthorized()) {"La sesión cambió antes de conectar sensores"}
        registerCallback()
        check(stillAuthorized()) {"La sesión cambió durante el registro del callback"}
        if(info.exerciseTrackedStatus==ExerciseOwnership.OWNED) {
            // Reattach, never replace our surviving exercise after Activity/process recreation.
            recording=!terminalObserved
            onUpdate?.invoke()
            return@withLock
        }
        val config = ExerciseConfig.Builder(exerciseType)
            .setDataTypes(metrics)
            .setIsAutoPauseAndResumeEnabled(false)
            .setIsGpsEnabled(false)
            .build()
        check(stillAuthorized()) {"La sesión cambió antes de iniciar sensores"}
        check(binding.edit().putString("sessionId",sessionId).commit()) {"No se pudo guardar la identidad del registro"}
        check(stillAuthorized()) {"La sesión cambió antes de iniciar sensores"}
        client.startExercise(config)
        recording=!terminalObserved
        onUpdate?.invoke()
    }

    /** A failed await is not proof that the provider has no surviving exercise. */
    suspend fun canReleaseAfterStartFailure():Boolean = operations.withLock {
        val info=client.getCurrentExerciseInfo()
        info.exerciseTrackedStatus==ExerciseOwnership.NONE || info.exerciseTrackedStatus==ExerciseOwnership.OTHER
    }

    /** Pausa el registro (play/pausa del reloj, igual que watchOS). */
    suspend fun pause(sessionId:String,stillAuthorized:()->Boolean={true}) = operations.withLock {
        check(stillAuthorized()) {"La sesión cambió antes de pausar sensores"}
        check(binding.getString("sessionId",null)==sessionId) {"El registro de sensores no corresponde a esta sesión"}
        if (!recording || paused) return@withLock
        client.pauseExercise()
        // Only the callback confirms the paused state.
    }

    /** Reanuda el registro tras una pausa. */
    suspend fun resume(sessionId:String,stillAuthorized:()->Boolean={true}) = operations.withLock {
        check(stillAuthorized()) {"La sesión cambió antes de reanudar sensores"}
        check(binding.getString("sessionId",null)==sessionId) {"El registro de sensores no corresponde a esta sesión"}
        if (!paused) return@withLock
        client.resumeExercise()
    }

    suspend fun detach() = operations.withLock {
        onUpdate=null
        callbackRevision++
        callback?.let {client.clearUpdateCallback(it)}
        callback=null
    }

    /** Termina el registro conservando las últimas lecturas en pantalla. */
    suspend fun stop(sessionId:String?) = operations.withLock {
        if (sessionId==null || binding.getString("sessionId",null)!=sessionId) return@withLock
        val info=client.getCurrentExerciseInfo()
        check(binding.getString("sessionId",null)==sessionId) {"La identidad de sensores cambió antes de terminar"}
        if(info.exerciseTrackedStatus==ExerciseOwnership.NONE) {
            recording=false;paused=false;terminalObserved=true;onUpdate?.invoke();return@withLock
        }
        check(info.exerciseTrackedStatus==ExerciseOwnership.OWNED) {"Otra app registra un ejercicio; no se ha interrumpido"}
        // A surviving exercise may be owned even before this process received its first callback.
        registerCallback()
        check(binding.getString("sessionId",null)==sessionId) {"La identidad de sensores cambió al conectar el fin"}
        client.endExercise()
        // The terminal update confirms recording/paused. Do not invent success here.
    }
}
