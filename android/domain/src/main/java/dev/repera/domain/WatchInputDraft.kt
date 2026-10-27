package dev.repera.domain

import org.json.JSONObject

/** An editable draft is never a recorded set. Bind to the exact prescription cursor. */
data class WatchInputDraft(
    val sessionId: String, val exerciseIndex: Int, val recordedSets: Int,
    val quantity: Int, val weightKg: Double?, val rir: Double?,
    val durationSeconds: Int, val unit: String, val deficitCm: Int,
    val warmup: Boolean, val toFailure: Boolean
) {
    init {
        require(sessionId.isNotBlank() && exerciseIndex >= 1 && recordedSets >= 0)
        require(quantity in 0..10000 && durationSeconds in 1..86400 && deficitCm in 0..60)
        require(weightKg == null || weightKg.isFinite() && weightKg in 0.0..2000.0)
        require(rir == null || rir.isFinite() && rir in 0.0..5.0)
        require(unit in setOf("reps", "meters", "calories"))
    }
    fun matches(id: String, index: Int, sets: Int) =
        sessionId == id && exerciseIndex == index && recordedSets == sets
    fun encode(): String = JSONObject().put("version",1).put("sessionId",sessionId)
        .put("exerciseIndex",exerciseIndex).put("recordedSets",recordedSets)
        .put("quantity",quantity).put("weightKg",weightKg ?: JSONObject.NULL)
        .put("rir",rir ?: JSONObject.NULL).put("durationSeconds",durationSeconds)
        .put("unit",unit).put("deficitCm",deficitCm).put("warmup",warmup)
        .put("toFailure",toFailure).toString()
    companion object {
        fun decode(raw: String): WatchInputDraft? = runCatching {
            val o=JSONObject(raw)
            require(o.getInt("version")==1)
            WatchInputDraft(o.getString("sessionId"),o.getInt("exerciseIndex"),
                o.getInt("recordedSets"),o.getInt("quantity"),
                if(o.isNull("weightKg")) null else o.getDouble("weightKg"),
                if(o.isNull("rir")) null else o.getDouble("rir"),
                o.getInt("durationSeconds"),o.getString("unit"),o.getInt("deficitCm"),
                o.getBoolean("warmup"),o.getBoolean("toFailure"))
        }.getOrNull()
    }
}
