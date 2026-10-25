package dev.repera.mobile
import org.json.JSONObject
import dev.repera.domain.ReperaHealthExclusion
import java.time.Instant
internal object HealthExclusionSnapshot {
    fun windows(bytes:ByteArray?):List<ReperaHealthExclusion.Window> {
        val state=bytes?.let {runCatching {JSONObject(String(it))}.getOrNull()} ?: return emptyList()
        val workouts=state.optJSONArray("workouts") ?: return emptyList()
        return (0 until workouts.length()).mapNotNull {i ->
            val s=workouts.optJSONObject(i) ?: return@mapNotNull null
            val start=runCatching {Instant.parse(s.getString("startedAt")).toEpochMilli()}.getOrNull() ?: return@mapNotNull null
            val end=runCatching {Instant.parse(s.getString("finishedAt")).toEpochMilli()}.getOrNull() ?:
                start+maxOf(60_000L,(s.optDouble("appleDurationSeconds",60.0)*1000).toLong())
            ReperaHealthExclusion.Window(start,end,s.optString(dev.repera.domain.HealthSessionLink.SNAPSHOT_FIELD).takeIf {it.isNotBlank()})
        }
    }
}
