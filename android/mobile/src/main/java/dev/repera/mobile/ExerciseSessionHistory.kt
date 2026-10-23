package dev.repera.mobile

import org.json.JSONArray

/** Complete per-exercise timeline, available in the free tier like iOS ExerciseHistoryView. */
object ExerciseSessionHistory {
    data class Visit(
        val workoutId: String,
        val title: String,
        val date: String,
        val lines: List<String>
    )
    fun fromArchive(archive: JSONArray): Map<String, List<Visit>> {
        val output = linkedMapOf<String, MutableList<Visit>>()
        for (index in 0 until archive.length()) {
            val session = archive.optJSONObject(index) ?: continue
            val movements = session.optJSONArray("exercises") ?: continue
            val grouped = linkedMapOf<String, MutableList<String>>()
            for (n in 0 until movements.length()) {
                val item = movements.optJSONObject(n) ?: continue
                val id = item.optJSONObject("exercise")?.optString("id").orEmpty()
                if (id.isBlank()) continue
                val lines = WorkoutHistorySets.displayLines(session, item)
                if (lines.isEmpty()) continue
                grouped.getOrPut(id) { mutableListOf() }.addAll(lines)
            }
            val workoutId = session.optString("id")
            val title = session.optString("title")
            val date = session.optString("finishedAt").takeIf { it.isNotBlank() }
                ?: session.optString("startedAt")
            grouped.forEach { (id, lines) ->
                output.getOrPut(id) { mutableListOf() }
                    .add(Visit(workoutId, title, date, lines.toList()))
            }
        }
        return output.mapValues { (_, visits) -> visits.sortedByDescending { it.date } }
    }
}
