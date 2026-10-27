package dev.repera.mobile

import java.time.LocalDate
import java.time.ZoneId

/** Apple HomeView.plannedRoutinesForSelectedDay: hide a planned routine already completed that day or currently active (today only). */
internal object HomePlannedFilter {
    fun completedRoutineIds(history: List<WorkoutHistoryEntry>, day: LocalDate, zone: ZoneId = ZoneId.systemDefault()): Set<String> =
        history.filter { it.finishedAtIso != null && it.routineId != null }.filter {
            // Apple: live-sport sessions count on their start day (startedAt ?? finishedAt), others on finishedAt.
            val iso = (if (it.liveSportID != null) it.startedAtIso ?: it.finishedAtIso else it.finishedAtIso) ?: return@filter false
            runCatching { java.time.Instant.parse(iso).atZone(zone).toLocalDate() == day }.getOrDefault(false)
        }.mapNotNull { it.routineId }.toSet()

    fun <T> visible(planned: List<T>, id: (T) -> String, completedIds: Set<String>, activeRoutineId: String?, day: LocalDate, today: LocalDate): List<T> {
        val active = if (day == today) activeRoutineId else null
        return planned.filter { id(it) !in completedIds && id(it) != active }
    }
}
