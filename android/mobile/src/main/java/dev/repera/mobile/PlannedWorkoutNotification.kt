package dev.repera.mobile

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

/** Platform chronometer needs no polling service. Refreshed after durable writes
 * and hydration; never starts sensors, requests permission or publishes GPS/HR. */
internal object PlannedWorkoutNotification {
    private const val CHANNEL="repera.planned.status"
    private const val ID=4205
    fun refresh(context:Context,owner:String,state:JSONObject) {
        val sessions=SessionStore(context)
        if(sessions.load()?.uniqueId!=owner) return
        val revision=sessions.identityRevision() ?: return
        val manager=context.getSystemService(NotificationManager::class.java)
        val status=PlannedWorkoutStatus.fromState(state)
        fun snapshotStillCurrent():Boolean = runCatching {
            val current=LocalSnapshotStore(context,owner).read()?.let {PlannedWorkoutStatus.fromState(JSONObject(String(it,Charsets.UTF_8)))}
            current==status && sessions.load()?.uniqueId==owner && sessions.identityRevision()==revision
        }.getOrDefault(false)
        if(status==null) {if(snapshotStillCurrent()) manager.cancel(ID);return}
        if(Build.VERSION.SDK_INT>=33 && ContextCompat.checkSelfPermission(context,Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED) return
        manager.createNotificationChannel(NotificationChannel(CHANNEL,"Entrenamiento activo",NotificationManager.IMPORTANCE_LOW))
        val notification=build(context,owner,revision,status)
        // Recheck the durable login before publishing a snapshot prepared for it.
        if(snapshotStillCurrent()) manager.notify(ID,notification)
    }
    internal fun build(context:Context,owner:String,revision:String,status:PlannedWorkoutStatus):android.app.Notification {
        val open=PendingIntent.getActivity(context,605,Intent(context,MainActivity::class.java)
            .setData(Uri.parse("repera://workout").buildUpon().appendQueryParameter("session",status.sessionId).appendQueryParameter("revision",revision).build())
            .putExtra("plannedOwner",owner).putExtra("plannedRevision",revision).putExtra("plannedSession",status.sessionId)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        return NotificationCompat.Builder(context,CHANNEL).setSmallIcon(R.drawable.ic_timer)
            .setContentTitle(status.title).setContentText(status.exercise)
            .setSubText("Ejercicio ${status.exerciseProgress} · ${status.completedSets} series")
            .setWhen(status.startedEpochMillis).setUsesChronometer(true).setShowWhen(true)
            .setOngoing(true).setOnlyAlertOnce(true).setContentIntent(open).build()
    }
    fun cancel(context:Context) {context.getSystemService(NotificationManager::class.java).cancel(ID)}
}
