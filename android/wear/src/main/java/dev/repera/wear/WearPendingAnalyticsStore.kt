package dev.repera.wear

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Durable product-metrics outbox. Phone hosts Firebase; Wear only relays
 * allowlisted event names. Cleared only after `/repera/analytics-ack`.
 */
internal class WearPendingAnalyticsStore(context: Context) {
    private val prefs = context.getSharedPreferences("repera.wear.analytics-outbox", Context.MODE_PRIVATE)

    private val allowedEvents = setOf(
        "watch_app_opened",
        "watch_command_used",
        "watch_sync_confirmed",
        "watch_sync_failed"
    )

    fun append(
        event: String,
        featureArea: String = "reliability",
        result: String = "success",
        actionName: String? = null
    ): String = synchronized(lock) {
        require(event in allowedEvents) { "Evento de analytics no permitido en Wear" }
        require(featureArea.matches(SAFE) && result.matches(SAFE))
        if (actionName != null) require(actionName.matches(SAFE))
        val values = JSONArray(prefs.getString("outbox", "[]"))
        require(values.length() < 80) { "Cola de analytics Wear llena" }
        val id = UUID.randomUUID().toString()
        val row = JSONObject()
            .put("id", id)
            .put("event", event)
            .put("feature_area", featureArea)
            .put("result", result)
        if (actionName != null) row.put("action_name", actionName)
        values.put(row)
        check(prefs.edit().putString("outbox", values.toString()).commit())
        id
    }

    fun all(): List<JSONObject> = synchronized(lock) {
        val values = JSONArray(prefs.getString("outbox", "[]"))
        (0 until values.length()).map { values.getJSONObject(it) }
    }

    fun remove(id: String) = synchronized(lock) {
        if (id.isBlank()) return@synchronized
        val retained = all().filter { it.optString("id") != id }
        val array = JSONArray()
        retained.forEach { array.put(it) }
        check(prefs.edit().putString("outbox", array.toString()).commit())
    }

    fun clear() = synchronized(lock) {
        check(prefs.edit().remove("outbox").commit())
    }

    companion object {
        private val lock = Any()
        private val SAFE = Regex("^[a-zA-Z0-9_]{1,40}$")
    }
}
