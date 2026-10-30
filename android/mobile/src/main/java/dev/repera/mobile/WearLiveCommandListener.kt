package dev.repera.mobile

import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject

/**
 * Receives the few watch controls that must work when MainActivity is stopped
 * (screen locked, phone in pocket). The foreground LiveActivityService remains
 * the actual location recorder; the watch is never a second GPS owner.
 *
 * The authenticated account is recovered exclusively from encrypted device
 * storage and every command is checked against the ACTIVE workout UUID.
 */
internal object WearUiPresence {
    @Volatile var active: Boolean = false
}

class WearLiveCommandListener : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        if (event.path in setOf("/repera/log-set", "/repera/session-finish")) {
            if (!WearUiPresence.active) handleBackgroundWorkout(event)
            return
        }
        if (event.path != "/repera/live-command") return
        val command = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val sessionId = command.optString("sessionId")
        val action = command.optString("command")
        if (sessionId.isBlank() || action !in setOf("pause", "resume", "finish")) return
        val owner = SessionStore(this).load()?.uniqueId ?: return
        Handler(Looper.getMainLooper()).post {
            // Do not start a new activity or sensor from a background command.
            val runtime = LiveActivityRuntime.forAccount(this, owner)
            if (SessionStore(this).load()?.uniqueId != owner ||
                runtime.state.gpsSessionID != sessionId) return@post
            when (action) {
                "pause" -> runtime.pause()
                "resume" -> runtime.resume()
                "finish" -> runtime.finish() // Review/Save remains on the phone.
            }
        }
    }

    /** The Activity listener is absent while the phone is locked. Wear keeps
     * each action in its own durable outbox until this persist-then-ACK succeeds.
     * The repository deduplicates by set UUID, including a retried message.
     */
    private fun handleBackgroundWorkout(event: MessageEvent) {
        val json = runCatching {
            JSONObject(String(event.data, Charsets.UTF_8))
        }.getOrNull() ?: return
        val sessionStore = SessionStore(this)
        val owner = sessionStore.load() ?: run {
            if (event.path == "/repera/log-set") ackSet(event.sourceNodeId, json.optString("id"), "retry")
            return
        }
        val revision = sessionStore.identityRevision()
        val authorized = {
            sessionStore.identityRevision() == revision &&
                sessionStore.load()?.uniqueId == owner.uniqueId &&
                sessionStore.load()?.userId == owner.userId
        }
        val repo = WorkoutRepository(this, owner.uniqueId, stillAuthorized = authorized)
        if (event.path == "/repera/session-finish") {
            val id = json.optString("sessionId")
            if (id.isBlank()) return
            val saved = runCatching {
                authorized() && repo.finishWearSession(id)
            }.getOrDefault(false)
            if (saved) {
                Wearable.getMessageClient(this).sendMessage(
                    event.sourceNodeId, "/repera/session-finish-ack",
                    JSONObject().put("sessionId", id).put("status", "saved")
                        .toString().toByteArray(Charsets.UTF_8)
                )
                DriveSyncWorker.syncNow(this)
            }
            return
        }
        val id = json.optString("id")
        if (id.isBlank()) return
        val sessionId = json.optString("sessionId")
        val index = json.optInt("exerciseIndex", -1)
        val reps = json.optInt("quantity", -1)
        val weight = if (json.has("weightKg") && !json.isNull("weightKg"))
            json.optDouble("weightKg", Double.NaN) else null
        val rir = if (json.has("rir") && !json.isNull("rir"))
            json.optDouble("rir", Double.NaN) else null
        val duration = if (json.has("durationSeconds") && !json.isNull("durationSeconds"))
            json.optInt("durationSeconds", -1) else null
        val deficit = if (json.has("deficitCm") && !json.isNull("deficitCm"))
            json.optInt("deficitCm", -1) else null
        val interval = if (json.has("intervalIndex") && !json.isNull("intervalIndex"))
            json.optInt("intervalIndex", -1) else null
        val kind = json.optString("kind", "straight").ifBlank { "straight" }
        if (sessionId.isBlank() || index < 0 || reps !in 1..10000 ||
            (weight != null && (!weight.isFinite() || weight < 0)) ||
            (rir != null && (!rir.isFinite() || rir !in 0.0..5.0)) ||
            (duration != null && duration !in 1..86400) ||
            (deficit != null && deficit !in 0..100) ||
            (interval != null && interval !in 0..100000) ||
            kind !in setOf("straight", "dropset", "restpause")) {
            ackSet(event.sourceNodeId, id, "rejected")
            return
        }
        val drops = runCatching {
            val values = json.optJSONArray("drops")
            if (values == null) emptyList() else (0 until values.length()).map { n ->
                val obj = values.getJSONObject(n)
                obj.getInt("reps") to
                    if (obj.has("weightKg") && !obj.isNull("weightKg")) obj.getDouble("weightKg") else null
            }
        }.getOrDefault(emptyList())
        val clusters = runCatching {
            val values = json.optJSONArray("clusters")
            if (values == null) emptyList() else (0 until values.length()).map { n ->
                val obj = values.getJSONObject(n)
                obj.getInt("reps") to obj.getInt("restSeconds")
            }
        }.getOrDefault(emptyList())
        val saved = runCatching {
            authorized() && repo.logWearSet(
                sessionId, index, id, reps, weight, rir,
                durationSeconds = duration,
                quantityUnit = json.optString("quantityUnit").takeIf {
                    it in setOf("reps", "meters", "calories")
                },
                deficitCm = deficit, intervalIndex = interval,
                sessionPayload = json.optJSONObject("session"),
                warmup = json.optBoolean("warmup", false),
                toFailure = json.optBoolean("toFailure", false),
                kind = kind, drops = drops, clusters = clusters
            )
        }.getOrDefault(false)
        ackSet(event.sourceNodeId, id, if (saved) "saved" else "retry")
        if (saved) DriveSyncWorker.syncNow(this)
    }

    private fun ackSet(node: String, id: String, status: String) {
        if (id.isBlank()) return
        Wearable.getMessageClient(this).sendMessage(
            node, "/repera/log-set-ack",
            JSONObject().put("id", id).put("status", status)
                .toString().toByteArray(Charsets.UTF_8)
        )
    }
}
