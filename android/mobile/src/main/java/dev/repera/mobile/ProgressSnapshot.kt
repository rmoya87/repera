package dev.repera.mobile

import dev.repera.domain.DayActivityContribution
import dev.repera.domain.ExternalDaySample
import dev.repera.domain.MuscleMapEngine
import dev.repera.domain.MuscleStatus
import dev.repera.domain.MuscleStimulusExercise
import dev.repera.domain.MuscleStimulusSet
import dev.repera.domain.MuscleStimulusWorkout
import dev.repera.domain.PersonalRecord
import dev.repera.domain.ProgressDayPoint
import dev.repera.domain.ProgressHealthSummary
import dev.repera.domain.ProgressSeriesGranularity
import dev.repera.domain.ProgressTimeRange
import dev.repera.domain.StatsEngine
import dev.repera.domain.StatsExercise
import dev.repera.domain.StatsSet
import dev.repera.domain.StatsWorkout
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

/**
 * Snapshot inmutable de Progreso para un rango: resume StatsEngine +
 * MuscleMapEngine sobre el archivo completo del estado. Port del
 * ProgressDataEngine de iOS (sin las partes de Salud aún no conectadas).
 */
data class ProgressSnapshotData(
    val range: ProgressTimeRange,
    val summary: ProgressHealthSummary,
    val previousSummary: ProgressHealthSummary?,
    val streak: Int,
    val previousStreak: Int,
    val records: List<PersonalRecord>,
    val muscleStatuses: List<MuscleStatus>,
    val hasHardSets: Boolean,
    /** Día → nivel 0…4 por minutos (cuartiles del periodo). */
    val heatmapTime: List<Pair<LocalDate, Int>>,
    val cardioSeries: List<ProgressDayPoint>,
    val weeklyVolume: List<Pair<LocalDate, Double>>,
    val weeklySessions: List<Pair<LocalDate, Int>>,
    val mobilitySessions: Int,
    val mobilitySeconds: Int,
    val weightPoints: List<ProgressDayPoint>,
    val weightDelta30d: Double?,
    val monthSessions: Int,
    val filteredWorkouts: Int
)

object ProgressSnapshotBuilder {

    private fun epochOf(session: JSONObject): Long? {
        val raw = session.optString("finishedAt").takeIf { it.isNotBlank() }
            ?: session.optString("startedAt").takeIf { it.isNotBlank() }
            ?: return null
        return runCatching { Instant.parse(raw).toEpochMilli() }.getOrNull()
            ?: runCatching {
                LocalDate.parse(raw.take(10)).atTime(LocalTime.NOON)
                    .atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
            }.getOrNull()
    }

    private fun unitOf(set: JSONObject, exercise: JSONObject): String? =
        sequenceOf(
            set.optString("quantityUnit"),
            exercise.optString("quantityUnit"),
            exercise.optJSONObject("exercise")?.optString("defaultQuantityUnit").orEmpty()
        ).firstOrNull { it == "calories" || it == "meters" }

    private fun statsSet(set: JSONObject, exercise: JSONObject): StatsSet {
        val drops = set.optJSONArray("drops")?.let { array ->
            (0 until array.length()).map { i ->
                val drop = array.getJSONObject(i)
                drop.optInt("reps") to
                    if (drop.has("weightKg") && !drop.isNull("weightKg"))
                        drop.optDouble("weightKg") else null
            }
        }.orEmpty()
        return StatsSet(
            reps = set.optInt("reps"),
            weightKg = if (set.has("weightKg") && !set.isNull("weightKg"))
                set.optDouble("weightKg") else null,
            quantityUnit = unitOf(set, exercise),
            deficitCm = if (set.has("deficitCm") && !set.isNull("deficitCm"))
                set.optDouble("deficitCm") else null,
            isWarmup = set.optString("phase", "work") == "warmup",
            rir = if (set.has("rir") && !set.isNull("rir"))
                set.optDouble("rir") else null,
            durationSeconds = set.optInt("durationSeconds").takeIf {
                set.has("durationSeconds") && !set.isNull("durationSeconds") && it > 0
            },
            drops = drops
        )
    }

