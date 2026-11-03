package dev.repera.wear

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.os.*
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import androidx.health.services.client.data.ExerciseType
import androidx.wear.ongoing.OngoingActivity
import com.google.android.gms.wearable.Wearable

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
    private var lastHeartSentAt = 0L
    private var lastHeartSentSession: String? = null
    private var lastHeartSentBpm: Int? = null
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
        if(key=="snapshot" || key=="companionLiveSessionId") owner?.takeUnless {isCurrent(it)}?.let {endOwned(it)}
    }
    override fun onCreate() {super.onCreate();cache.registerOnSharedPreferenceChangeListener(changes)}
    override fun onBind(intent:Intent?):IBinder=binder
    private fun cachedId():String?=cache.getString("snapshot",null)?.let {
        runCatching {JSONObject(it).getString("id")}.getOrNull()
    }
    private fun isCurrent(id:String)=cachedId()==id || cache.getString("companionLiveSessionId",null)==id
    private fun snapshot()=Snapshot(owner,sensors.freshHeartRateBpm,sensors.energyKcal,sensors.recording,sensors.paused,status ?: sensors.problem)
    private fun publish() {
        observer?.invoke(snapshot())
        publishCompanionHeartRate()
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
    /**
     * Send actual Health Services samples to the phone-owned Comenzar session.
     * This runs in the foreground sensor service even if WearMainActivity is hidden.
     */
    private fun publishCompanionHeartRate() {
        val id = owner ?: return
        if (cache.getString("companionLiveSessionId", null) != id) return
        val bpm = sensors.freshHeartRateBpm?.takeIf { it in 25..250 } ?: return
        val now = System.currentTimeMillis()
        if (lastHeartSentSession == id) {
            val elapsed = now - lastHeartSentAt
            if (elapsed < 3_000L || (lastHeartSentBpm == bpm && elapsed < 5_000L)) return
        }
        lastHeartSentSession = id
        lastHeartSentBpm = bpm
        lastHeartSentAt = now
        val data = JSONObject()
            .put("sessionId", id)
            .put("bpm", bpm)
            .put("capturedAt", now)
            .toString().toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            nodes.forEach { node ->
                Wearable.getMessageClient(this)
                    .sendMessage(node.id, "/repera/live-heart-rate", data)
            }
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
        val companion = cache.getString("companionLiveSessionId",null)==id
        val sportId = intent?.getStringExtra("sportId")
        val sportType = if (companion && sportId == "walking") ExerciseType.WALKING
            else ExerciseType.STRENGTH_TRAINING
        scope.launch {
            val result=runCatching {sensors.start(id,sportType) {token==revision && isCurrent(id)}}
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
        val builder = NotificationCompat.Builder(this,CHANNEL)
            .setSmallIcon(R.drawable.ic_repera_complication)
            .setContentTitle("Repera · Entrenamiento")
            .setContentText(status ?: sensors.problem ?: if(ending) "Terminando sensores" else if(sensors.paused) "Sensores en pausa" else if(sensors.recording) "Registro de sensores activo" else "Conectando con sensores")
            .setOngoing(true).setOnlyAlertOnce(true).setContentIntent(open)
        // La notificación foreground por sí sola NO evita Return to Watch Face.
        // Ongoing Activity mantiene la UI visible durante el entrenamiento, en pausa
        // y durante la recepción de sensores, y ofrece un toque para regresar si
        // el usuario pulsa manualmente la corona. Nunca crearla sin sesión activa.
        if (owner?.let { isCurrent(it) } == true && !sensors.ended && !ending) {
            OngoingActivity.Builder(applicationContext, NOTIFICATION, builder)
                .setStaticIcon(R.drawable.ic_repera_complication)
                .setTouchIntent(open)
                .setTitle("Repera · Entrenamiento")
                .setContentDescription("Volver al entrenamiento en curso de Repera")
                .build()
                .apply(applicationContext)
        }
        return builder.build()
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
        fun startFromVisibleUI(context:Context,id:String,sportId:String?=null) {
            androidx.core.content.ContextCompat.startForegroundService(context,
                Intent(context,WearHealthService::class.java)
                    .putExtra("sessionId",id).putExtra("sportId",sportId))
        }
    }
}
