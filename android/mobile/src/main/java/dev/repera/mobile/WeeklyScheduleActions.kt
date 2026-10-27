package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.DayOfWeek
import java.time.temporal.TemporalAdjusters
import java.util.UUID

/** Contract from Apple ReperaStore.copyPreviousWeekSchedule/clearWeeklySchedule. */
internal object WeeklyScheduleActions {
    /** One recurring routine per ISO weekday, while dated one-offs are independent. */
    fun makeWeekdayExclusive(state:JSONObject,routineId:String,weekday:Int) {
        require(weekday in 1..7)
        val routines=state.getJSONArray("routines")
        for(i in 0 until routines.length()) {
            val other=routines.getJSONObject(i)
            if(other.optString("id")!=routineId && other.isNull("scheduledDate") && other.optInt("weekday",-1)==weekday)
                other.remove("weekday")
        }
    }
    /** Apple removeScheduledRoutine(id:): dated routine -> favorite keeps the template (unscheduled), otherwise deleted.
     *  Weekday-only legacy routine (no Apple equivalent now): previous Apple Home rule, unassign the weekday. Returns false if nothing changed. */
    fun removeScheduled(state: JSONObject, routineId: String): Boolean {
        val routines = state.optJSONArray("routines") ?: return false
        val index = (0 until routines.length()).firstOrNull { routines.getJSONObject(it).optString("id") == routineId } ?: return false
        val routine = routines.getJSONObject(index)
        if (date(routine) != null) {
            if (routine.optBoolean("isFavorite", false)) { routine.remove("scheduledDate"); routine.remove("weekday") }
            else {
                routines.remove(index)
                state.optJSONObject("rotation")?.optJSONArray("routineIds")?.let { ids ->
                    val kept = JSONArray(); for (i in 0 until ids.length()) if (ids.optString(i) != routineId) kept.put(ids.get(i))
                    if (kept.length() == 0) state.remove("rotation") else state.getJSONObject("rotation").put("routineIds", kept)
                }
            }
            return true
        }
        if (routine.has("weekday") && !routine.isNull("weekday")) { routine.remove("weekday"); return true }
        return false
    }
    /** Apple clearWeeklySchedule(for:): only DATED routines of the Monday-Sunday week containing `week`;
     *  favorites are unscheduled (kept), others removed. Other weeks, templates and sessions untouched. Returns affected count. */
    fun clearWeek(state: JSONObject, week: LocalDate): Int {
        val routines = state.optJSONArray("routines") ?: return 0
        val start = week.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)); val end = start.plusDays(7)
        val ids = (0 until routines.length()).map { routines.getJSONObject(it) }
            .filter { r -> date(r)?.let { !it.isBefore(start) && it.isBefore(end) } == true }.map { it.optString("id") }.toSet()
        if (ids.isEmpty()) return 0
        val kept = JSONArray()
        for (i in 0 until routines.length()) {
            val r = routines.getJSONObject(i)
            if (r.optString("id") in ids) {
                if (r.optBoolean("isFavorite", false)) { r.remove("scheduledDate"); r.remove("weekday"); kept.put(r) }
            } else kept.put(r)
        }
        state.put("routines", kept)
        return ids.size
    }
    fun hasDatedRoutineInWeek(state: JSONObject, week: LocalDate): Boolean {
        val routines = state.optJSONArray("routines") ?: return false
        val start = week.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)); val end = start.plusDays(7)
        return (0 until routines.length()).any { date(routines.getJSONObject(it))?.let { d -> !d.isBefore(start) && d.isBefore(end) } == true }
    }
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
        // Snapshot before copying (Apple originallyOccupied): a second session on the same source day must not be blocked by the first copy.
        val originallyOccupied = (0 until routines.length()).mapNotNull { date(routines.getJSONObject(it)) }.toSet()
        var count = 0
        for (source in sources) {
            val target = date(source)!!.plusDays(7)
            if (target in originallyOccupied) continue
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
    /** Apple assignRoutine(_:toDate:): schedules an INDEPENDENT copy of the template on `date` (fresh ids, no weekday,
     *  not a favorite, time and progression kept). The template is not moved or changed and no recurrence is created,
     *  so several sessions can share a date. Returns the new routine id, or null if the template does not exist.
     *  Touches neither weekday routines nor rotation. */
    fun assignTemplateToDate(state: JSONObject, templateId: String, date: LocalDate): String? {
        val routines = state.optJSONArray("routines") ?: return null
        val source = (0 until routines.length()).map { routines.getJSONObject(it) }.firstOrNull { it.optString("id") == templateId } ?: return null
        val copy = deepCopy(source)
        copy.put("id", freshId()).put("scheduledDate", date.toString()).put("isFavorite", false)
        copy.remove("weekday")
        val blocks = copy.optJSONArray("blocks")
        if (blocks != null) for (i in 0 until blocks.length()) {
            val entries = blocks.getJSONObject(i).optJSONArray("exercises") ?: continue
            for (j in 0 until entries.length()) entries.getJSONObject(j).remove("supersetGroup")
        }
        routines.put(copy)
        return copy.getString("id")
    }
    /** PREPARED, NOT WIRED (no caller; needs user authorization, option B). Mirrors Apple migrateLegacyWeeklyPlans:
     *  each weekday-only routine becomes dated in the week of `today` unless that date is already occupied, plus an
     *  independent template copy (fresh ids); weekday cleared; history/activeSession untouched. Idempotent. */
    fun migrateLegacyWeekly(state: JSONObject, today: LocalDate, mondayFirst: Boolean = true): Boolean {
        val routines = state.optJSONArray("routines") ?: return false
        val legacy = (0 until routines.length()).map { routines.getJSONObject(it) }
            .filter { date(it) == null && it.has("weekday") && !it.isNull("weekday") }
        if (legacy.isEmpty()) return false
        val start = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val templates = mutableListOf<JSONObject>()
        for (source in legacy) {
            val weekday = source.optInt("weekday", -1)
            if (weekday !in 1..7) continue
            val target = start.plusDays((weekday - 1).toLong())
            val occupied = (0 until routines.length()).any { date(routines.getJSONObject(it)) == target }
            source.remove("weekday")
            if (!occupied) {
                templates += deepCopy(source).apply { remove("scheduledDate"); put("id", freshId()) }.also { it.put("isFavorite", source.optBoolean("isFavorite", false)) }
                source.put("scheduledDate", target.toString()); source.put("isFavorite", false)
            }
        }
        templates.forEach { routines.put(it) }
        return true
    }
    private fun deepCopy(source: JSONObject): JSONObject {
        val copy = JSONObject(source.toString())
        val blocks = copy.optJSONArray("blocks") ?: return copy
        for (i in 0 until blocks.length()) {
            val block = blocks.getJSONObject(i); block.put("id", freshId())
            for (key in listOf("exercises", "movements")) {
                val entries = block.optJSONArray(key) ?: continue
                for (j in 0 until entries.length()) {
                    val entry = entries.getJSONObject(j); entry.put("id", freshId())
                    for (setKey in listOf("plannedSets", "explicitPlannedSets")) {
                        val sets = entry.optJSONArray(setKey) ?: continue
                        for (n in 0 until sets.length()) sets.getJSONObject(n).put("id", freshId())
                    }
                }
            }
        }
        return copy
    }
    private fun freshId() = UUID.randomUUID().toString()
    private fun date(routine: JSONObject): LocalDate? = routine.optString("scheduledDate").takeIf {it.isNotBlank() && it != "null"}
        ?.let { runCatching { LocalDate.parse(it.take(10)) }.getOrNull() }
}
