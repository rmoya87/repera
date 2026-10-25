package dev.repera.mobile

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.Record
import kotlin.reflect.KClass
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.HeartRateVariabilityRmssdRecord
import androidx.health.connect.client.records.RestingHeartRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import dev.repera.domain.HealthMuscleMapper
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Observed health information only. No MET estimates, synthetic readings or implicit writes. */
data class TodayHealth(val steps: Long?, val activeKcal: Double?)

/** Lecturas diarias para Progreso: mismo contrato que HealthKitStore en iOS. */
data class DailyHeartRatePoint(val date: LocalDate, val avgBpm: Double,
                              val minBpm: Double, val maxBpm: Double)
data class DailyEnergyPoint(val date: LocalDate, val kcal: Double)

/** Lote de salud para el snapshot de Progreso. */
data class RecoveryRead(
    val nights: List<dev.repera.domain.RecoverySleepNight>,
    val vitals: List<dev.repera.domain.RecoveryEngine.DailyVitals>
)

data class ExternalHealthHistoryEntry(val id:String,val title:String,val startMillis:Long,val endMillis:Long,val minutes:Double,val sourcePackage:String)

data class HealthSamples(
    val heartRateDays: List<DailyHeartRatePoint>,
    val energyDays: List<DailyEnergyPoint>,
    val externalActivities: List<HealthMuscleMapper.ExternalActivity>,
    val verifiedWorkoutMinutes: Map<String,HealthWorkoutMinutes.Verified> = emptyMap(),
    val externalHistory:List<ExternalHealthHistoryEntry> = emptyList()
) {
    val daySamples: List<dev.repera.domain.ExternalDaySample>
        get() = HealthMuscleMapper.daySamples(externalActivities)
    val stimuli: List<dev.repera.domain.ExternalMuscleStimulus>
        get() = HealthMuscleMapper.stimuli(externalActivities)
}

class HealthConnectReader(private val context: Context) {
    companion object {
        val permissions = setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(ExerciseSessionRecord::class),
            HealthPermission.getWritePermission(ExerciseSessionRecord::class),
            HealthPermission.getReadPermission(SleepSessionRecord::class),
            HealthPermission.getReadPermission(
                HeartRateVariabilityRmssdRecord::class),
            HealthPermission.getReadPermission(RestingHeartRateRecord::class),
            HealthPermission.getReadPermission(WeightRecord::class),
            HealthPermission.getWritePermission(WeightRecord::class)
        )

