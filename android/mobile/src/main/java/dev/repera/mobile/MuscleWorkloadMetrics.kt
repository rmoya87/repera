package dev.repera.mobile

import dev.repera.domain.ExerciseInput
import dev.repera.domain.ExerciseInputMode
import org.json.JSONArray
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Observed count of effective working sets by catalog group, not a fatigue diagnosis. */
internal object MuscleWorkloadMetrics {
    data class GroupCount(val group: String, val sets: Int)

    fun weekly(archive: JSONArray, today: LocalDate, zone: ZoneId): List<GroupCount> {
        val firstDay = today.minusDays((today.dayOfWeek.value - 1).toLong())
        val counts = mutableMapOf<String, Int>()
        for (index in 0 until archive.length()) {
            val session = archive.optJSONObject(index) ?: continue
            val recordedDate = session.optString("finishedAt").takeIf { it.isNotBlank() }
                ?: session.optString("startedAt")
            val day = runCatching {
                Instant.parse(recordedDate).atZone(zone).toLocalDate()
            }.getOrNull() ?: runCatching { LocalDate.parse(recordedDate.take(10)) }.getOrNull()
            if (day == null || day.isBefore(firstDay) || day.isAfter(today)) continue

            val exercises = session.optJSONArray("exercises") ?: continue
            for (n in 0 until exercises.length()) {
                val entry = exercises.optJSONObject(n) ?: continue
                val exercise = entry.optJSONObject("exercise") ?: continue
                val name = exercise.optString("name")
                if (name.isBlank()) continue
                val mode = ExerciseInput.mode(name, exercise.optString("equipment"),
                    exercise.optString("targetMuscle"), exercise.optString("muscleGroup"))
                if (mode == ExerciseInputMode.MACHINE_WORK ||
                    mode == ExerciseInputMode.REPS_AND_TIME) continue
                val group = exercise.optString("muscleGroup").trim()
                    .ifBlank { exercise.optString("targetMuscle").trim() }
                    .takeIf { it.isNotBlank() && !it.equals("cardio", ignoreCase = true) }
                    ?: continue
                val effective = WorkoutHistorySets.effectiveWorkSets(session, entry)
                if (effective.isEmpty()) continue
                counts[group] = (counts[group] ?: 0) + effective.size
            }
        }
        return counts.map { GroupCount(it.key, it.value) }
            .sortedWith(compareByDescending<GroupCount> { it.sets }.thenBy { it.group })
    }
}