    private fun adapt(state: JSONObject, zone: ZoneId):
            Pair<List<StatsWorkout>, List<MuscleStimulusWorkout>> {
        val archive = state.optJSONArray("workouts") ?: JSONArray()
        val stats = mutableListOf<StatsWorkout>()
        val stimuli = mutableListOf<MuscleStimulusWorkout>()
        for (index in 0 until archive.length()) {
            val session = archive.optJSONObject(index) ?: continue
            val epoch = epochOf(session) ?: continue
            val finished = session.optString("phase") == "finished" ||
                session.optString("finishedAt").isNotBlank()
            val started = runCatching {
                Instant.parse(session.optString("startedAt")).toEpochMilli()
            }.getOrNull()
            val duration = if (started != null)
                maxOf(0.0, (epoch - started) / 60000.0) else 0.0
            val exercisesJson = session.optJSONArray("exercises") ?: JSONArray()
            val exercises = mutableListOf<StatsExercise>()
            val stimulusExercises = mutableListOf<MuscleStimulusExercise>()
            for (e in 0 until exercisesJson.length()) {
                val entry = exercisesJson.optJSONObject(e) ?: continue
                val detail = entry.optJSONObject("exercise")
                val logged = entry.optJSONArray("loggedSets") ?: JSONArray()
                val sets = (0 until logged.length()).map { s ->
                    statsSet(logged.getJSONObject(s), entry)
                }
                val mobility = detail?.optString("sportTag") == "Movilidad"
                exercises.add(StatsExercise(
                    exerciseId = detail?.optString("id")
                        ?: entry.optString("exerciseId"),
                    exerciseName = detail?.optString("name") ?: "Ejercicio",
                    muscleGroup = detail?.optString("muscleGroup"),
                    isMobility = mobility,
                    sets = sets
                ))
                stimulusExercises.add(MuscleStimulusExercise(
                    sportTag = detail?.optString("sportTag"),
                    targetMuscle = detail?.optString("targetMuscle"),
                    primaryRegions = detail?.optJSONArray("primaryRegions")
                        ?.let { a -> (0 until a.length()).map { a.optString(it) } }
                        .orEmpty(),
                    secondaryMuscles = detail?.optJSONArray("secondaryMuscles")
                        ?.let { a -> (0 until a.length()).map { a.optString(it) } }
                        .orEmpty(),
                    secondaryRegions = detail?.optJSONArray("secondaryRegions")
                        ?.let { a -> (0 until a.length()).map { a.optString(it) } }
                        .orEmpty(),
                    bodyPart = detail?.optString("bodyPart"),
                    muscleGroup = detail?.optString("muscleGroup"),
                    sets = sets.map {
                        MuscleStimulusSet(
                            reps = it.reps,
                            isWarmup = it.isWarmup,
                            rir = it.rir,
                            weightKg = it.weightKg,
                            durationSeconds = it.durationSeconds,
                            isMachineQuantity = it.quantityUnit != null)
                    }
                ))
            }
            val kcal = if (session.has("appleActiveEnergyKcal") &&
                !session.isNull("appleActiveEnergyKcal"))
                session.optDouble("appleActiveEnergyKcal") else null
            stats.add(StatsWorkout(epoch, duration, finished, kcal, exercises))
            stimuli.add(MuscleStimulusWorkout(epoch, stimulusExercises))
        }
        return stats to stimuli
    }

