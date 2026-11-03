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
import java.util.UUID

/** A Wear OS finish is already persisted before this optional editor prompt. */
internal object WearWorkoutCompletionNotification {
    private const val CHANNEL = "repera.wear.finished"
    private const val PREFS = "repera.wear.finished.notifications"

    fun show(context: Context, account: String, workoutID: String) {
        if (runCatching { UUID.fromString(workoutID) }.isFailure) return
        val sessions = SessionStore(context)
        val identity = sessions.load() ?: return
        if (identity.uniqueId != account) return
        val revision = sessions.identityRevision() ?: return
        val bytes = LocalSnapshotStore(context, account).read() ?: return
        val state = runCatching { JSONObject(String(bytes, Charsets.UTF_8)) }.getOrNull() ?: return
        val workouts = state.optJSONArray("workouts") ?: return
        val finished = (0 until workouts.length()).any { index ->
            val row = workouts.optJSONObject(index)
            row != null && row.optString("id") == workoutID &&
                row.optString("phase") == "finished" &&
                row.optBoolean("awaitingResultEntry")
        }
        if (!finished) return
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) return

        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val key = account + ":" + workoutID
        if (prefs.getBoolean(key, false)) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(
            CHANNEL, "Entrenamientos terminados", NotificationManager.IMPORTANCE_DEFAULT
        ))
        val open = Intent(context, MainActivity::class.java)
            .setData(Uri.parse("repera://complete-workout/" + Uri.encode(workoutID)))
            .putExtra("completedOwner", account)
            .putExtra("completedRevision", revision)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val requestCode = workoutID.hashCode() and Int.MAX_VALUE
        val click = PendingIntent.getActivity(context, requestCode, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle("¿Quieres completar tu entrenamiento?")
            .setContentText("Toca para revisar y registrar las repeticiones y los pesos.")
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(click)
            .build()
        if (sessions.load()?.uniqueId != account || sessions.identityRevision() != revision) return
        manager.notify(requestCode, notification)
        prefs.edit().putBoolean(key, true).apply()
    }
}
