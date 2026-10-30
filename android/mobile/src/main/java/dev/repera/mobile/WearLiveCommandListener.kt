package dev.repera.mobile

import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

/**
 * Receives the few watch controls that must work when MainActivity is stopped
 * (screen locked, phone in pocket). The foreground LiveActivityService remains
 * the actual location recorder; the watch is never a second GPS owner.
 *
 * The authenticated account is recovered exclusively from encrypted device
 * storage and every command is checked against the ACTIVE workout UUID.
 */
class WearLiveCommandListener : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
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
}
