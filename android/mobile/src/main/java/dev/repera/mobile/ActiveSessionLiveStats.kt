package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject

/** Contadores en vivo de Play (paridad StatsEngine.liveWorkSetCount/liveVolumeKg iOS). */
internal object ActiveSessionLiveStats {
    fun liveSetCount(session: JSONObject): Int {
        val exercises = session.optJSONArray("exercises") ?: return 0
        var count = 0
        for (i in 0 until exercises.length()) {
            val logs = exercises.getJSONObject(i).optJSONArray("loggedSets") ?: continue
            for (j in 0 until logs.length()) {
                val set = logs.getJSONObject(j)
                if (set.optBoolean("isWarmup")) continue
                if (set.optInt("reps", 0) > 0) count++
            }
        }
        return count
    }

    fun plannedSetCount(session: JSONObject): Int {
        val exercises = session.optJSONArray("exercises") ?: return 1
        var total = 0
        for (i in 0 until exercises.length()) {
            val planned = exercises.getJSONObject(i).optJSONArray("plannedSets") ?: continue
            total += planned.length().coerceAtLeast(1)
        }
        return total.coerceAtLeast(1)
    }

    fun liveVolumeKg(session: JSONObject): Double {
        val exercises = session.optJSONArray("exercises") ?: return 0.0
        var volume = 0.0
        for (i in 0 until exercises.length()) {
            val logs = exercises.getJSONObject(i).optJSONArray("loggedSets") ?: continue
            for (j in 0 until logs.length()) {
                val set = logs.getJSONObject(j)
                if (set.optBoolean("isWarmup")) continue
                val reps = set.optInt("reps", 0)
                if (reps <= 0) continue
                val weight = set.optDouble("weightKg", 0.0).takeIf { set.has("weightKg") && !set.isNull("weightKg") } ?: 0.0
                volume += reps * weight
            }
        }
        return volume
    }

    fun startedAtEpochMillis(session: JSONObject): Long? {
        val raw = session.optString("startedAt").takeIf { it.isNotBlank() } ?: return null
        return runCatching { java.time.Instant.parse(raw).toEpochMilli() }.getOrNull()
    }

    fun formatElapsed(seconds: Int): String {
        val m = seconds / 60
        val s = seconds % 60
        return if (m > 0) "$m:${s.toString().padStart(2, '0')}" else "${s}s"
    }
}
