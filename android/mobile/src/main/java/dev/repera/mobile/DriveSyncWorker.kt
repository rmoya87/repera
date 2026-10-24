package dev.repera.mobile

import android.accounts.Account
import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.Scope
import com.google.android.gms.tasks.Tasks
import java.util.concurrent.TimeUnit

/**
 * Background Drive synchronization.
 *
 * Uses the same short-lived AuthorizationClient token as the in-app flow:
 * when Google can resolve it silently (consent already granted), the worker
 * synchronizes; when it requires user interaction it records the pending state
 * and leaves the next run or the next app open to finish. It never invents
 * credentials and never blocks waiting for UI.
 */
class DriveSyncWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        val stored = SessionStore(applicationContext).load() ?: return Result.success()
        val builder = AuthorizationRequest.builder()
            .setRequestedScopes(listOf(Scope(DRIVE_APPDATA_SCOPE)))
        if (stored.email.isNotBlank()) {
            builder.setAccount(Account(stored.email, "com.google"))
        }
        val result = runCatching {
            Tasks.await(
                Identity.getAuthorizationClient(applicationContext).authorize(builder.build()),
                30, TimeUnit.SECONDS
            )
        }.getOrElse { return if (runAttemptCount < MAX_ATTEMPTS) Result.retry() else Result.success() }

        if (result.hasResolution()) {
            SyncStatusStore(applicationContext).markConsentRequired()
            return Result.success()
        }
        val token = result.accessToken
        if (token.isNullOrBlank()) {
            SyncStatusStore(applicationContext).markConsentRequired()
            return Result.success()
        }
        return runCatching {
            val store = LocalSnapshotStore(applicationContext, stored.uniqueId)
            val outcome = DriveSnapshotService(token, store).synchronize()
            SyncStatusStore(applicationContext).markSynced(outcome)
            Result.success()
        }.getOrElse {
            if (runAttemptCount < MAX_ATTEMPTS) Result.retry() else Result.success()
        }
    }

    companion object {
        private const val DRIVE_APPDATA_SCOPE = "https://www.googleapis.com/auth/drive.appdata"
        private const val MAX_ATTEMPTS = 3
        private const val PERIODIC_NAME = "repera_drive_sync"
        private const val NOW_NAME = "repera_drive_sync_now"

        /** Backstop sync while the athlete keeps the app closed. */
        fun schedulePeriodic(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            val request = PeriodicWorkRequestBuilder<DriveSyncWorker>(6, TimeUnit.HOURS)
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 15, TimeUnit.MINUTES)
                .build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(PERIODIC_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }

        /** Prompt sync after local writes, so a second device converges quickly. */
        fun syncNow(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            val request = OneTimeWorkRequestBuilder<DriveSyncWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
                .build()
            WorkManager.getInstance(context)
                .enqueueUniqueWork(NOW_NAME, ExistingWorkPolicy.REPLACE, request)
        }
    }
}
