package dev.repera.mobile

import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Never filter the weight list by the selected statistics range. */
data class BodyWeightHistoryEntry(val id:String,val day:LocalDate,val kg:Double,val source:String)
internal object BodyWeightHistory {
    fun day(value:String, zone:ZoneId=ZoneId.systemDefault()):LocalDate? =
        runCatching {Instant.parse(value).atZone(zone).toLocalDate()}.getOrNull()
            ?: runCatching {LocalDate.parse(value)}.getOrNull()
    fun entries(state:JSONObject,zone:ZoneId=ZoneId.systemDefault()):List<BodyWeightHistoryEntry> {
        val array=state.optJSONArray("bodyWeights") ?: return emptyList()
        return (0 until array.length()).mapNotNull {i ->
            val entry=array.optJSONObject(i) ?: return@mapNotNull null
            val id=entry.optString("id").takeIf {it.isNotBlank()} ?: return@mapNotNull null
            val day=day(entry.optString("date"),zone) ?: return@mapNotNull null
            val kg=entry.optDouble("weightKg")
            if(!kg.isFinite() || kg<=0) return@mapNotNull null
            BodyWeightHistoryEntry(id,day,kg,entry.optString("source","manual"))
        }.sortedByDescending {it.day}
    }
}
