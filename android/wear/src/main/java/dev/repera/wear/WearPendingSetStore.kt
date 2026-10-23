package dev.repera.wear

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * At-least-once command outbox on Wear OS. The phone uses the UUID as its persisted
 * LoggedSet.id, so retries are idempotent and only a verified acknowledgement clears
 * an item. Never claim a queued set is already recorded on the phone.
 */
internal class WearPendingSetStore(context: Context) {
    private val prefs = context.getSharedPreferences("repera.wear.set-outbox", Context.MODE_PRIVATE)

    @Synchronized fun append(sessionId: String, exerciseIndex: Int,
                              quantity: Int, weightKg: Double?): String {
        require(sessionId.isNotBlank() && exerciseIndex >= 0 && quantity in 1..10000)
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0))
        val values = JSONArray(prefs.getString("outbox", "[]"))
        require(values.length() < 100) { "Hay demasiadas series sin sincronizar" }
        val id = UUID.randomUUID().toString()
        val command = JSONObject().put("id", id).put("sessionId", sessionId)
            .put("exerciseIndex", exerciseIndex).put("quantity", quantity)
        if (weightKg != null) command.put("weightKg", weightKg)
        values.put(command)
        check(prefs.edit().putString("outbox", values.toString()).commit())
        return id
    }

    @Synchronized fun all(): List<JSONObject> {
        val values = JSONArray(prefs.getString("outbox", "[]"))
        return (0 until values.length()).map { values.getJSONObject(it) }
    }

    @Synchronized fun count(): Int = all().size

    @Synchronized fun remove(id: String) {
        if (id.isBlank()) return
        val current = all()
        val retained = current.filter { it.optString("id") != id }
        if (retained.size == current.size) return
        val array = JSONArray()
        retained.forEach { array.put(it) }
        check(prefs.edit().putString("outbox", array.toString()).commit())
    }

    @Synchronized fun clear() {
        check(prefs.edit().remove("outbox").commit())
    }
}
