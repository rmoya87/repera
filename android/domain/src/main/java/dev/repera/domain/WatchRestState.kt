package dev.repera.domain

import org.json.JSONObject

/** A monotonic rest checkpoint is reusable only within the same verified device boot. */
data class WatchRestState(
    val sessionId: String, val paused: Boolean, val remainingMillis: Long,
    val capturedElapsedMillis: Long, val bootCount: Int
) {
    init {
        require(sessionId.isNotBlank() && remainingMillis in 0L..86400000L)
        require(capturedElapsedMillis >= 0 && bootCount >= 0)
    }
    fun remainingAt(id: String, nowElapsed: Long, currentBoot: Int?): Long? {
        if (id != sessionId || bootCount != currentBoot || nowElapsed < capturedElapsedMillis) return null
        return if(paused) remainingMillis else
            (remainingMillis - (nowElapsed - capturedElapsedMillis)).coerceAtLeast(0)
    }
    fun encode(): String = JSONObject().put("version",1).put("sessionId",sessionId)
        .put("paused",paused).put("remainingMillis",remainingMillis)
        .put("capturedElapsedMillis",capturedElapsedMillis).put("bootCount",bootCount).toString()
    companion object {
        fun decode(raw:String):WatchRestState? = runCatching {
            val o=JSONObject(raw);require(o.getInt("version")==1)
            WatchRestState(o.getString("sessionId"),o.getBoolean("paused"),
                o.getLong("remainingMillis"),o.getLong("capturedElapsedMillis"),o.getInt("bootCount"))
        }.getOrNull()
    }
}
