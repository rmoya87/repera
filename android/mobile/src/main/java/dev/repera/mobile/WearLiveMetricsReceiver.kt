package dev.repera.mobile

import android.content.Context
import org.json.JSONObject

/**
 * A single inbox for visible and background Wear Health Services packets.
 *
 * Health Services CALORIES_TOTAL contains active + basal calories. The app
 * stores these as wearTotalEnergyKcal; never upgrades them to active calories.
 * Each packet must target the exact in-progress or archived workout UUID.
 */
internal object WearLiveMetricsReceiver {
    fun accept(context: Context, accountID: String, payload: JSONObject): Boolean {
        val id = payload.optString("sessionId")
        if (id.isBlank() || runCatching { java.util.UUID.fromString(id) }.isFailure) return false
        val capturedAt = payload.optLong("capturedAt", 0L)
        val now = System.currentTimeMillis()
        if (capturedAt !in (now - 25_000L)..(now + 5_000L)) return false
        val bpm = payload.optInt("bpm", -1).takeIf { it in 25..250 }
        val totalKcal = payload.optDouble("totalEnergyKcal", Double.NaN)
            .takeIf { it.isFinite() && it > 0 }
        val averageBpm = payload.optDouble("averageHeartRateBpm", Double.NaN)
            .takeIf { it.isFinite() && it in 25.0..250.0 }
        if (bpm == null && totalKcal == null && averageBpm == null) return false

        val updatedActive = LiveActivityRuntime.forAccount(context, accountID)
            .acceptWearMetrics(id, bpm, capturedAt, totalKcal, averageBpm)
        // Terminal packets may arrive after phone Save and after runtime.discard.
        // Only an exact archived UUID is eligible; no new workout is created.
        val updatedArchived = WorkoutRepository(context, accountID)
            .mergeWearMeasuredMetrics(id, totalKcal, averageBpm)
        return updatedActive || updatedArchived
    }
}
