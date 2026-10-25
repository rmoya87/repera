package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.DayOfWeek
import java.time.temporal.TemporalAdjusters
import java.util.UUID

/** Contract from Apple ReperaStore.copyPreviousWeekSchedule/clearWeeklySchedule. */
internal object WeeklyScheduleActions {
    fun clear(state: JSONObject) {
        val routines = state.optJSONArray("routines") ?: JSONArray()
        for (i in 0 until routines.length()) {
            val routine = routines.getJSONObject(i)
            if (routine.isNull("scheduledDate")) routine.remove("weekday")
        }
        state.remove("rotation")
    }

    fun copyPreviousWeek(state: JSONObject, today: LocalDate): Int {
        val routines = state.getJSONArray("routines")
        val monday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val previous = monday.minusDays(7)
        val sources = (0 until routines.length()).map { routines.getJSONObject(it) }.filter {
            val date = date(it)
            date != null && !date.isBefore(previous) && date.isBefore(monday)
        }
        var count = 0
        for (source in sources) {
            val target = date(source)!!.plusDays(7)
            if ((0 until routines.length()).any { date(routines.getJSONObject(it)) == target }) continue
            val copy = JSONObject().put("id", freshId()).put("title", source.getString("title"))
                .put("scheduledDate", target.toString()).put("isFavorite", false)
                .put("progression", source.optString("progression", "off"))
            if (!source.isNull("scheduledTimeMinutes")) copy.put("scheduledTimeMinutes", source.get("scheduledTimeMinutes"))
            val blocks = JSONArray(source.optJSONArray("blocks")?.toString() ?: "[]")
            for (i in 0 until blocks.length()) {
                val block = blocks.getJSONObject(i); block.put("id", freshId())
                for (key in listOf("exercises", "movements")) {
                    val entries = block.optJSONArray(key) ?: continue
                    for (j in 0 until entries.length()) {
                        val entry = entries.getJSONObject(j); entry.put("id", freshId())
                        if (key == "exercises") entry.remove("supersetGroup")
                        for (setKey in listOf("plannedSets", "explicitPlannedSets")) {
                            val sets = entry.optJSONArray(setKey) ?: continue
                            for (n in 0 until sets.length()) sets.getJSONObject(n).put("id", freshId())
                        }
                    }
                }
            }
            copy.put("blocks", blocks); routines.put(copy); count++
        }
        return count
    }
    private fun freshId() = UUID.randomUUID().toString()
    private fun date(routine: JSONObject): LocalDate? = routine.optString("scheduledDate").takeIf {it.isNotBlank() && it != "null"}
        ?.let { runCatching { LocalDate.parse(it.take(10)) }.getOrNull() }
}
