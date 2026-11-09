package dev.repera.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationCompat
import dev.repera.domain.LiveSport
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Lock-screen-only mirror for a workout that Wear OS owns.
 * No phone Health Connect writer, GPS tracker or foreground exercise is started.
 * Transport packets must match the encrypted active account and stay ordered
 * through process death. Finished UUIDs cannot be resurrected by late messages.
 */
internal object WearOwnedLiveMirror {
    private const val PREFS = "repera.wear.owned.live.v1"
    private const val CHANNEL = "repera.live.activity"
    private const val NOTIFICATION_ID = 4207

    @Synchronized
    fun accept(context: Context, payload: JSONObject): Boolean {
        val sessionStore = SessionStore(context)
        val account = sessionStore.load() ?: return false
        val revision = sessionStore.identityRevision() ?: return false
        val id = payload.optString("sessionId")
        if (runCatching { UUID.fromString(id) }.isFailure ||
            payload.optString("ownerScope") != account.uniqueId) return false
        val phase = payload.optString("phase")
        if (phase !in setOf("recording", "paused", "finished")) return false
        val captured = payload.optLong("capturedAtMillis", 0L)
        val now = System.currentTimeMillis()
        val age = now - captured
        if (age !in -5_000L..(if (phase == "finished") 3_600_000L else 90_000L)) {
            return false
        }
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getString("owner", null) != account.uniqueId ||
            prefs.getString("revision", null) != revision) {
            prefs.edit().clear().putString("owner", account.uniqueId)
                .putString("revision", revision).commit()
            cancelNotification(context)
        }
        val closed = closedIds(prefs.getString("closed", null))
        if (id in closed && phase != "finished") return false

        val previousID = prefs.getString("sessionId", null)
        val previousAt = prefs.getLong("captured", 0L)
        if (phase == "finished") {
            markClosed(prefs, closed, id)
            if (previousID == id) {
                prefs.edit().remove("state").remove("sessionId")
                    .putLong("captured", maxOf(previousAt, captured)).commit()
                cancelNotification(context)
            }
            return true
        }
        if (id in closed || captured <= previousAt) return false
        if (LiveSport.byId(payload.optString("sportId")) == null) return false

        // Preserve the phone's own recording and foreground notification.
        // The watch remains the Health Services writer of this unrelated UUID.
        val phone = LiveActivityRuntime.forAccount(context, account.uniqueId)
        if (phone.state.phase in setOf(
                dev.repera.domain.LiveActivityState.Phase.RECORDING,
                dev.repera.domain.LiveActivityState.Phase.PAUSED
            )) return false

        val saved = prefs.edit()
            .putString("sessionId", id)
            .putLong("captured", captured)
            .putString("state", payload.toString())
            .commit()
        if (saved) showNotification(context, payload)
        return saved
    }

    @Synchronized
    fun closeSaved(context: Context, sessionId: String) {
        if (runCatching { UUID.fromString(sessionId) }.isFailure) return
        val store = SessionStore(context)
        val account = store.load() ?: return
        val revision = store.identityRevision() ?: return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getString("owner", null) != account.uniqueId ||
            prefs.getString("revision", null) != revision) {
            // The durable live-save may arrive before the first live packet.
            // Still create a tombstone so a delayed recording cannot revive it.
            prefs.edit().clear().putString("owner", account.uniqueId)
                .putString("revision", revision).commit()
            cancelNotification(context)
        }
        markClosed(prefs, closedIds(prefs.getString("closed", null)), sessionId)
        if (prefs.getString("sessionId", null) == sessionId) {
            prefs.edit().remove("sessionId").remove("state")
                .putLong("captured", System.currentTimeMillis()).commit()
            cancelNotification(context)
        }
    }

    @Synchronized
    fun restore(context: Context) {
        val store = SessionStore(context)
        val account = store.load()
        val revision = store.identityRevision()
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (account == null || revision == null ||
            prefs.getString("owner", null) != account.uniqueId ||
            prefs.getString("revision", null) != revision) {
            cancelNotification(context)
            return
        }
        val raw = prefs.getString("state", null) ?: return
        val state = runCatching { JSONObject(raw) }.getOrNull() ?: return
        val age = System.currentTimeMillis() - state.optLong("capturedAtMillis")
        if (age in 0L..90_000L &&
            prefs.getString("sessionId", null) == state.optString("sessionId")) {
            showNotification(context, state)
        } else {
            cancelNotification(context)
        }
    }

    @Synchronized
    fun clearForSignOut(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().commit()
        cancelNotification(context)
    }

    private fun closedIds(raw: String?): MutableList<String> {
        val array = runCatching { JSONArray(raw ?: "[]") }.getOrNull() ?: JSONArray()
        return (0 until array.length()).mapNotNull {
            array.optString(it).takeIf { value -> value.isNotBlank() }
        }.toMutableList()
    }

    private fun markClosed(
        prefs: android.content.SharedPreferences, closed: MutableList<String>, id: String
    ) {
        closed.remove(id)
        closed.add(id)
        prefs.edit().putString("closed",
            JSONArray(closed.takeLast(100)).toString()).commit()
    }

    private fun showNotification(context: Context, payload: JSONObject) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, "Actividad en vivo", NotificationManager.IMPORTANCE_LOW)
        )
        val sport = LiveSport.byId(payload.optString("sportId")) ?: return
        val paused = payload.optString("phase") == "paused"
        val seconds = payload.optDouble("elapsedSeconds", 0.0)
            .takeIf { it.isFinite() && it >= 0.0 } ?: 0.0
        val text = dev.repera.domain.LiveSportHistory.formatDuration(seconds) +
            if (paused) " · En pausa" else ""
        val open = PendingIntent.getActivity(
            context, 6207,
            Intent(context, MainActivity::class.java)
                .setData(Uri.parse("repera://home"))
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val builder = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle(payload.optString("sportTitle").ifBlank { sport.title })
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(open)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
        if (!paused) {
            builder.setWhen(System.currentTimeMillis() - (seconds * 1000).toLong())
                .setUsesChronometer(true)
        }
        runCatching { manager.notify(NOTIFICATION_ID, builder.build()) }
    }

    private fun cancelNotification(context: Context) {
        context.getSystemService(NotificationManager::class.java)
            .cancel(NOTIFICATION_ID)
    }
}
