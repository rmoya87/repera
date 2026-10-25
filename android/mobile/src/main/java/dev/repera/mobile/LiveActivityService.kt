package dev.repera.mobile

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.*
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import dev.repera.domain.LiveActivityState
import dev.repera.domain.LiveSportHistory

/** Servicio privado de actividad En vivo. Solo arranca desde acción explícita
 * de la UI en primer plano; no arranca tras boot ni restaura GPS por sí solo.
 * Ubicación en pantalla apagada usa FGS location, no permiso background nuevo. */
internal class LiveActivityService : Service() {
    private val handler=Handler(Looper.getMainLooper())
    private var runtime: LiveActivityRuntime?=null
    private var ticking=false
    private val tick=object:Runnable {
        override fun run() {
            val r=runtime ?: return
            if (!ticking) return
            if (SessionStore(this@LiveActivityService).load()?.uniqueId != r.accountID) {
                r.stopForAccountChange();stopSelf();return
            }
            if (r.state.phase==LiveActivityState.Phase.IDLE || r.state.phase==LiveActivityState.Phase.REVIEW) {
                stopSelf();return
            }
            r.checkpoint();r.publish()
            getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID,notification(r))
            handler.postDelayed(this,1000)
        }
    }
    override fun onBind(intent:Intent?):IBinder?=null
    override fun onStartCommand(intent:Intent?,flags:Int,startId:Int):Int {
        val account=intent?.getStringExtra("accountID").orEmpty()
        if (account.isBlank() || SessionStore(this).load()?.uniqueId!=account) { stopSelf();return START_NOT_STICKY }
        val r=LiveActivityRuntime.forAccount(this,account);runtime=r
        val phase=r.state.phase
        if (phase==LiveActivityState.Phase.IDLE || phase==LiveActivityState.Phase.REVIEW) {stopSelf();return START_NOT_STICKY}
        val hasLocation=ContextCompat.checkSelfPermission(this,Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this,Manifest.permission.ACCESS_COARSE_LOCATION)==PackageManager.PERMISSION_GRANTED
        val type=if(r.state.sport.usesGPS && hasLocation) ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            else if(Build.VERSION.SDK_INT>=34) ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0
        try { startForeground(NOTIFICATION_ID,notification(r),type) }
        catch (_: SecurityException) { r.pause();stopSelf();return START_NOT_STICKY }
        when(intent?.action) {
            ACTION_PAUSE->r.pause()
            ACTION_RESUME->r.resume()
            ACTION_FINISH->r.finish()
        }
        if (!ticking) {ticking=true;handler.post(tick)}
        return START_NOT_STICKY
    }
    override fun onDestroy() {
        ticking=false;handler.removeCallbacks(tick)
        runtime?.let { if(it.state.phase==LiveActivityState.Phase.RECORDING) it.pause() else it.checkpoint(true) }
        stopForeground(STOP_FOREGROUND_REMOVE);super.onDestroy()
    }
    private fun notification(r:LiveActivityRuntime):Notification {
        getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL,"Actividad en vivo",NotificationManager.IMPORTANCE_LOW))
        val open=PendingIntent.getActivity(this,601,Intent(this,MainActivity::class.java).setData(android.net.Uri.parse("repera://live"))
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val paused=r.state.phase==LiveActivityState.Phase.PAUSED
        val text=buildList {
            add(LiveSportHistory.formatDuration(r.state.durationSeconds(System.currentTimeMillis())))
            if(r.state.sport.usesGPS) add("%.2f km".format(r.state.distanceMeters/1000))
            if(paused) add("En pausa")
        }.joinToString(" · ")
        fun action(action:String,code:Int)=PendingIntent.getService(this,code,
            Intent(this,LiveActivityService::class.java).setAction(action).putExtra("accountID",r.accountID),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        return NotificationCompat.Builder(this,CHANNEL).setSmallIcon(R.drawable.ic_timer)
            .setContentTitle(r.state.sport.title).setContentText(text).setOngoing(true).setOnlyAlertOnce(true)
            .setContentIntent(open)
            .addAction(0,if(paused) "Reanudar" else "Pausar",action(if(paused) ACTION_RESUME else ACTION_PAUSE,602))
            .addAction(0,"Finalizar",action(ACTION_FINISH,603)).build()
    }
    companion object {
        private const val CHANNEL="repera.live.activity"
        private const val NOTIFICATION_ID=4203
        private const val ACTION_PAUSE="dev.repera.live.PAUSE"
        private const val ACTION_RESUME="dev.repera.live.RESUME"
        private const val ACTION_FINISH="dev.repera.live.FINISH"
        fun startFromVisibleUI(context:Context,accountID:String) {
            ContextCompat.startForegroundService(context,Intent(context,LiveActivityService::class.java).putExtra("accountID",accountID))
        }
        fun stop(context:Context) {context.stopService(Intent(context,LiveActivityService::class.java))}
    }
}
