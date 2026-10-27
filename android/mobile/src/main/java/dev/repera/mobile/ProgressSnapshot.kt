package dev.repera.mobile

import dev.repera.domain.DayActivityContribution
import dev.repera.domain.ExternalDaySample
import dev.repera.domain.HealthMuscleMapper
import dev.repera.domain.MuscleLoadEngine
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
internal fun performedForChart(e: dev.repera.domain.StatsExercise): Boolean =
    e.sets.any { !it.isWarmup && (it.reps > 0 || (it.durationSeconds ?: 0) > 0) } || (e.isMobility && e.sets.any { it.reps > 0 })

data class ProgressExerciseRow(val id:String,val name:String,val topWeight:Double?,val lastEpochMillis:Long=0,val isMobility:Boolean=false)

data class ProgressSnapshotData(
    val range: ProgressTimeRange,
    val summary: ProgressHealthSummary,
    val previousSummary: ProgressHealthSummary?,
    val streak: Int,
    val previousStreak: Int,
    val records: List<PersonalRecord>,
    val muscleStatuses: List<MuscleStatus>,
    val hasHardSets: Boolean,
    val includesEstimatedWodMuscles: Boolean = false,
    /** Series efectivas por músculo del periodo, todas (port preparedLoadAll iOS). */
    val muscleLoadAll: Map<String, Double>,
    /** Series efectivas duras (RIR) por músculo del periodo (preparedLoadHard iOS). */
    val muscleLoadHard: Map<String, Double>,
    /** Fatiga retenida por músculo, todas las series (preparedFatigueAll iOS). */
    val muscleFatigueAll: Map<String, Double>,
    /** Fatiga retenida solo series duras (preparedFatigueHard iOS). */
    val muscleFatigueHard: Map<String, Double>,
    /** Día → nivel 0…4 por minutos (cuartiles del periodo). */
    val heatmapTime: List<Pair<LocalDate, Int>>,
    /** Día → nivel 0…4 por volumen en kg (cuartiles del periodo). */
    val heatmapVolume: List<Pair<LocalDate, Int>>,
    val cardioSeries: List<ProgressDayPoint>,
    val weeklyVolume: List<Pair<LocalDate, Double>>,
    val weeklySessions: List<Pair<LocalDate, Int>>,
    val mobilitySessions: Int,
    val mobilitySeconds: Int,
    val weightPoints: List<ProgressDayPoint>,
    val weightDelta30d: Double?,
    val monthSessions: Int,
    val filteredWorkouts: Int,
    val averageHeartRate: Double? = null,
    val previousAverageHeartRate: Double? = null,
    val externalSessions: Int = 0,
    val chartExercises:List<ProgressExerciseRow> = emptyList()
)

object ProgressSnapshotBuilder {

