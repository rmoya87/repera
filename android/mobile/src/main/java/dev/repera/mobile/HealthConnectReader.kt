package dev.repera.mobile

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
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

data class HealthSamples(
    val heartRateDays: List<DailyHeartRatePoint>,
    val energyDays: List<DailyEnergyPoint>,
    val externalActivities: List<HealthMuscleMapper.ExternalActivity>
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

    suspend fun readToday(): TodayHealth {
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        require(granted.containsAll(permissions)) { "Debes autorizar Salud para leer actividad" }
        val zone = ZoneId.systemDefault()
        val start = LocalDate.now(zone).atStartOfDay(zone).toInstant()
        val now = Instant.now()
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

    /** Muestra de cardio de UNA sesión (HealthKitStore.sessionHealthExtras
     *  iOS): serie de FC y kcal activas dentro de la ventana del entreno.
     *  Requiere permisos ya concedidos; sin permiso devuelve muestra vacía. */
    suspend fun readSessionSample(startEpochMs: Long, endEpochMs: Long): dev.repera.domain.SessionCardioSample {
        if (!available() || endEpochMs <= startEpochMs) return dev.repera.domain.SessionCardioSample()
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        val start = Instant.ofEpochMilli(startEpochMs)
        val end = Instant.ofEpochMilli(endEpochMs)
        var bpm: List<Double> = emptyList()
        if (granted.contains(HealthPermission.getReadPermission(HeartRateRecord::class))) {
            val response = client.readRecords(ReadRecordsRequest(
                HeartRateRecord::class, TimeRangeFilter.between(start, end)))
            bpm = response.records.flatMap { it.samples }
                .map { it.beatsPerMinute.toDouble() }
        }
        var kcal: Double? = null
        if (granted.contains(HealthPermission.getReadPermission(
                ActiveCaloriesBurnedRecord::class))) {
            val response = client.readRecords(ReadRecordsRequest(
                ActiveCaloriesBurnedRecord::class, TimeRangeFilter.between(start, end)))
            val total = response.records.sumOf { it.energy.inKilocalories }
            if (total > 0) kcal = total
        }
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
    suspend fun readSamples(days: Int): HealthSamples {
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
            val response = client.readRecords(ReadRecordsRequest(
                HeartRateRecord::class, TimeRangeFilter.between(start, now)))
            for (record in response.records) {
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
            val response = client.readRecords(ReadRecordsRequest(
                ActiveCaloriesBurnedRecord::class, TimeRangeFilter.between(start, now)))
            for (record in response.records) {
                val day = record.startTime.atZone(zone).toLocalDate()
                energyDays[day] = (energyDays[day] ?: 0.0) + record.energy.inKilocalories
            }
        }

        val externalActivities = mutableListOf<HealthMuscleMapper.ExternalActivity>()
        if (granted.contains(HealthPermission.getReadPermission(
                ExerciseSessionRecord::class))) {
            val response = client.readRecords(ReadRecordsRequest(
                ExerciseSessionRecord::class, TimeRangeFilter.between(start, now)))
            for (record in response.records) {
                // Las sesiones registradas por Repera no son «externas».
                if (record.metadata.dataOrigin.packageName == context.packageName) continue
                val minutes = maxOf(0.0,
                    (record.endTime.epochSecond - record.startTime.epochSecond) / 60.0)
                if (minutes <= 0) continue
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
            externalActivities = externalActivities.sortedBy { it.epochMillis }
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
            val response = client.readRecords(ReadRecordsRequest(
                SleepSessionRecord::class, TimeRangeFilter.between(start, now)))
            for (record in response.records) {
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
            val response = client.readRecords(ReadRecordsRequest(
                HeartRateVariabilityRmssdRecord::class,
                TimeRangeFilter.between(start, now)))
            for (record in response.records) {
                hrv.add(record.time.toEpochMilli() to record.heartRateVariabilityMillis.toDouble())
            }
        }
        val rest = mutableListOf<Pair<Long, Double>>()
        if (granted.contains(HealthPermission.getReadPermission(
                RestingHeartRateRecord::class))) {
            val response = client.readRecords(ReadRecordsRequest(
                RestingHeartRateRecord::class,
                TimeRangeFilter.between(start, now)))
            for (record in response.records) {
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
        val response = client.readRecords(ReadRecordsRequest(
            WeightRecord::class,
            TimeRangeFilter.between(Instant.EPOCH, Instant.now())))
        return response.records.map {
            it.time.toEpochMilli() to it.weight.inKilograms
        }.sortedByDescending { it.first }
    }

    /** Escribe un peso en Salud (saveBodyMass de iOS). */
    suspend fun saveBodyMass(kg: Double, epochMillis: Long) {
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
                .Metadata.manualEntry()
        )))
    }
}
