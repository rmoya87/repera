package dev.repera.mobile

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Coalesced updates from local-first persistence. WorkManager survives process
 * suspension; each refresh reads only the currently authenticated account.
 * No health data, GPS or exercise sensors are requested from the worker.
 */
internal class ReperaWidgetRefreshWorker(
    appContext: Context,
    parameters: WorkerParameters
) : CoroutineWorker(appContext, parameters) {
    override suspend fun doWork(): Result = runCatching {
        ReperaHomeWidget().updateAll(applicationContext)
        Result.success()
    }.getOrElse { Result.retry() }
}

internal object ReperaWidgetRefresh {
    private const val UNIQUE_WORK = "repera.homeWidget.refresh"

    fun enqueue(context: Context) {
        val app = context.applicationContext
        // Avoid a WorkManager job when nobody has installed the widget.
        val ids = AppWidgetManager.getInstance(app)
            .getAppWidgetIds(ComponentName(app, ReperaHomeWidgetReceiver::class.java))
        if (ids.isEmpty()) return
        val request = OneTimeWorkRequestBuilder<ReperaWidgetRefreshWorker>()
            .setInitialDelay(5, TimeUnit.SECONDS)
            .build()
        WorkManager.getInstance(app).enqueueUniqueWork(
            UNIQUE_WORK, ExistingWorkPolicy.KEEP, request
        )
    }
}
