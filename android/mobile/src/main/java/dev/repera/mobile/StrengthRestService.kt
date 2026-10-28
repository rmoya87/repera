package dev.repera.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Cuenta atrás del descanso entre series como notificación persistente:
 * equivalente Android a la Rest Live Activity de iOS (RestLiveActivityWidget).
 * Usa chronometer nativo (como PlannedWorkoutNotification) + acción «Saltar».
 */
internal class StrengthRestService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var remaining = 0
    private var endsAtElapsedRealtime = 0L
    private var exerciseName = ""
    private var running = false
    private var soundEnabled = true
    private var hapticEnabled = true

    private val tick = object : Runnable {
        override fun run() {
            if (!running) return
            remaining = ((endsAtElapsedRealtime - SystemClock.elapsedRealtime()) / 1000L)
                .toInt().coerceAtLeast(0)
            if (remaining <= 0) {
                postFinished()
                stopSelf()
                return
            }
            postCountdown()
            handler.postDelayed(this, 1000L)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CANCEL, ACTION_SKIP -> {
                running = false
                handler.removeCallbacks(tick)
                cancelNotification()
                RestNotifier.cancel(this)
                stopSelf()
            }
            ACTION_START -> {
                val seconds = intent.getIntExtra(EXTRA_SECONDS, 0)
                val name = intent.getStringExtra(EXTRA_NAME).orEmpty()
                if (seconds <= 0) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                soundEnabled = intent.getBooleanExtra("sound", true)
                hapticEnabled = intent.getBooleanExtra("haptic", true)
                exerciseName = name
                remaining = seconds
                endsAtElapsedRealtime = SystemClock.elapsedRealtime() + seconds * 1000L
                running = true
                handler.removeCallbacks(tick)
                postCountdown()
                handler.postDelayed(tick, 1000L)
            }
            else -> stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    private fun manager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun canPost(): Boolean =
        Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(
            this, android.Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED

    private fun baseBuilder(): NotificationCompat.Builder {
        if (Build.VERSION.SDK_INT >= 26) {
            manager().createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID, "Cronómetros",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
        }
        val openApp = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val skip = PendingIntent.getService(
            this, 1,
            Intent(this, StrengthRestService::class.java).setAction(ACTION_SKIP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle("Descanso")
            .setContentIntent(openApp)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .addAction(0, "Saltar", skip)
    }

    private fun postCountdown() {
        if (!canPost()) return
        val text = if (exerciseName.isBlank()) "Restantes"
        else "$exerciseName · restantes"
        // Chronometer cuenta hacia arriba desde (now - remaining); usamos
        // setChronometerCountDown cuando está disponible (API 24+).
        val whenMillis = System.currentTimeMillis() + remaining * 1000L
        val builder = baseBuilder()
            .setContentText(text)
            .setWhen(whenMillis)
            .setShowWhen(true)
            .setUsesChronometer(true)
        if (Build.VERSION.SDK_INT >= 24) {
            builder.setChronometerCountDown(true)
        }
        runCatching { manager().notify(NOTIFICATION_ID, builder.build()) }
    }

    private fun postFinished() {
        if (!canPost()) return
        val notification: Notification = baseBuilder()
            .setContentText("Descanso terminado · a por la siguiente serie")
            .setOngoing(false)
            .setAutoCancel(true)
            .setUsesChronometer(false)
            .build()
        runCatching { manager().notify(NOTIFICATION_ID, notification) }
        RestNotifier.notifyRest(this, "Descanso terminado", 0, soundEnabled, hapticEnabled)
    }

    private fun cancelNotification() {
        runCatching { manager().cancel(NOTIFICATION_ID) }
    }

    companion object {
        private const val CHANNEL_ID = "repera.timers"
        private const val NOTIFICATION_ID = 4202
        private const val ACTION_START = "dev.repera.mobile.rest.START"
        private const val ACTION_CANCEL = "dev.repera.mobile.rest.CANCEL"
        private const val ACTION_SKIP = "dev.repera.mobile.rest.SKIP"
        private const val EXTRA_SECONDS = "seconds"
        private const val EXTRA_NAME = "name"

        fun start(
            context: Context,
            exerciseName: String,
            seconds: Int,
            sound: Boolean = true,
            haptic: Boolean = true
        ) {
            val intent = Intent(context, StrengthRestService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_SECONDS, seconds)
                .putExtra(EXTRA_NAME, exerciseName)
                .putExtra("sound", sound)
                .putExtra("haptic", haptic)
            runCatching { context.startService(intent) }
        }

        fun cancel(context: Context) {
            val intent = Intent(context, StrengthRestService::class.java)
                .setAction(ACTION_CANCEL)
            runCatching { context.startService(intent) }
        }
    }
}
