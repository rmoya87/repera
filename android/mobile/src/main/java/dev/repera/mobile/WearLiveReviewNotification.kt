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
import java.util.UUID

/**
 * A Wear-triggered Comenzar finish stops the phone recording and enters REVIEW.
 * This notification opens that pending review; it never saves or discards it.
 */
internal object WearLiveReviewNotification {
    private const val CHANNEL = "repera.wear.live-review"

    fun show(context: Context, account: String, sessionID: String) {
        if (runCatching { UUID.fromString(sessionID) }.isFailure) return
        val sessions = SessionStore(context)
        if (sessions.load()?.uniqueId != account) return
        val revision = sessions.identityRevision() ?: return
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED) return

        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(
            CHANNEL, "Actividades pendientes de revisión", NotificationManager.IMPORTANCE_DEFAULT
        ))
        val open = Intent(context, MainActivity::class.java)
            .setData(Uri.parse("repera://review-live/" + Uri.encode(sessionID)))
            .putExtra("liveReviewOwner", account)
            .putExtra("liveReviewRevision", revision)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val requestCode = sessionID.hashCode() and Int.MAX_VALUE
        val click = PendingIntent.getActivity(context, requestCode, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle("Entrenamiento listo para revisar")
            .setContentText("Abre Comenzar para guardar, editar o descartar la actividad.")
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(click)
            .build()
        if (sessions.load()?.uniqueId == account && sessions.identityRevision() == revision) {
            manager.notify(requestCode, notification)
        }
    }
}