    private fun epochOf(session: JSONObject): Long? {
        // Sesiones "En vivo": el día es el de INICIO (StatsEngine.swift:
        // liveSportID == nil ? finishedAt ?? startedAt : startedAt ?? finishedAt).
        val live = session.optString("liveSportID").takeIf { it.isNotBlank() && it != "null" } != null
        val raw = if (live)
            session.optString("startedAt").takeIf { it.isNotBlank() }
                ?: session.optString("finishedAt").takeIf { it.isNotBlank() }
        else
            session.optString("finishedAt").takeIf { it.isNotBlank() }
                ?: session.optString("startedAt").takeIf { it.isNotBlank() }
        if (raw == null) return null
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

    /** Archivo completo adaptado a StatsWorkout (para StatsEngine y
     *  ProgressionEngine). */
    fun statsWorkouts(state: JSONObject, zone: ZoneId = ZoneId.systemDefault()):
            List<StatsWorkout> = adapt(state, zone).first

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
            // En vivo: duración ACTIVA medida por Repera (sin pausas), no
            // reloj de pared (Models.swift durationMinutes/displayDurationMinutes).
            val liveSportID = session.optString("liveSportID").takeIf { it.isNotBlank() && it != "null" }
            val activeSeconds = session.optDouble("activeDurationSeconds",Double.NaN)
                .takeIf { liveSportID != null && it.isFinite() }
            val measuredSeconds = session.optDouble("appleDurationSeconds",Double.NaN)
                .takeIf { it.isFinite() && it > 0 }
            val end = runCatching { Instant.parse(session.optString("finishedAt")).toEpochMilli() }.getOrNull()
            val duration = when {
                activeSeconds != null -> maxOf(0.0, activeSeconds / 60.0)
                measuredSeconds != null -> measuredSeconds / 60.0
                started != null && end != null -> maxOf(0.0, (end-started)/60000.0)
                else -> 0.0
            }
            val exercisesJson = session.optJSONArray("exercises") ?: JSONArray()
            val exercises = mutableListOf<StatsExercise>()
            val stimulusExercises = mutableListOf<MuscleStimulusExercise>()
            for (e in 0 until exercisesJson.length()) {
                val entry = exercisesJson.optJSONObject(e) ?: continue
                val detail = entry.optJSONObject("exercise")
                val logged = entry.optJSONArray("loggedSets") ?: JSONArray()
                val recorded = (0 until logged.length()).map { s ->
                    statsSet(logged.getJSONObject(s), entry)
                }
                // Apple StatsEngine.confirmedWorkSets: una sesión finalizada sin registros acepta lo prescrito
                // (misma regla que ya usan carga muscular e historial); nunca se escribe en disco.
                val sets = if (logged.length() == 0 && finished) {
                    WorkoutHistorySets.confirmedWorkSets(session, entry).map { eff ->
                        StatsSet(reps = eff.reps, weightKg = eff.weightKg, quantityUnit = when (eff.unit) { "cal" -> "calories"; "m" -> "meters"; else -> null },
                            durationSeconds = eff.durationSeconds, rir = eff.rir)
                    }
                } else recorded
                val mobility = detail?.optString("sportTag") == "Movilidad"
                val planned = entry.optJSONArray("plannedSets")
                exercises.add(StatsExercise(
                    exerciseId = detail?.optString("id")
                        ?: entry.optString("exerciseId"),
                    exerciseName = detail?.exerciseDisplayName() ?: "Ejercicio",
                    muscleGroup = detail?.optString("muscleGroup"),
                    isMobility = mobility,
                    sets = sets,
                    plannedTargetReps = planned?.optJSONObject(0)
                        ?.optInt("targetReps")?.takeIf { it > 0 },
                    plannedSetCount = planned?.length() ?: 0
                ))
                val blockId = entry.optString("blockId").takeIf { it.isNotBlank() && it != "null" }
                val wodResultsJson = session.optJSONArray("wodResults")
                val hasBlockScore = blockId != null && wodResultsJson != null &&
                    (0 until wodResultsJson.length()).any { wodResultsJson.optJSONObject(it)?.optString("id") == blockId }
                val noWorkRecorded = (0 until logged.length()).none {
                    val l = logged.getJSONObject(it)
                    l.optString("phase", "work") == "work" && l.optInt("reps") > 0
                }
                val completedWod = if (finished && (entry.optString("blockKind") == "wod" || hasBlockScore) &&
                    !mobility && noWorkRecorded) 1.0 else 0.0
                stimulusExercises.add(MuscleStimulusExercise(
                    completedWodSetEquivalent = completedWod,
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
                    // Apple MuscleMapEngine usa StatsEngine.confirmedWorkSets: sin terminar no cuenta y los
                    // calentamientos/series sin reps nunca aportan fatiga ni carga.
                    sets = (if (finished) sets.filter { !it.isWarmup && it.reps > 0 } else emptyList()).map {
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
            stats.add(StatsWorkout(
                epoch, duration, finished, kcal, exercises,
                liveSportID = liveSportID))
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
        monday: Boolean = true,
        health: HealthSamples? = null
    ): ProgressSnapshotData {
        val (workouts, stimuli) = adapt(state, zone)
        // Una sesión de Comenzar sincronizada en Salud (p. ej. copia del reloj) se cuenta solo una vez.
        val health = health?.copy(externalActivities =
            HealthMuscleMapper.dropNativeOverlaps(health.externalActivities, workouts))
        val externalSamples = health?.daySamples.orEmpty()
        // Apple (live main): el propio «Comenzar» aporta carga por deporte y duración activa; la capa de esfuerzo
        // alto solo recibe estímulos de modalidades intensas (nunca un paseo).
        val externalStimuli = health?.stimuli.orEmpty() + HealthMuscleMapper.nativeSportStimuli(workouts)
        val highEffortStimuli = HealthMuscleMapper.highEffortStimuli(health?.externalActivities.orEmpty()) +
            HealthMuscleMapper.nativeHighEffortSportStimuli(workouts)

        val filtered = StatsEngine.filterWorkouts(workouts, range, monday, now, zone)
        val filteredExternal = StatsEngine.filterExternal(
            externalSamples, range, monday, now, zone)
        val filteredStimuli = stimuli.filter { stimulus ->
            range.contains(
                Instant.ofEpochMilli(stimulus.epochMillis).atZone(zone).toLocalDate(),
                now, monday)
        }

        val summary = StatsEngine.progressHealthSummary(
            workouts, externalSamples, range, monday, now, zone)
        val previousSummary = StatsEngine.progressHealthSummary(
            StatsEngine.filterWorkoutsInPreviousPeriod(
                workouts, range, monday, now, zone),
            StatsEngine.filterExternal(externalSamples, range, monday, now, zone)
                .filter {
                    range.containsInPreviousPeriod(
                        Instant.ofEpochMilli(it.epochMillis).atZone(zone).toLocalDate(),
                        now, monday)
                },
            range, monday, now, zone,
            applyRangeFilter = false)

        val dates = workouts.map { it.epochMillis }
        val externalDates = externalSamples.map { it.epochMillis }
        val streak = StatsEngine.consecutiveWeekStreak(dates, externalDates,
            monday, now, zone)
        // Apple b4b8f8b8: mismo dia relativo del periodo anterior (bounds.end - 1s),
        // no necesariamente el ultimo dia de la semana o del mes anterior.
        val previousStreak = StatsEngine.consecutiveWeekStreak(dates, externalDates,
            monday, range.previousPeriodStreakReference(now, monday), zone)

        val averageHeartRate = health?.heartRateDays
            ?.filter { range.contains(it.date, now, monday) }
            ?.takeIf { it.isNotEmpty() }
            ?.map { it.avgBpm }?.average()
        val previousAverageHeartRate = health?.heartRateDays
            ?.filter { range.containsInPreviousPeriod(it.date, now, monday) }
            ?.takeIf { it.isNotEmpty() }
            ?.map { it.avgBpm }?.average()

        val records = StatsEngine.personalRecords(filtered)

        val externalInRange = externalStimuli.filter { stimulus ->
            range.contains(
                Instant.ofEpochMilli(stimulus.epochMillis).atZone(zone).toLocalDate(),
                now, monday)
        }
        val highEffortInRange = highEffortStimuli.filter { stimulus ->
            range.contains(
                Instant.ofEpochMilli(stimulus.epochMillis).atZone(zone).toLocalDate(),
                now, monday)
        }
        val statuses = MuscleMapEngine.statuses(
            filteredStimuli, externalInRange, hardOnly = false, nowMillis = nowMillis)
        // Mapas preparados para la tarjeta Equilibrio muscular (port iOS ProgressSnapshot).
        val loadAll = MuscleLoadEngine.load(filteredStimuli, externalInRange, hardOnly = false)
        val loadHard = MuscleLoadEngine.load(filteredStimuli, highEffortInRange, hardOnly = true)
        val fatigueAll = MuscleMapEngine.retainedLoad(filteredStimuli, externalInRange,
            hardOnly = false, nowMillis = nowMillis)
        val fatigueHard = MuscleMapEngine.retainedLoad(filteredStimuli, highEffortInRange,
            hardOnly = true, nowMillis = nowMillis)
        val hasHardSets = highEffortInRange.isNotEmpty() || filteredStimuli.any { stimulus ->
            stimulus.exercises.any { entry ->
                entry.sportTag != "Movilidad" && entry.sets.any {
                    !it.isWarmup && it.reps > 0 &&
                        dev.repera.domain.Effort.isHard(it.rir)
                }
            }
        }

        // Apple MuscleBalanceCard.includesEstimatedWODMuscles: nota solo si algún WOD confirmado aporta estimación mínima.
        val includesEstimatedWodMuscles = filteredStimuli.any { w -> w.exercises.any { it.completedWodSetEquivalent > 0 } }

        val activity = StatsEngine.dailyActivity(filtered, filteredExternal, zone)
        val thresholds = StatsEngine.heatmapThresholds(
            activity.values.map { it.minutes })
        val volumeThresholds = StatsEngine.heatmapThresholds(
            activity.values.map { it.volumeKg })
        val start = range.startDate(now, monday)
        val days = generateSequence(start) { it.plusDays(1) }
            .takeWhile { !it.isAfter(now) }
            .take(370).toList()
        val heatmap = days.map { day ->
            val row: DayActivityContribution? = activity[day]
            day to StatsEngine.heatmapLevel(
                row?.minutes ?: 0.0, row != null, thresholds)
        }
        val heatmapVolume = days.map { day ->
            val row: DayActivityContribution? = activity[day]
            day to StatsEngine.heatmapLevel(
                row?.volumeKg ?: 0.0, row != null, volumeThresholds)
        }

        val cardioRaw = StatsEngine.dailyMetricSeries(filtered, filteredExternal,
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
            // Apple ProgressSnapshot (live main): solo ejercicios realmente practicados (series confirmadas, o movilidad con reps);
            // los que solo figuraban en el plan no entran, y la fecha es la de la última sesión donde se practicó.
            chartExercises=filtered.flatMap {w ->w.exercises.filter {performedForChart(it)}.map {w.epochMillis to it}}.groupBy {it.second.exerciseId}.map {(id,items) ->
                val ex=items.map {it.second}
                ProgressExerciseRow(id,ex.first().exerciseName,ex.flatMap {it.sets}.filter { !it.isWarmup && it.reps>0 }.mapNotNull {it.weightKg?.takeIf {kg ->kg>0}}.maxOrNull(),
                    items.maxOf {it.first},ex.any {it.isMobility})
            }.sortedWith(compareByDescending<ProgressExerciseRow> {it.lastEpochMillis}.thenBy {it.name}),
            muscleStatuses = statuses,
            hasHardSets = hasHardSets,
            includesEstimatedWodMuscles = includesEstimatedWodMuscles,
            muscleLoadAll = loadAll,
            muscleLoadHard = loadHard,
            muscleFatigueAll = fatigueAll,
            muscleFatigueHard = fatigueHard,
            heatmapTime = heatmap,
            heatmapVolume = heatmapVolume,
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
                workouts, externalDates, now, zone),
            filteredWorkouts = filtered.size,
            averageHeartRate = averageHeartRate,
            previousAverageHeartRate = previousAverageHeartRate,
            externalSessions = filteredExternal.size
        )
    }
}
