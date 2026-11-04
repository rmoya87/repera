package dev.repera.mobile

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
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
import java.time.OffsetDateTime
import java.util.concurrent.TimeUnit

/**
 * Best-effort offline fallback until server cron + FCM/APNs delivery is active.
 * WorkManager may defer under battery restrictions; never promise exact alarms.
 * A workout never starts in a worker, and all reminders are account-scoped.
 */
internal object ClassBookingReminders {
    private const val TAG = "repera.booking.reminder"
    private const val PREFS = "repera.booking.reminders"
    private const val CHANNEL = "repera.booking.status"

    fun clear(context: Context) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().clear().commit()
        WorkManager.getInstance(context.applicationContext).cancelAllWorkByTag(TAG)
    }

    fun reconcile(
        context: Context,
        owner: String,
        userId: String,
        snapshot: BusinessCenterStore.Snapshot
    ) {
        val app = context.applicationContext
        val current = SessionStore(app).load()
        if (current?.uniqueId != owner || current.userId != userId) return
        val now = System.currentTimeMillis()
        val byID = snapshot.occurrences.associateBy { it.id }
        val upcoming = snapshot.bookings.asSequence().filter { it.status == "booked" }
            .mapNotNull { booking ->
                val occurrence = byID[booking.occurrenceId] ?: return@mapNotNull null
                if (occurrence.status != "active") return@mapNotNull null
                val start = runCatching { Instant.parse(occurrence.startsAt) }.getOrNull()
                    ?: runCatching { OffsetDateTime.parse(occurrence.startsAt).toInstant() }.getOrNull()
                    ?: return@mapNotNull null
                val fireAt = start.toEpochMilli() - 3_600_000L
                if (fireAt <= now + 10_000L || fireAt >= now + 30L * 86_400_000L)
                    return@mapNotNull null
                booking.id to fireAt
            }.sortedBy { it.second }.take(30).toList()

        val ids = upcoming.map { it.first }.toSet()
        val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.edit().putString("owner", owner).putString("user", userId)
                .putStringSet("bookings", ids).commit()) return

        // Runs from the existing IO dispatcher after a signed-in refresh.
        // Await cancellation to avoid a refresh cancelling its own new work.
        val wm = WorkManager.getInstance(app)
        runCatching { wm.cancelAllWorkByTag(TAG).result.get() }
        // Check again after blocking cancellation: the user may have signed out.
        val session = SessionStore(app).load()
        if (session?.uniqueId != owner || session.userId != userId ||
            prefs.getString("owner", null) != owner) return
        for ((bookingId, fireAt) in upcoming) {
            val request = OneTimeWorkRequestBuilder<ClassBookingReminderWorker>()
                .setInitialDelay((fireAt - System.currentTimeMillis()).coerceAtLeast(1_000L), TimeUnit.MILLISECONDS)
                .addTag(TAG)
                .setInputData(workDataOf(
                    "owner" to owner, "user" to userId, "bookingId" to bookingId
                )).build()
            wm.enqueueUniqueWork("$TAG.$userId.$bookingId", ExistingWorkPolicy.REPLACE, request)
        }
    }

    fun postIfStillBooked(context: Context, owner: String, userId: String, bookingId: String) {
        val app = context.applicationContext
        val session = SessionStore(app).load()
        if (session?.uniqueId != owner || session.userId != userId) return
        val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getString("owner", null) != owner ||
            prefs.getString("user", null) != userId ||
            bookingId !in prefs.getStringSet("bookings", emptySet()).orEmpty()) return
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(app, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED) return

        val manager = app.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(NotificationChannel(
            CHANNEL, "Reservas de Repera", NotificationManager.IMPORTANCE_DEFAULT
        ))
        val notification = NotificationCompat.Builder(app, CHANNEL)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle("Tu sesión de Repera comienza en 1 hora")
            .setContentText("Consulta tu reserva en Repera.")
            .setAutoCancel(true).build()
        manager.notify(bookingId.hashCode(), notification)
    }
}

internal class ClassBookingReminderWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val owner = inputData.getString("owner") ?: return Result.success()
        val user = inputData.getString("user") ?: return Result.success()
        val bookingId = inputData.getString("bookingId") ?: return Result.success()
        runCatching {
            ClassBookingReminders.postIfStillBooked(applicationContext, owner, user, bookingId)
        }
        return Result.success()
    }
}
