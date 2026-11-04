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
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import java.time.Instant
import java.util.concurrent.TimeUnit

/**
 * Recordatorios de reservas del atleta. WorkManager es diferido (Doze puede
 * retrasarlo); la hora exacta debe provenir de push/backend cuando exista.
 */
internal object BusinessSessionReminderScheduler {
    private const val PREFS = "repera.booking.reminders"
    private const val IDS = "ids"
    private const val PREFIX = "repera.booking.reminder."
    fun synchronize(
        context: Context,
        accountId: String,
        userId: String,
        snapshot: BusinessCenterStore.Snapshot
    ) {
        val sessions = SessionStore(context)
        val revision = sessions.identityRevision() ?: return
        if (sessions.load()?.uniqueId != accountId) return
        val byId = snapshot.occurrences.associateBy { it.id }
        val now = System.currentTimeMillis()
        val bookedOccurrences = snapshot.bookings
            .filter { it.status == "booked" }.map { it.occurrenceId }.toSet()
        val reserved = snapshot.bookings.asSequence()
            .filter { it.status == "booked" }
            .mapNotNull { booking ->
                val occurrence = byId[booking.occurrenceId] ?: return@mapNotNull null
                if (occurrence.status != "active" ||
                    occurrence.kind !in setOf("class", "appointment")) return@mapNotNull null
                val start = runCatching { Instant.parse(occurrence.startsAt).toEpochMilli() }
                    .getOrNull() ?: return@mapNotNull null
                val notifyAt = start - 3_600_000L
                if (notifyAt - now !in 60_000L..(60L * 86_400_000L)) return@mapNotNull null
                Triple(booking.id, occurrence.title, notifyAt)
            }
            .toList()
        val direct = snapshot.trainingSessions.asSequence()
            .filter { it.status == "scheduled" }
            .filter { it.sourceOccurrenceId == null || it.sourceOccurrenceId !in bookedOccurrences }
            .mapNotNull { session ->
                val minutes = session.scheduledTimeMinutes
                    ?.takeIf { it in 0..1439 } ?: return@mapNotNull null
                val start = runCatching {
                    java.time.LocalDate.parse(session.scheduledDate)
                        .atTime(minutes / 60, minutes % 60)
                        .atZone(java.time.ZoneId.systemDefault())
                        .toInstant().toEpochMilli()
                }.getOrNull() ?: return@mapNotNull null
                val notifyAt = start - 3_600_000L
                if (notifyAt - now !in 60_000L..(60L * 86_400_000L)) return@mapNotNull null
                Triple("training." + session.id, session.title, notifyAt)
            }.toList()
        val desired = (reserved + direct).sortedBy { it.third }.take(40)
        val work = WorkManager.getInstance(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val desiredIds = desired.map { it.first }.toSet()
        val previous = prefs.getStringSet(IDS, emptySet()).orEmpty().toSet()
        (previous - desiredIds).forEach { work.cancelUniqueWork(PREFIX + it) }
        desired.forEach { (id, title, whenMillis) ->
            val request = OneTimeWorkRequestBuilder<BusinessSessionReminderWorker>()
                .setInitialDelay((whenMillis - now).coerceAtLeast(0), TimeUnit.MILLISECONDS)
                .setInputData(workDataOf(
                    "bookingID" to id,
                    "title" to title,
                    "owner" to accountId,
                    "userID" to userId,
                    "revision" to revision
                ))
                .build()
            work.enqueueUniqueWork(PREFIX + id, ExistingWorkPolicy.REPLACE, request)
        }
        prefs.edit().putStringSet(IDS, desiredIds).apply()
    }

    fun cancelAll(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val work = WorkManager.getInstance(context)
        prefs.getStringSet(IDS, emptySet()).orEmpty().toSet().forEach {
            work.cancelUniqueWork(PREFIX + it)
        }
        prefs.edit().remove(IDS).apply()
    }
}

/** Verifica identidad de nuevo en el momento de la notificación. */
class BusinessSessionReminderWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val owner = inputData.getString("owner") ?: return Result.success()
        val userId = inputData.getString("userID") ?: return Result.success()
        val revision = inputData.getString("revision") ?: return Result.success()
        val bookingId = inputData.getString("bookingID") ?: return Result.success()
        val store = SessionStore(applicationContext)
        if (store.identityRevision() != revision ||
            store.load()?.uniqueId != owner || store.load()?.userId != userId) {
            return Result.success()
        }
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) return Result.success()
        val manager = applicationContext.getSystemService(NotificationManager::class.java)
        val channel = "repera.booking.reminders"
        manager.createNotificationChannel(NotificationChannel(
            channel, "Reservas Repera", NotificationManager.IMPORTANCE_DEFAULT
        ))
        val open = PendingIntent.getActivity(
            applicationContext, bookingId.hashCode(),
            Intent(applicationContext, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("repera://workout")
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        manager.notify(bookingId.hashCode(),
            NotificationCompat.Builder(applicationContext, channel)
                .setSmallIcon(R.drawable.ic_timer)
                .setContentTitle(inputData.getString("title") ?: "Tu sesión Repera")
                .setContentText("Tu sesión de Repera comienza en una hora.")
                .setContentIntent(open).setAutoCancel(true).build()
        )
        return Result.success()
    }
}