        /** Health Connect EXERCISE_TYPE_* → claves de HealthMuscleMapper
         *  (mismas familias que HKWorkoutActivityType en iOS). */
        fun exerciseTypeKey(type: Int): String = when (type) {
            ExerciseSessionRecord.EXERCISE_TYPE_RUNNING,
            ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL -> "running"
            ExerciseSessionRecord.EXERCISE_TYPE_WALKING -> "walking"
            ExerciseSessionRecord.EXERCISE_TYPE_HIKING -> "hiking"
            ExerciseSessionRecord.EXERCISE_TYPE_BIKING,
            ExerciseSessionRecord.EXERCISE_TYPE_BIKING_STATIONARY -> "cycling"
            ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL,
            ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_OPEN_WATER -> "swimming"
            ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE -> "rowing"
            ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL -> "elliptical"
            ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING,
            ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING_MACHINE -> "stairClimbing"
            ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING ->
                "highIntensityIntervalTraining"
            ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING ->
                "traditionalStrengthTraining"
            ExerciseSessionRecord.EXERCISE_TYPE_CALISTHENICS ->
                "functionalStrengthTraining"
            ExerciseSessionRecord.EXERCISE_TYPE_YOGA -> "yoga"
            ExerciseSessionRecord.EXERCISE_TYPE_PILATES -> "pilates"
            ExerciseSessionRecord.EXERCISE_TYPE_STRETCHING -> "flexibility"
            ExerciseSessionRecord.EXERCISE_TYPE_DANCING -> "dance"
            ExerciseSessionRecord.EXERCISE_TYPE_MARTIAL_ARTS -> "martialArts"
            ExerciseSessionRecord.EXERCISE_TYPE_BOXING -> "boxing"
            // kickboxing/wrestling/hockey/lacrosse no existen en este
            // SDK de Health Connect: caen en "other" (plantilla genérica).
            ExerciseSessionRecord.EXERCISE_TYPE_TENNIS -> "tennis"
            ExerciseSessionRecord.EXERCISE_TYPE_TABLE_TENNIS -> "racquetball"
            ExerciseSessionRecord.EXERCISE_TYPE_BADMINTON -> "badminton"
            ExerciseSessionRecord.EXERCISE_TYPE_SQUASH -> "squash"
            ExerciseSessionRecord.EXERCISE_TYPE_SOCCER -> "soccer"
            ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL -> "basketball"
            ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL -> "volleyball"
            ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AMERICAN -> "americanFootball"
            ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL -> "baseball"
            ExerciseSessionRecord.EXERCISE_TYPE_SOFTBALL -> "softball"
            ExerciseSessionRecord.EXERCISE_TYPE_RUGBY -> "rugby"
            ExerciseSessionRecord.EXERCISE_TYPE_GOLF -> "golf"
            ExerciseSessionRecord.EXERCISE_TYPE_SKIING -> "downhillSkiing"
            ExerciseSessionRecord.EXERCISE_TYPE_SNOWBOARDING -> "snowboarding"
            ExerciseSessionRecord.EXERCISE_TYPE_SKATING -> "skatingSports"
            ExerciseSessionRecord.EXERCISE_TYPE_SNOWSHOEING -> "snowSports"
            ExerciseSessionRecord.EXERCISE_TYPE_ROCK_CLIMBING -> "climbing"
            ExerciseSessionRecord.EXERCISE_TYPE_SURFING -> "surfingSports"
            ExerciseSessionRecord.EXERCISE_TYPE_PADDLING -> "paddleSports"
            ExerciseSessionRecord.EXERCISE_TYPE_WHEELCHAIR -> "wheelchairRunPace"
            else -> "other"
        }
    }

    fun available() = HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE

    suspend fun hasPermissions(): Boolean {
        if (!available()) return false
        val granted = HealthConnectClient.getOrCreate(context)
            .permissionController.getGrantedPermissions()
        return granted.containsAll(permissions)
    }

    suspend fun readToday(): TodayHealth = readDay(LocalDate.now())

    suspend fun readDay(day:LocalDate):TodayHealth {
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        require(granted.containsAll(permissions)) { "Debes autorizar Salud para leer actividad" }
        val zone = ZoneId.systemDefault()
        val start = day.atStartOfDay(zone).toInstant()
        val now = minOf(day.plusDays(1).atStartOfDay(zone).toInstant(),Instant.now())
        if(start>=now) return TodayHealth(null,null)
        val result = client.aggregate(
            AggregateRequest(
                metrics = setOf(StepsRecord.COUNT_TOTAL, ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL),
                timeRangeFilter = TimeRangeFilter.between(start, now)
            )
        )
        // Null means no verified reading. Zero and unknown are not interchangeable.
        return TodayHealth(
            steps = result[StepsRecord.COUNT_TOTAL],
            activeKcal = result[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]
                ?.inKilocalories
        )
    }

    /** Evidencia cruda de Salud para la ventana de una sesión, SIN elegir
     *  orígenes: candidatos de sesión de ejercicio (ventana ±45 min, como la
     *  consulta expandida de overlappingWorkout iOS), muestras de FC con su
     *  origen y kcal con su origen. La decisión la toma SessionHealthMatcher
     *  (reglas portadas de Apple); aquí solo se lee. */
    private suspend fun readSessionCandidates(startEpochMs: Long, endEpochMs: Long): List<dev.repera.domain.SessionHealthMatcher.CandidateSession> {
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        if (!granted.contains(HealthPermission.getReadPermission(ExerciseSessionRecord::class)))
            return emptyList()
        val lo = Instant.ofEpochMilli(startEpochMs - dev.repera.domain.SessionHealthMatcher.QUERY_SLACK_MS)
        val hi = Instant.ofEpochMilli(endEpochMs + dev.repera.domain.SessionHealthMatcher.QUERY_SLACK_MS)
        val response = client.readAllRecords(
            ExerciseSessionRecord::class, TimeRangeFilter.between(lo, hi))
        return response.map {
            dev.repera.domain.SessionHealthMatcher.CandidateSession(
                id = it.metadata.id,
                startEpochMs = it.startTime.toEpochMilli(),
                endEpochMs = it.endTime.toEpochMilli(),
                packageName = it.metadata.dataOrigin.packageName
            )
        }
    }

    private suspend fun readSessionEvidence(startEpochMs: Long, endEpochMs: Long): SessionEvidence {
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        val start = Instant.ofEpochMilli(startEpochMs)
        val end = Instant.ofEpochMilli(endEpochMs)
        var heart = emptyList<dev.repera.domain.SessionHealthMatcher.HeartSample>()
        if (granted.contains(HealthPermission.getReadPermission(HeartRateRecord::class))) {
            val response = client.readAllRecords(
                HeartRateRecord::class, TimeRangeFilter.between(start, end))
            heart = response.flatMap { record ->
                record.samples.map {
                    dev.repera.domain.SessionHealthMatcher.HeartSample(
                        epochMs = it.time.toEpochMilli(),
                        bpm = it.beatsPerMinute.toInt(),
                        originPackage = record.metadata.dataOrigin.packageName
                    )
                }
            }
        }
        var kcal = emptyList<KcalSample>()
        if (granted.contains(HealthPermission.getReadPermission(
                ActiveCaloriesBurnedRecord::class))) {
            val response = client.readAllRecords(
                ActiveCaloriesBurnedRecord::class, TimeRangeFilter.between(start, end))
            kcal = response.map {
                KcalSample(it.startTime.toEpochMilli(), it.endTime.toEpochMilli(),
                    it.energy.inKilocalories, it.metadata.dataOrigin.packageName)
            }
        }
        return SessionEvidence(heart, kcal)
    }

    private data class KcalSample(val startMs: Long, val endMs: Long,
                                  val kcal: Double, val originPackage: String)
    private data class SessionEvidence(
        val heart: List<dev.repera.domain.SessionHealthMatcher.HeartSample>,
        val kcal: List<KcalSample>)

    /** Rango efectivo de lectura: el de la sesión de Salud asociada
     *  (rangeStart/rangeEnd de sessionHealthExtras iOS). POLÍTICA ANDROID,
     *  más estricta que iOS por decisión del equipo: sin asociación
     *  (None) o con asociación ambigua (Ambiguous) no se lee nada — la
     *  señal que solo coincide en ventana puede ser ajena, y la nota
     *  existente se conserva (iOS sí lee FC de ventana sin workout). */
    private suspend fun matchedSession(sessionId: String?, startEpochMs: Long, endEpochMs: Long,
                                       linkedRecordId: String?): dev.repera.domain.SessionHealthMatcher.CandidateSession? {
        val candidates = readSessionCandidates(startEpochMs, endEpochMs)
        // Vínculo persistido primero (fetchWorkout(uuid) iOS), pero solo se
        // reusa si pertenece a ESTA sesión y el registro sigue válido; si no,
        // matching por ventana. Un vínculo sin sessionId no es verificable y
        // no se fía ciegamente.
        if (sessionId != null) {
            dev.repera.domain.SessionHealthMatcher.validStoredLink(
                sessionId, startEpochMs, endEpochMs, linkedRecordId,
                candidates, context.packageName)?.let { return it }
        }
        return (dev.repera.domain.SessionHealthMatcher.associate(
            startEpochMs, endEpochMs, candidates, context.packageName)
            as? dev.repera.domain.SessionHealthMatcher.Association.Matched)?.session
    }

    /** Serie temporal de FC de una sesión (epoch ms → lpm) para la curva
     *  del detalle (extras.heartRateSeries iOS). Fusiona TODOS los orígenes
     *  con dedup de duplicados exactos (SessionHealthMatcher); si la señal es
     *  contradictoria entre orígenes devuelve vacío (ni curva ni refinado). */
    suspend fun readSessionHeartSeries(startEpochMs: Long, endEpochMs: Long,
                                       linkedRecordId: String? = null,
                                       linkedSessionId: String? = null): List<Pair<Long, Int>> {
        if (!available() || endEpochMs <= startEpochMs) return emptyList()
        val matched = matchedSession(linkedSessionId, startEpochMs, endEpochMs, linkedRecordId) ?: return emptyList()
        val evidence = readSessionEvidence(matched.startEpochMs, matched.endEpochMs)
        return when (val merged = dev.repera.domain.SessionHealthMatcher
            .mergeHeartRate(evidence.heart)) {
            is dev.repera.domain.SessionHealthMatcher.HeartMerge.Merged -> merged.series
            else -> emptyList()
        }
    }

    /** Muestra de cardio de UNA sesión (HealthKitStore.sessionHealthExtras
     *  iOS). Reglas portadas de Apple:
     *  - Asociación: un único ExerciseSessionRecord plausible (umbrales de
     *    overlappingWorkout: ≥70% de la sesión, ≥60% del candidato, regla del
     *    85% entre fuentes). Ambigüedad ⇒ muestra vacía: no se refina nada y
     *    la nota existente se conserva.
     *  - FC: fusión de todos los orígenes con dedup; señal contradictoria ⇒
     *    vacío.
     *  - kcal: SOLO del origen de la sesión asociada y dentro de su rango
     *    (workout.statistics iOS); sin asociación no hay kcal. */
    suspend fun readSessionSample(startEpochMs: Long, endEpochMs: Long,
                                  linkedRecordId: String? = null,
                                  linkedSessionId: String? = null): dev.repera.domain.SessionCardioSample {
        if (!available() || endEpochMs <= startEpochMs) return dev.repera.domain.SessionCardioSample()
        // Sin asociación confiable (None o Ambiguous) no se refina: la nota
        // existente se conserva y la FC ajena en ventana no se usa.
        val matched = matchedSession(linkedSessionId, startEpochMs, endEpochMs, linkedRecordId)
            ?: return dev.repera.domain.SessionCardioSample()
        val evidence = readSessionEvidence(matched.startEpochMs, matched.endEpochMs)
        val bpm: List<Double> = when (val merged = dev.repera.domain.SessionHealthMatcher
            .mergeHeartRate(evidence.heart)) {
            is dev.repera.domain.SessionHealthMatcher.HeartMerge.Merged ->
                merged.series.map { it.second.toDouble() }
            else -> emptyList()
        }
        val kcal: Double? = evidence.kcal.filter {
            it.originPackage == matched.packageName &&
                it.startMs >= matched.startEpochMs &&
                it.endMs <= matched.endEpochMs
        }.sumOf { it.kcal }.takeIf { it > 0 }
        return dev.repera.domain.SessionCardioSample(
            averageHeartRateBpm = bpm.takeIf { it.isNotEmpty() }?.average(),
            maxHeartRateBpm = bpm.maxOrNull(),
            heartRateBpmSamples = bpm,
            activeEnergyKcal = kcal,
            durationMinutes = (endEpochMs - startEpochMs) / 60000.0
        )
    }

    /** Lecturas de los últimos `days` días para Progreso (misma ventana
     *  que ProgressTimeRange.healthFetchDayCount en iOS). */
    suspend fun readSamples(days: Int,localSessions:List<dev.repera.domain.ReperaHealthExclusion.Window> = emptyList()): HealthSamples {
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        val zone = ZoneId.systemDefault()
        val start = LocalDate.now(zone).minusDays(days.toLong() - 1)
            .atStartOfDay(zone).toInstant()
        val now = Instant.now()

        val heartRateDays = mutableMapOf<LocalDate, Triple<Double, Double, Double>>()
        val heartRateCounts = mutableMapOf<LocalDate, Int>()
        if (granted.contains(HealthPermission.getReadPermission(HeartRateRecord::class))) {
            val response = client.readAllRecords(
                HeartRateRecord::class, TimeRangeFilter.between(start, now))
            for (record in response) {
                val day = record.startTime.atZone(zone).toLocalDate()
                val bpm = record.samples.map { it.beatsPerMinute }
                if (bpm.isEmpty()) continue
                val acc = heartRateDays[day]
                val n = heartRateCounts[day] ?: 0
                heartRateDays[day] = Triple(
                    minOf(acc?.first ?: Double.MAX_VALUE, bpm.min().toDouble()),
                    (acc?.second ?: 0.0) + bpm.average() * bpm.size,
                    maxOf(acc?.third ?: 0.0, bpm.max().toDouble()))
                heartRateCounts[day] = n + bpm.size
            }
        }

        val energyDays = mutableMapOf<LocalDate, Double>()
        if (granted.contains(HealthPermission.getReadPermission(
                ActiveCaloriesBurnedRecord::class))) {
            val response = client.readAllRecords(
                ActiveCaloriesBurnedRecord::class, TimeRangeFilter.between(start, now))
            for (record in response) {
                val day = record.startTime.atZone(zone).toLocalDate()
                energyDays[day] = (energyDays[day] ?: 0.0) + record.energy.inKilocalories
            }
        }

        val externalActivities = mutableListOf<HealthMuscleMapper.ExternalActivity>()
        val externalHistory=mutableListOf<ExternalHealthHistoryEntry>()
        val verifiedMinutes=mutableMapOf<String,HealthWorkoutMinutes.Verified>()
        val linkedIDs=localSessions.mapNotNull {it.linkedHealthId}.toSet()
        if (granted.contains(HealthPermission.getReadPermission(
                ExerciseSessionRecord::class))) {
            val response = client.readAllRecords(
                ExerciseSessionRecord::class, TimeRangeFilter.between(start, now))
            for (record in response) {
                val measured=HealthWorkoutMinutes.measured(record.startTime.toEpochMilli(),record.endTime.toEpochMilli(),
                    record.segments.filter {it.segmentType==androidx.health.connect.client.records.ExerciseSegment.EXERCISE_SEGMENT_TYPE_PAUSE}
                        .map {it.startTime.toEpochMilli() to it.endTime.toEpochMilli()})
                if(record.metadata.id in linkedIDs && measured>0) {
                    verifiedMinutes[record.metadata.id]=HealthWorkoutMinutes.Verified(measured,
                        record.metadata.dataOrigin.packageName!=context.packageName)
                }
                // Las sesiones registradas por Repera no son «externas».
                if (record.metadata.dataOrigin.packageName == context.packageName) continue
                if(dev.repera.domain.ReperaHealthExclusion.matches(record.startTime.toEpochMilli(),record.endTime.toEpochMilli(),record.metadata.id,localSessions)) continue
                val minutes = measured
                if (minutes <= 0) continue
                externalHistory.add(ExternalHealthHistoryEntry(record.metadata.id,
                    record.title?.takeIf {it.isNotBlank()} ?: exerciseTypeKey(record.exerciseType),
                    record.startTime.toEpochMilli(),record.endTime.toEpochMilli(),minutes,record.metadata.dataOrigin.packageName))
                externalActivities.add(HealthMuscleMapper.ExternalActivity(
                    epochMillis = record.startTime.toEpochMilli(),
                    type = exerciseTypeKey(record.exerciseType),
                    durationMinutes = minutes))
            }
        }

        return HealthSamples(
            heartRateDays = heartRateDays.map { (day, acc) ->
                val n = heartRateCounts[day] ?: 0
                DailyHeartRatePoint(
                    date = day,
                    avgBpm = if (n > 0) acc.second / n else 0.0,
                    minBpm = if (acc.first == Double.MAX_VALUE) 0.0 else acc.first,
                    maxBpm = acc.third)
            }.sortedBy { it.date },
            energyDays = energyDays.map { (day, kcal) -> DailyEnergyPoint(day, kcal) }
                .sortedBy { it.date },
            externalActivities = externalActivities.sortedBy { it.epochMillis },
            verifiedWorkoutMinutes=verifiedMinutes,externalHistory=externalHistory.sortedByDescending {it.startMillis}
        )
    }

    /** Mediana diaria con los rangos válidos y el corte de las 7:00 de iOS
     *  (HealthPhysiologyStore.refresh). */
    private fun medianForDay(
        samples: List<Pair<Long, Double>>, day: LocalDate, zone: ZoneId,
        valid: ClosedFloatingPointRange<Double>, beforeMorning: Boolean
    ): Double? {
        val cutoff = day.atTime(7, 0).atZone(zone).toInstant().toEpochMilli()
        val sorted = samples.filter { (ts, v) ->
            Instant.ofEpochMilli(ts).atZone(zone).toLocalDate() == day &&
                (!beforeMorning || ts <= cutoff) && v.isFinite() && v in valid
        }.map { it.second }.sorted()
        if (sorted.isEmpty()) return null
        val i = sorted.size / 2
        return if (sorted.size % 2 == 0) (sorted[i - 1] + sorted[i]) / 2
        else sorted[i]
    }

    /** Noches de sueño y constantes diarias de los últimos `days` días.
     *  Solo lo concedido: sin permiso la lista sale vacía (iOS igual:
     *  nunca inventa ceros). */
    suspend fun readRecovery(days: Int): RecoveryRead {
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        val zone = ZoneId.systemDefault()
        val start = LocalDate.now(zone).minusDays(days.toLong() - 1)
            .atStartOfDay(zone).toInstant()
        val now = Instant.now()

        val stageSamples = mutableListOf<dev.repera.domain.SleepStageSample>()
        if (granted.contains(HealthPermission.getReadPermission(
                SleepSessionRecord::class))) {
            val response = client.readAllRecords(
                SleepSessionRecord::class, TimeRangeFilter.between(start, now))
            for (record in response) {
                val source = record.metadata.dataOrigin.packageName
                for (stage in record.stages) {
                    val key = when (stage.stage) {
                        SleepSessionRecord.STAGE_TYPE_DEEP -> "DEEP"
                        SleepSessionRecord.STAGE_TYPE_REM -> "REM"
                        SleepSessionRecord.STAGE_TYPE_LIGHT -> "LIGHT"
                        // Despierto no cuenta como sueño.
                        SleepSessionRecord.STAGE_TYPE_AWAKE,
                        SleepSessionRecord.STAGE_TYPE_AWAKE_IN_BED,
                        SleepSessionRecord.STAGE_TYPE_OUT_OF_BED -> continue
                        else -> "OTRO"
                    }
                    stageSamples.add(dev.repera.domain.SleepStageSample(
                        startMillis = stage.startTime.toEpochMilli(),
                        endMillis = stage.endTime.toEpochMilli(),
                        stage = key, source = source))
                }
                // Sesión sin fases: el total cuenta como "OTRO".
                if (record.stages.isEmpty()) {
                    stageSamples.add(dev.repera.domain.SleepStageSample(
                        startMillis = record.startTime.toEpochMilli(),
                        endMillis = record.endTime.toEpochMilli(),
                        stage = "OTRO", source = source))
                }
            }
        }
        val nights = dev.repera.domain.combineSleepNights(stageSamples, zone)

        val hrv = mutableListOf<Pair<Long, Double>>()
        if (granted.contains(HealthPermission.getReadPermission(
                HeartRateVariabilityRmssdRecord::class))) {
            val response = client.readAllRecords(
                HeartRateVariabilityRmssdRecord::class,
                TimeRangeFilter.between(start, now))
            for (record in response) {
                hrv.add(record.time.toEpochMilli() to record.heartRateVariabilityMillis.toDouble())
            }
        }
        val rest = mutableListOf<Pair<Long, Double>>()
        if (granted.contains(HealthPermission.getReadPermission(
                RestingHeartRateRecord::class))) {
            val response = client.readAllRecords(
                RestingHeartRateRecord::class,
                TimeRangeFilter.between(start, now))
            for (record in response) {
                rest.add(record.time.toEpochMilli() to record.beatsPerMinute.toDouble())
            }
        }
        val daysSet = (hrv + rest).map {
            Instant.ofEpochMilli(it.first).atZone(zone).toLocalDate()
        }.toSortedSet()
        val vitals = daysSet.map { day ->
            dev.repera.domain.RecoveryEngine.DailyVitals(
                day = day,
                hrvMilliseconds = medianForDay(hrv, day, zone,
                    5.0..300.0, beforeMorning = true),
                restingHeartRateBpm = medianForDay(rest, day, zone,
                    30.0..130.0, beforeMorning = true))
        }
        return RecoveryRead(nights = nights, vitals = vitals)
    }

    /** Muestras de peso corporal, más reciente primero
     *  (fetchAllBodyMassSamples de iOS). */
    suspend fun readBodyMass(): List<Pair<Long, Double>> {
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        if (!granted.contains(HealthPermission.getReadPermission(
                WeightRecord::class))) return emptyList()
        val response = client.readAllRecords(
            WeightRecord::class,
            TimeRangeFilter.between(Instant.EPOCH, Instant.now()))
        return response.map {
            it.time.toEpochMilli() to it.weight.inKilograms
        }.sortedByDescending { it.first }
    }

    /** Escribe un peso en Salud (saveBodyMass de iOS). */
    suspend fun saveBodyMass(kg: Double, epochMillis: Long, owner:String) {
        require(kg.isFinite() && kg>0 && owner.isNotBlank())
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        require(granted.contains(HealthPermission.getWritePermission(
            WeightRecord::class))) { "Falta el permiso de escritura de peso" }
        val instant = Instant.ofEpochMilli(epochMillis)
        val offset = ZoneId.systemDefault().rules.getOffset(instant)
        client.insertRecords(listOf(WeightRecord(
            time = instant, zoneOffset = offset,
            weight = androidx.health.connect.client.units.Mass.kilograms(kg),
            metadata = androidx.health.connect.client.records.metadata
                .Metadata.manualEntry(clientRecordId=BodyWeightHealthIdentity.recordId(owner,epochMillis),
                    clientRecordVersion=epochMillis)
        )))
    }
}

/** Fetch all pages. A non-null token is opaque and is never guessed or reused.
 * Errors propagate: returning only the first pages would silently invent completeness. */
internal suspend fun <T : Record> HealthConnectClient.readAllRecords(
    type: KClass<T>, range: TimeRangeFilter
): List<T> = collectHealthPages { token ->
    val page = readRecords(ReadRecordsRequest(type, range, pageToken = token))
    HealthRecordPage(page.records, page.pageToken)
}
