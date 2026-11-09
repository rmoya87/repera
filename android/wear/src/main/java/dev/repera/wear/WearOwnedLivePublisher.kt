package dev.repera.wear

import android.content.Context
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.PutDataMapRequest
import org.json.JSONObject

/**
 * Read-only Watch-owned exercise snapshots for the paired phone.
 * No phone exercise, location tracker or Health Connect record is started.
 * A workout retains the owner scope captured when it began; an account
 * switch cannot silently assign it to the new phone identity.
 */
internal object WearOwnedLivePublisher {
    private var lastSentSession: String? = null
    private var lastSentAt = 0L

    fun publish(context: Context, live: JSONObject, force: Boolean = false) {
        if (!live.optBoolean("watchOwned")) return
        val id = live.optString("sessionId")
        val scope = live.optString("ownerScope")
        val phase = live.optString("phase")
        if (id.isBlank() || scope.isBlank() ||
            phase !in setOf("recording", "paused", "finished")) return
        val now = System.currentTimeMillis()
        if (!force && id == lastSentSession && now - lastSentAt < 30_000L) return

        val base = live.optDouble("elapsedSeconds", 0.0).coerceAtLeast(0.0)
        val capturedAt = live.optLong("capturedAtMillis", now)
        val elapsed = if (phase == "recording") {
            base + ((now - capturedAt).coerceAtLeast(0L) / 1000.0)
        } else base
        val sport = live.optString("sportId")
        if (dev.repera.domain.LiveSport.byId(sport) == null) return
        val packet = JSONObject()
            .put("ownerScope", scope)
            .put("sessionId", id)
            .put("sportId", sport)
            .put("sportTitle", live.optString("sportTitle"))
            .put("phase", phase)
            .put("elapsedSeconds", elapsed)
            .put("capturedAtMillis", now)
            .put("distanceMeters", live.optDouble("distanceMeters", 0.0))
        val bytes = packet.toString().toByteArray(Charsets.UTF_8)
        if (!WearPayload.withinLimit(bytes)) return
        lastSentSession = id
        lastSentAt = now
        // Durable coalesced state survives a transient phone disconnect. Each
        // fresh phase replaces the previous DataItem, including terminal state.
        val request = PutDataMapRequest.create("/repera/watch-owned-live").apply {
            dataMap.putByteArray("live", bytes)
            dataMap.putLong("revision", now)
        }.asPutDataRequest().setUrgent()
        Wearable.getDataClient(context).putDataItem(request)
        Wearable.getNodeClient(context).connectedNodes.addOnSuccessListener { nodes ->
            nodes.forEach { node ->
                Wearable.getMessageClient(context)
                    .sendMessage(node.id, "/repera/watch-owned-live", bytes)
            }
        }
    }

    fun close(context: Context, live: JSONObject) {
        val terminal = JSONObject(live.toString())
            .put("phase", "finished")
            .put("capturedAtMillis", System.currentTimeMillis())
        publish(context, terminal, force = true)
    }
}
