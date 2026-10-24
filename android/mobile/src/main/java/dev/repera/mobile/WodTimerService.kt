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
import androidx.core.app.NotificationCompat
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import dev.repera.domain.WodFormat

/**
 * Foreground service dueño del reloj WOD visible y de los avisos de fase:
 * mantiene la notificación persistente con el tiempo y dispara los avisos de
 * descanso aunque la pantalla esté apagada o la app en segundo plano. Lee el
 * cronómetro monótono persistido (WodTimerStore), nunca inventa tiempo.
 */
internal class WodTimerService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var ticking = false
    private var lastRestLabel: String? = null

    private val tick = object : Runnable {
        override fun run() {
            if (!ticking) return
            val specData = lastSpec
            val state = lastStoreKey?.let { (sessionId, index, user) ->
                WodTimerStore(this@WodTimerService, user).read(sessionId, index)
            }
            if (specData == null || state == null || !state.running) {
                stopSelf()
                return
            }
            val face = WodClock.face(specData.spec, state.elapsedSeconds)
            updateNotification(specData.title, face.primarySeconds, face.label)
            val restLabel = face.label?.takeIf { it.startsWith("Descanso") }
            if (restLabel != null && restLabel != lastRestLabel) {
                RestNotifier.notifyRest(this@WodTimerService, restLabel, face.primarySeconds)
            } else if (restLabel == null && lastRestLabel != null) {
                RestNotifier.cancel(this@WodTimerService)
            }
            lastRestLabel = restLabel
            handler.postDelayed(this, 500L)
        }
    }

    private data class ServiceSpec(val spec: WodClockSpec, val title: String)
    private var lastSpec: ServiceSpec? = null
    private var lastStoreKey: Triple<String, Int, String>? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action != ACTION_START) {
            stopSelf()
            return START_NOT_STICKY
        }
        val format = WodFormat.fromWire(intent.getStringExtra(EXTRA_FORMAT).orEmpty())
        val sessionId = intent.getStringExtra(EXTRA_SESSION_ID).orEmpty()
        val user = intent.getStringExtra(EXTRA_GOOGLE_USER).orEmpty()
        if (format == null || sessionId.isBlank() || user.isBlank()) {
            stopSelf()
            return START_NOT_STICKY
        }
        val spec = WodClockSpec(
            format = format,
            blockTimeCapMinutes = intent.getIntExtra(EXTRA_CAP, -1).takeIf { it >= 0 },
            intervalSeconds = intent.getIntExtra(EXTRA_INTERVAL, -1).takeIf { it >= 0 },
            rounds = intent.getIntExtra(EXTRA_ROUNDS, -1).takeIf { it >= 0 },
            workSeconds = intent.getIntExtra(EXTRA_WORK, -1).takeIf { it >= 0 },
            restSeconds = intent.getIntExtra(EXTRA_REST, -1).takeIf { it >= 0 },
            restBetweenRoundsSeconds = intent.getIntExtra(EXTRA_REST_ROUNDS, -1).takeIf { it >= 0 },
            stations = intent.getIntExtra(EXTRA_STATIONS, 1).coerceAtLeast(1)
        )
        lastSpec = ServiceSpec(spec,
            intent.getStringExtra(EXTRA_TITLE).orEmpty().ifBlank { "Entrenamiento" })
        lastStoreKey = Triple(sessionId, intent.getIntExtra(EXTRA_BLOCK_INDEX, 0), user)
        startForegroundWithNotification(lastSpec!!.title, 0, null)
        if (!ticking) {
            ticking = true
            handler.post(tick)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        ticking = false
        handler.removeCallbacks(tick)
        RestNotifier.cancel(this)
        super.onDestroy()
    }

    private fun startForegroundWithNotification(title: String, seconds: Int, label: String?) {
        val notification = buildNotification(title, seconds, label)
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateNotification(title: String, seconds: Int, label: String?) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        runCatching { manager.notify(NOTIFICATION_ID, buildNotification(title, seconds, label)) }
    }

    private fun buildNotification(title: String, seconds: Int, label: String?): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Cronómetros", NotificationManager.IMPORTANCE_LOW))
        }
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle(title)
            .setContentText("%d:%02d".format(seconds / 60, seconds % 60) +
                (label?.let { " · $it" } ?: ""))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(open)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "repera.timers"
        private const val NOTIFICATION_ID = 4202
        const val ACTION_START = "dev.repera.mobile.action.WOD_TIMER_START"
        private const val EXTRA_SESSION_ID = "sessionId"
        private const val EXTRA_BLOCK_INDEX = "blockIndex"
        private const val EXTRA_GOOGLE_USER = "googleUser"
        private const val EXTRA_FORMAT = "format"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_CAP = "cap"
        private const val EXTRA_INTERVAL = "interval"
        private const val EXTRA_ROUNDS = "rounds"
        private const val EXTRA_WORK = "work"
        private const val EXTRA_REST = "rest"
        private const val EXTRA_REST_ROUNDS = "restRounds"
        private const val EXTRA_STATIONS = "stations"

        /**
         * Mantiene el servicio acorde al estado real: arranca solo con un WOD
         * activo y el cronómetro en marcha; en cualquier otro caso lo detiene.
         */
        fun sync(context: Context, active: ActiveWorkout?, timer: WodTimerState?,
                 googleUser: String?) {
            val wod = active?.wod
            if (wod == null || timer?.running != true || googleUser == null) {
                context.stopService(Intent(context, WodTimerService::class.java))
                return
            }
            val intent = Intent(context, WodTimerService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_SESSION_ID, active.id)
                .putExtra(EXTRA_BLOCK_INDEX, active.index)
                .putExtra(EXTRA_GOOGLE_USER, googleUser)
                .putExtra(EXTRA_FORMAT, wod.format)
                .putExtra(EXTRA_TITLE, active.title)
                .putExtra(EXTRA_CAP, wod.timeCapMinutes ?: -1)
                .putExtra(EXTRA_INTERVAL, wod.intervalSeconds ?: -1)
                .putExtra(EXTRA_ROUNDS, wod.rounds ?: -1)
                .putExtra(EXTRA_WORK, wod.workSeconds ?: -1)
                .putExtra(EXTRA_REST, wod.restSeconds ?: -1)
                .putExtra(EXTRA_REST_ROUNDS, wod.restBetweenRoundsSeconds ?: -1)
                .putExtra(EXTRA_STATIONS, wod.movements.count { !it.isRest }.coerceAtLeast(1))
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent)
            else context.startService(intent)
        }
    }
}
