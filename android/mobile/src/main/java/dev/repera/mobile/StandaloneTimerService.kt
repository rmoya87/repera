package dev.repera.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.NotificationCompat

/**
 * Foreground service del temporizador independiente (I-70 / I-140):
 * notificación ongoing con el tiempo restante/transcurrido mientras corre.
 */
internal class StandaloneTimerService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var ticking = false
    private var mode: StandaloneTimerMode = StandaloneTimerMode.DOWN
    private var endElapsedRealtime = 0L
    private var startElapsedRealtime = 0L
    private var durationSeconds = 0
    private var title = "Temporizador"

    private val tick = object : Runnable {
        override fun run() {
            if (!ticking) return
            val now = SystemClock.elapsedRealtime()
            val seconds = when (mode) {
                StandaloneTimerMode.UP ->
                    ((now - startElapsedRealtime) / 1000L).toInt().coerceAtLeast(0)
                StandaloneTimerMode.DOWN, StandaloneTimerMode.INTERVALS ->
                    ((endElapsedRealtime - now) / 1000L).toInt().coerceAtLeast(0)
            }
            updateNotification(seconds)
            val finished = when (mode) {
                StandaloneTimerMode.UP -> seconds >= durationSeconds
                StandaloneTimerMode.DOWN, StandaloneTimerMode.INTERVALS -> seconds <= 0
            }
            if (finished) {
                notifyFinished()
                stopSelf()
                return
            }
            handler.postDelayed(this, 500L)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                mode = StandaloneTimerMode.fromWire(intent.getStringExtra(EXTRA_MODE).orEmpty())
                durationSeconds = intent.getIntExtra(EXTRA_DURATION, 0).coerceAtLeast(1)
                title = intent.getStringExtra(EXTRA_TITLE).orEmpty().ifBlank { "Temporizador" }
                val now = SystemClock.elapsedRealtime()
                startElapsedRealtime = now
                endElapsedRealtime = now + durationSeconds * 1000L
                startForegroundWithNotification(
                    when (mode) {
                        StandaloneTimerMode.UP -> 0
                        else -> durationSeconds
                    }
                )
                if (!ticking) {
                    ticking = true
                    handler.post(tick)
                }
                return START_STICKY
            }
            else -> {
                stopSelf()
                return START_NOT_STICKY
            }
        }
    }

    override fun onDestroy() {
        ticking = false
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    private fun startForegroundWithNotification(seconds: Int) {
        val notification = buildNotification(seconds, finished = false)
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateNotification(seconds: Int) {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        runCatching { manager.notify(NOTIFICATION_ID, buildNotification(seconds, finished = false)) }
    }

    private fun notifyFinished() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_DONE, "Temporizador finalizado", NotificationManager.IMPORTANCE_HIGH)
            )
        }
        val open = PendingIntent.getActivity(
            this, 1,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val done = NotificationCompat.Builder(this, CHANNEL_DONE)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle("Temporizador finalizado")
            .setContentText(title)
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()
        runCatching { manager.notify(NOTIFICATION_DONE_ID, done) }
    }

    private fun buildNotification(seconds: Int, finished: Boolean): Notification {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Cronómetros", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val label = when (mode) {
            StandaloneTimerMode.UP -> "Cronómetro"
            StandaloneTimerMode.DOWN -> "Cuenta atrás"
            StandaloneTimerMode.INTERVALS -> "Intervalos"
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle(if (finished) "Temporizador finalizado" else title)
            .setContentText("$label · %d:%02d".format(seconds / 60, seconds % 60))
            .setOngoing(!finished)
            .setOnlyAlertOnce(true)
            .setContentIntent(open)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "repera.timers"
        private const val CHANNEL_DONE = "repera.timer.done"
        private const val NOTIFICATION_ID = 4205
        private const val NOTIFICATION_DONE_ID = 4206
        const val ACTION_START = "dev.repera.mobile.action.STANDALONE_TIMER_START"
        const val ACTION_STOP = "dev.repera.mobile.action.STANDALONE_TIMER_STOP"
        private const val EXTRA_MODE = "mode"
        private const val EXTRA_DURATION = "duration"
        private const val EXTRA_TITLE = "title"

        fun sync(context: Context, running: Boolean, mode: StandaloneTimerMode, secondsLeftOrElapsed: Int, title: String) {
            if (!running) {
                context.stopService(Intent(context, StandaloneTimerService::class.java).setAction(ACTION_STOP))
                return
            }
            val intent = Intent(context, StandaloneTimerService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_MODE, mode.wire)
                .putExtra(EXTRA_DURATION, secondsLeftOrElapsed.coerceAtLeast(1))
                .putExtra(EXTRA_TITLE, title)
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent)
            else context.startService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, StandaloneTimerService::class.java).setAction(ACTION_STOP))
        }
    }
}