    fun build(
        state: JSONObject,
        range: ProgressTimeRange,
        now: LocalDate = LocalDate.now(),
        zone: ZoneId = ZoneId.systemDefault(),
        nowMillis: Long = System.currentTimeMillis(),
        monday: Boolean = true
    ): ProgressSnapshotData {
        val (workouts, stimuli) = adapt(state, zone)

        val filtered = StatsEngine.filterWorkouts(workouts, range, monday, now, zone)
        val filteredStimuli = stimuli.filter { stimulus ->
            range.contains(
                Instant.ofEpochMilli(stimulus.epochMillis).atZone(zone).toLocalDate(),
                now, monday)
        }

        val summary = StatsEngine.progressHealthSummary(
            workouts, emptyList(), range, monday, now, zone)
        val previousSummary = StatsEngine.progressHealthSummary(
            StatsEngine.filterWorkoutsInPreviousPeriod(
                workouts, range, monday, now, zone),
            emptyList(), range, monday, now, zone,
            applyRangeFilter = false)

        val dates = workouts.map { it.epochMillis }
        val streak = StatsEngine.consecutiveWeekStreak(dates, emptyList(),
            monday, now, zone)
        val previousStreak = StatsEngine.consecutiveWeekStreak(dates, emptyList(),
            monday, now.minusDays(7), zone)

        val records = StatsEngine.personalRecords(filtered)

        val statuses = MuscleMapEngine.statuses(
            filteredStimuli, emptyList(), hardOnly = false, nowMillis = nowMillis)
        val hasHardSets = filteredStimuli.any { stimulus ->
            stimulus.exercises.any { entry ->
                entry.sportTag != "Movilidad" && entry.sets.any {
                    !it.isWarmup && it.reps > 0 &&
                        dev.repera.domain.Effort.isHard(it.rir)
                }
            }
        }

        val activity = StatsEngine.dailyActivity(filtered, emptyList(), zone)
        val thresholds = StatsEngine.heatmapThresholds(
            activity.values.map { it.minutes })
        val start = range.startDate(now, monday)
        val heatmap = generateSequence(start) { it.plusDays(1) }
            .takeWhile { !it.isAfter(now) }
            .take(370)
            .map { day ->
                val row: DayActivityContribution? = activity[day]
                day to StatsEngine.heatmapLevel(
                    row?.minutes ?: 0.0, row != null, thresholds)
            }
            .toList()

        val cardioRaw = StatsEngine.dailyMetricSeries(filtered, emptyList(),
            "cardioMinutes", range, monday, now, zone)
        val cardioSeries = StatsEngine.averagedSeries(cardioRaw,
            StatsEngine.granularityForChart(range), monday)

        var mobilitySessions = 0
        var mobilitySeconds = 0
        val archive = state.optJSONArray("workouts") ?: JSONArray()
        val filteredEpochs = filtered.map { it.epochMillis }.toSet()
        for (index in 0 until archive.length()) {
            val session = archive.optJSONObject(index) ?: continue
            if (epochOf(session) !in filteredEpochs) continue
            if (session.optString("phase") != "finished" &&
                session.optString("finishedAt").isBlank()) continue
            val exercisesJson = session.optJSONArray("exercises") ?: continue
            var duration = 0
            for (e in 0 until exercisesJson.length()) {
                val entry = exercisesJson.optJSONObject(e) ?: continue
                if (entry.optJSONObject("exercise")?.optString("sportTag") != "Movilidad")
                    continue
                val logged = entry.optJSONArray("loggedSets") ?: continue
                for (s in 0 until logged.length()) {
                    val set = logged.getJSONObject(s)
                    if (set.optString("phase", "work") == "warmup" ||
                        set.optInt("reps") <= 0) continue
                    val sec = set.optInt("durationSeconds")
                    if (sec > 0) duration += sec
                }
            }
            if (duration > 0) {
                mobilitySessions += 1
                mobilitySeconds += duration
            }
        }

        val bodyWeights = state.optJSONArray("bodyWeights") ?: JSONArray()
        val weightEntries = (0 until bodyWeights.length()).mapNotNull { i ->
            val entry = bodyWeights.optJSONObject(i) ?: return@mapNotNull null
            val date = runCatching {
                LocalDate.parse(entry.optString("date").take(10))
            }.getOrNull() ?: return@mapNotNull null
            val kg = entry.optDouble("weightKg")
            if (kg > 0) date to kg else null
        }
        val weightPoints = weightEntries
            .filter { (date, _) -> range.contains(date, now, monday) }
            .sortedBy { it.first }
            .map { ProgressDayPoint(it.first, it.second) }
            .let { raw ->
                if (StatsEngine.granularityForChart(range) ==
                    ProgressSeriesGranularity.DAY || raw.size <= 1) raw
                else StatsEngine.averagedSeries(raw,
                    StatsEngine.granularityForChart(range), monday)
            }
        val weightDelta = StatsEngine.bodyWeightDelta30d(
            weightEntries.map {
                it.first.atTime(LocalTime.NOON).atZone(zone).toInstant()
                    .toEpochMilli() to it.second
            }, now, zone)

        return ProgressSnapshotData(
            range = range,
            summary = summary,
            previousSummary = previousSummary,
            streak = streak,
            previousStreak = previousStreak,
            records = records,
            muscleStatuses = statuses,
            hasHardSets = hasHardSets,
            heatmapTime = heatmap,
            cardioSeries = cardioSeries,
            weeklyVolume = StatsEngine.weeklyVolumeSeries(
                workouts, 8, now, zone, monday),
            weeklySessions = StatsEngine.weeklySessionSeries(
                workouts, 8, now, zone, monday),
            mobilitySessions = mobilitySessions,
            mobilitySeconds = mobilitySeconds,
            weightPoints = weightPoints,
            weightDelta30d = weightDelta,
            monthSessions = StatsEngine.workoutsThisMonth(
                workouts, emptyList(), now, zone),
            filteredWorkouts = filtered.size
        )
    }
}
