package dev.repera.mobile

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Posts the rest-phase cue for the WOD clock. WodTimerService owns delivery
 * with the screen off; composed clock screens use the same entry point while
 * the service is not running (timer paused or app without an active WOD).
 */
internal object RestNotifier {
    private const val CHANNEL_ID = "repera.timers"
    private const val NOTIFICATION_ID = 4201

    fun notifyRest(context: Context, label: String, remainingSeconds: Int,sound:Boolean=true,haptic:Boolean=true) {
        if(haptic) vibrate(context)
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel=CHANNEL_ID+if(sound) ".sound" else ".silent"
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(channel, "Cronómetros", NotificationManager.IMPORTANCE_HIGH).apply { enableVibration(false);if(!sound) setSound(null,null) }
            )
        }
        val text = "%d:%02d restantes".format(remainingSeconds / 60, remainingSeconds % 60)
        val notification = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle(label)
            .setContentText(text)
            .setOnlyAlertOnce(true)
            .setSilent(!sound)
            .setAutoCancel(true)
            .build()
        runCatching { manager.notify(NOTIFICATION_ID, notification) }
    }

    fun cancel(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        runCatching { manager.cancel(NOTIFICATION_ID) }
    }

    private fun vibrate(context: Context) {
        runCatching {
            if (Build.VERSION.SDK_INT >= 31) {
                val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.defaultVibrator.vibrate(
                    VibrationEffect.createOneShot(350, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                (context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator)
                    .vibrate(VibrationEffect.createOneShot(350, VibrationEffect.DEFAULT_AMPLITUDE))
            }
        }
    }
}
