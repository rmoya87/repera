package dev.repera.wear

import org.json.JSONObject

/**
 * Reloj WOD local en el reloj (paridad Apple WatchSessionHub.blockElapsed).
 * Produce el mismo JSON shape que `/repera/wod-timer` del teléfono para
 * reutilizar `wearWodIntervalIndex` / `WodClock.face` sin DataItem.
 */
internal object WearLocalWodClock {
    fun seed(sessionId: String, blockIndex0: Int, exercise: JSONObject): JSONObject? {
        val format = exercise.optString("wodFormat").takeIf { it.isNotBlank() } ?: return null
        fun int(key: String): Any {
            val blockKey = "block" + key.replaceFirstChar { it.uppercase() }
            return when {
                exercise.has(key) && !exercise.isNull(key) -> exercise.optInt(key)
                exercise.has(blockKey) && !exercise.isNull(blockKey) -> exercise.optInt(blockKey)
                else -> JSONObject.NULL
            }
        }
        val stations = exercise.optJSONArray("blockMovements")?.let { arr ->
            (0 until arr.length()).count { !arr.getJSONObject(it).optBoolean("isRest") }
        } ?: 1
        return JSONObject()
            .put("sessionId", sessionId)
            .put("blockIndex", blockIndex0)
            .put("format", format)
            .put("title", exercise.optString("blockHeader").ifBlank {
                exercise.optJSONObject("exercise")?.optString("name").orEmpty()
            })
            .put("timeCapMinutes", int("timeCapMinutes"))
            .put("intervalSeconds", int("intervalSeconds"))
            .put("rounds", int("rounds"))
            .put("workSeconds", int("workSeconds"))
            .put("restSeconds", int("restSeconds"))
            .put("restBetweenRoundsSeconds",
                if (exercise.has("blockRestBetweenRoundsSeconds") &&
                    !exercise.isNull("blockRestBetweenRoundsSeconds"))
                    exercise.optInt("blockRestBetweenRoundsSeconds")
                else JSONObject.NULL)
            .put("stations", stations.coerceAtLeast(1))
            .put("plannedIntervals",
                if (exercise.has("blockPlannedIntervals") && !exercise.isNull("blockPlannedIntervals"))
                    exercise.optInt("blockPlannedIntervals") else JSONObject.NULL)
            .put("running", false)
            .put("elapsedSeconds", 0)
            .put("zeroAtWallMs", JSONObject.NULL)
            .put("local", true)
    }

    fun start(timer: JSONObject, nowWallMs: Long = System.currentTimeMillis()): JSONObject {
        val elapsed = timer.optInt("elapsedSeconds", 0).coerceAtLeast(0)
        return JSONObject(timer.toString())
            .put("running", true)
            .put("zeroAtWallMs", nowWallMs - elapsed * 1000L)
    }

    fun pause(timer: JSONObject, nowWallMs: Long = System.currentTimeMillis()): JSONObject {
        val zero = if (timer.has("zeroAtWallMs") && !timer.isNull("zeroAtWallMs"))
            timer.optLong("zeroAtWallMs") else null
        val elapsed = if (timer.optBoolean("running") && zero != null)
            ((nowWallMs - zero) / 1000L).toInt().coerceAtLeast(0)
        else timer.optInt("elapsedSeconds", 0).coerceAtLeast(0)
        return JSONObject(timer.toString())
            .put("running", false)
            .put("elapsedSeconds", elapsed)
            .put("zeroAtWallMs", JSONObject.NULL)
    }

    fun reset(timer: JSONObject): JSONObject =
        JSONObject(timer.toString())
            .put("running", false)
            .put("elapsedSeconds", 0)
            .put("zeroAtWallMs", JSONObject.NULL)

    fun tickElapsed(timer: JSONObject, nowWallMs: Long = System.currentTimeMillis()): Int {
        if (!timer.optBoolean("running")) return timer.optInt("elapsedSeconds", 0).coerceAtLeast(0)
        val zero = if (timer.has("zeroAtWallMs") && !timer.isNull("zeroAtWallMs"))
            timer.optLong("zeroAtWallMs") else return timer.optInt("elapsedSeconds", 0)
        return ((nowWallMs - zero) / 1000L).toInt().coerceAtLeast(0)
    }
}
