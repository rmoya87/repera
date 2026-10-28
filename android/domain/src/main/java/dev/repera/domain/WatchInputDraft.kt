package dev.repera.domain

import org.json.JSONArray
import org.json.JSONObject

/** An editable draft is never a recorded set. Bind to the exact prescription cursor. */
data class WatchInputDraft(
    val sessionId: String, val exerciseIndex: Int, val recordedSets: Int,
    val quantity: Int, val weightKg: Double?, val rir: Double?,
    val durationSeconds: Int, val unit: String, val deficitCm: Int,
    val warmup: Boolean, val toFailure: Boolean,
    val kind: String = "straight",
    val drops: List<Pair<Int, Double?>> = emptyList(),
    val clusters: List<Pair<Int, Int>> = emptyList()
) {
    init {
        require(sessionId.isNotBlank() && exerciseIndex >= 1 && recordedSets >= 0)
        require(quantity in 0..10000 && durationSeconds in 1..86400 && deficitCm in 0..60)
        require(weightKg == null || weightKg.isFinite() && weightKg in 0.0..2000.0)
        require(rir == null || rir.isFinite() && rir in 0.0..5.0)
        require(unit in setOf("reps", "meters", "calories"))
        require(kind in setOf("straight", "dropset", "restpause"))
        require(drops.size <= 5)
        drops.forEach { (reps, weight) ->
            require(reps in 1..10000)
            require(weight == null || weight.isFinite() && weight in 0.0..2000.0)
        }
        clusters.forEach { (reps, rest) ->
            require(reps in 1..10000)
            require(rest in 1..600)
        }
        if (kind == "dropset") require(drops.isNotEmpty())
        if (kind == "restpause") require(clusters.isNotEmpty())
        if (kind == "straight") require(drops.isEmpty() && clusters.isEmpty())
    }
    fun matches(id: String, index: Int, sets: Int) =
        sessionId == id && exerciseIndex == index && recordedSets == sets
    fun encode(): String = JSONObject().put("version",1).put("sessionId",sessionId)
        .put("exerciseIndex",exerciseIndex).put("recordedSets",recordedSets)
        .put("quantity",quantity).put("weightKg",weightKg ?: JSONObject.NULL)
        .put("rir",rir ?: JSONObject.NULL).put("durationSeconds",durationSeconds)
        .put("unit",unit).put("deficitCm",deficitCm).put("warmup",warmup)
        .put("toFailure",toFailure).put("kind",kind)
        .put("drops", JSONArray().also { arr ->
            drops.forEach { (reps, weight) ->
                arr.put(JSONObject().put("reps", reps)
                    .put("weightKg", weight ?: JSONObject.NULL))
            }
        })
        .put("clusters", JSONArray().also { arr ->
            clusters.forEach { (reps, rest) ->
                arr.put(JSONObject().put("reps", reps).put("restSeconds", rest))
            }
        }).toString()
    companion object {
        fun decode(raw: String): WatchInputDraft? = runCatching {
            val o=JSONObject(raw)
            require(o.getInt("version")==1)
            val kind = o.optString("kind", "straight").ifBlank { "straight" }
            val drops = mutableListOf<Pair<Int, Double?>>()
            o.optJSONArray("drops")?.let { arr ->
                for (i in 0 until arr.length()) {
                    val d = arr.getJSONObject(i)
                    drops += d.getInt("reps") to
                        if (d.isNull("weightKg")) null else d.getDouble("weightKg")
                }
            }
            val clusters = mutableListOf<Pair<Int, Int>>()
            o.optJSONArray("clusters")?.let { arr ->
                for (i in 0 until arr.length()) {
                    val c = arr.getJSONObject(i)
                    clusters += c.getInt("reps") to c.getInt("restSeconds")
                }
            }
            WatchInputDraft(o.getString("sessionId"),o.getInt("exerciseIndex"),
                o.getInt("recordedSets"),o.getInt("quantity"),
                if(o.isNull("weightKg")) null else o.getDouble("weightKg"),
                if(o.isNull("rir")) null else o.getDouble("rir"),
                o.getInt("durationSeconds"),o.getString("unit"),o.getInt("deficitCm"),
                o.getBoolean("warmup"),o.getBoolean("toFailure"),
                kind = kind, drops = drops, clusters = clusters)
        }.getOrNull()
    }
}
