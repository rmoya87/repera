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

    fun append(sessionId: String, exerciseIndex: Int,
                              quantity: Int, weightKg: Double?,
                              rir: Double? = null,
                              durationSeconds: Int? = null,
                              quantityUnit: String? = null,
                              deficitCm: Int? = null, intervalIndex: Int? = null,
                              sessionJson: String? = null, warmup:Boolean=false,toFailure:Boolean=false): String = synchronized(lock) {
        require(sessionId.isNotBlank() && exerciseIndex >= 0 && quantity in 1..10000)
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0))
        require(rir == null || (rir.isFinite() && rir in 0.0..5.0))
        require(durationSeconds == null || durationSeconds in 1..86400)
        require(quantityUnit == null || quantityUnit in setOf("reps", "calories", "meters"))
        require(deficitCm == null || deficitCm in 0..100)
        require(intervalIndex == null || intervalIndex in 0..100000)
        val values = JSONArray(prefs.getString("outbox", "[]"))
        require(values.length() < 100) { "Hay demasiadas series sin sincronizar" }
        val id = UUID.randomUUID().toString()
        val command = JSONObject().put("id", id).put("sessionId", sessionId)
            .put("warmup",warmup).put("toFailure",toFailure && !warmup)
            .put("exerciseIndex", exerciseIndex).put("quantity", quantity)
        if (weightKg != null) command.put("weightKg", weightKg)
        if (rir != null) command.put("rir", rir)
        if (durationSeconds != null) command.put("durationSeconds", durationSeconds)
        if (quantityUnit != null) command.put("quantityUnit", quantityUnit)
        if (deficitCm != null) command.put("deficitCm", deficitCm)
        if (intervalIndex != null) command.put("intervalIndex", intervalIndex)
        if (sessionJson != null) command.put("session", JSONObject(sessionJson))
        values.put(command)
        check(prefs.edit().putString("outbox", values.toString()).commit())
        id
    }

    fun all(): List<JSONObject> = synchronized(lock) {
        val values = JSONArray(prefs.getString("outbox", "[]"))
        (0 until values.length()).map { values.getJSONObject(it) }
    }

    fun count(): Int = synchronized(lock) { all().size }

    fun remove(id: String) = synchronized(lock) {
        if (id.isBlank()) return@synchronized
        val current = all()
        val retained = current.filter { it.optString("id") != id }
        if (retained.size == current.size) return@synchronized
        val array = JSONArray()
        retained.forEach { array.put(it) }
        check(prefs.edit().putString("outbox", array.toString()).commit())
    }

    fun clear() = synchronized(lock) {
        check(prefs.edit().remove("outbox").commit())
    }
    companion object { private val lock=Any() }
}
