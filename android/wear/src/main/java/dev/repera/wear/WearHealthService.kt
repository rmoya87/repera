package dev.repera.wear

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.os.*
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import androidx.health.services.client.data.ExerciseType

/** Owns Health Services independently of Activity. Starts only from visible UI. */
internal class WearHealthService:Service() {
    private val scope=CoroutineScope(SupervisorJob()+Dispatchers.Main.immediate)
    private val cache by lazy {getSharedPreferences("repera.wear.session",MODE_PRIVATE)}
    private val sensors by lazy {WearHealthSession(applicationContext).apply {onUpdate={publish()}}}
    private var owner:String?=null
    private var observer:((Snapshot)->Unit)?=null
    private var status:String?=null
    private var ending=false
    private var foreground=false
    private var revision=0L
    private var starting=false
    // Last delivered start id: stopSelfResult(lastStartId) does not stop the service if a newer start request is pending.
    private var lastStartId=-1
    data class Snapshot(val sessionId:String?,val heart:Int?,val energy:Double?,val recording:Boolean,val paused:Boolean,val problem:String?)
    inner class Connection:Binder() {
        fun observe(callback:((Snapshot)->Unit)?) {observer=callback;if(callback!=null) callback(snapshot())}
        fun pause(id:String,paused:Boolean) {
            if(id!=owner || !isCurrent(id)) return
            val token=revision
            scope.launch {runCatching {
                if(paused) sensors.pause(id) {token==revision && isCurrent(id)}
                else sensors.resume(id) {token==revision && isCurrent(id)}
            }.onFailure {status=it.localizedMessage;publish()}}
        }
        fun stop(id:String?) {if(id!=null && id==owner) endOwned(id)}
    }
    private val binder=Connection()
    private val changes=SharedPreferences.OnSharedPreferenceChangeListener {_,key ->
        if(key=="snapshot" || key=="companionLiveSensor") owner?.takeUnless {isCurrent(it)}?.let {endOwned(it)}
    }
    override fun onCreate() {super.onCreate();cache.registerOnSharedPreferenceChangeListener(changes)}
    override fun onBind(intent:Intent?):IBinder=binder
    private fun cachedId():String?=cache.getString("snapshot",null)?.let {
        runCatching {JSONObject(it).getString("id")}.getOrNull()
    }
    private fun companionLiveId():String?=cache.getString("companionLiveSensor",null)
    private fun isCurrent(id:String)=cachedId()==id || companionLiveId()==id
    private fun exerciseTypeFor(id:String):ExerciseType {
        if(companionLiveId()!=id) return ExerciseType.STRENGTH_TRAINING
        return when(cache.getString("companionLiveSport",null)) {
            "walking" -> ExerciseType.WALKING
            "running", "trail" -> ExerciseType.RUNNING
            "hiking" -> ExerciseType.HIKING
            "cycling", "gravel", "mountainBike" -> ExerciseType.BIKING
            else -> ExerciseType.WORKOUT
        }
    }
    private fun snapshot()=Snapshot(owner,sensors.heartRateBpm,sensors.energyKcal,sensors.recording,sensors.paused,status ?: sensors.problem)
    private fun publish() {
        observer?.invoke(snapshot())
        if(foreground) runCatching {
            // Update the existing foreground notification through the service API.
            // POST_NOTIFICATIONS is optional for FGS and must not gate sensor continuity.
            startForeground(NOTIFICATION,notification(),if(Build.VERSION.SDK_INT>=34) ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH else 0)
        }.onFailure {status="No se pudo actualizar el aviso del registro; revisa Repera en el reloj."}
        if(sensors.ended) {
            owner?.let {id ->
                if(!cache.edit().putString("sensorEndedSessionId",id).commit()) {
                    status="No se pudo guardar el fin de sensores. Revisa el reloj.";return
                }
            }
        }
        if(dev.repera.domain.WatchSensorLifetime.mayRetire(starting,sensors.ended)) {
            ending=false;owner=null;stopForeground(STOP_FOREGROUND_REMOVE);foreground=false;stopSelfResult(lastStartId)
        }
    }
    override fun onStartCommand(intent:Intent?,flags:Int,startId:Int):Int {
        lastStartId=startId
        val id=intent?.getStringExtra("sessionId")
        // Even a stale/terminal startForegroundService intent must promote before retiring.
        // Returning first would leave Android's foreground-promotion deadline unsatisfied.
        try {
            startForeground(NOTIFICATION,notification(),if(Build.VERSION.SDK_INT>=34) ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH else 0)
            foreground=true
        } catch(e:RuntimeException) {
            status=e.localizedMessage ?: "No se pudo mantener el registro en primer plano"
            observer?.invoke(snapshot());stopSelf(startId);return START_NOT_STICKY
        }
        if(id.isNullOrBlank() || !isCurrent(id)) {
            if(owner==null) {stopForeground(STOP_FOREGROUND_REMOVE);foreground=false;stopSelf(startId)}
            return START_NOT_STICKY
        }
        if(cache.getString("sensorEndedSessionId",null)==id) {
            status="Los sensores de esta sesión ya terminaron. Tus series siguen disponibles."
            observer?.invoke(snapshot())
            if(owner==null) {stopForeground(STOP_FOREGROUND_REMOVE);foreground=false;stopSelf(startId)}
            return START_NOT_STICKY
        }
        if(owner!=null && owner!=id) {status="Otro registro de sensores sigue pendiente de terminar";publish();return START_NOT_STICKY}
        if(ending) {status="Espera a que termine el registro anterior";publish();return START_NOT_STICKY}
        if(starting) return START_NOT_STICKY
        owner=id;status=null;starting=true
        val token=revision
        scope.launch {
            val result=runCatching {sensors.start(id,exerciseTypeFor(id)) {token==revision && isCurrent(id)}}
            result.onFailure {status=it.localizedMessage ?: "No se pudo iniciar sensores"}
            // recording=false can mean a failed callback/start await, not provider termination.
            // Retain the foreground owner on unknown/owned status so visible UI can retry/stop.
            val releasable=if(!sensors.recording && !sensors.ended) runCatching {
                sensors.canReleaseAfterStartFailure()
            }.getOrDefault(false) else false
            starting=false
            publish()
            if(releasable && owner==id && !ending) {owner=null;stopForeground(STOP_FOREGROUND_REMOVE);foreground=false;stopSelfResult(lastStartId)}
        }
        return START_NOT_STICKY
    }
    private fun endOwned(id:String) {
        if(owner!=id || ending) return
        revision++;ending=true
        scope.launch {
            runCatching {sensors.stop(id)}.onFailure {
                ending=false;status="No se pudo detener sensores. Abre Repera para revisar el registro.";publish()
            }
            publish()
        }
    }
    private fun notification():Notification {
        getSystemService(NotificationManager::class.java).createNotificationChannel(NotificationChannel(CHANNEL,"Entrenamiento",NotificationManager.IMPORTANCE_LOW))
        val open=PendingIntent.getActivity(this,801,Intent(this,WearMainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        return NotificationCompat.Builder(this,CHANNEL).setSmallIcon(R.drawable.ic_repera_complication)
            .setContentTitle("Repera · Entrenamiento")
            .setContentText(status ?: sensors.problem ?: if(ending) "Terminando sensores" else if(sensors.paused) "Sensores en pausa" else if(sensors.recording) "Registro de sensores activo" else "Conectando con sensores")
            .setOngoing(true).setOnlyAlertOnce(true).setContentIntent(open).build()
    }
    override fun onDestroy() {
        revision++;observer=null;cache.unregisterOnSharedPreferenceChangeListener(changes)
        // Detach callback, not endExercise: a surviving exercise is reattached from visible UI.
        scope.launch {runCatching {sensors.detach()};scope.cancel()}
        stopForeground(STOP_FOREGROUND_REMOVE);foreground=false;super.onDestroy()
    }
    companion object {
        private const val CHANNEL="repera.wear.exercise"
        private const val NOTIFICATION=8101
        fun startFromVisibleUI(context:Context,id:String) {
            androidx.core.content.ContextCompat.startForegroundService(context,
                Intent(context,WearHealthService::class.java).putExtra("sessionId",id))
        }
    }
}
