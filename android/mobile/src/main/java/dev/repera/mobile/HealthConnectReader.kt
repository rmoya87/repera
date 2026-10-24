package dev.repera.mobile

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
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
data class DailyHeartRatePoint(val date: LocalDate, val avgBpm: Double)
data class DailyEnergyPoint(val date: LocalDate, val kcal: Double)

/** Lote de salud para el snapshot de Progreso. */
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
            HealthPermission.getReadPermission(ExerciseSessionRecord::class)
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

        val heartRateDays = mutableMapOf<LocalDate, Pair<Double, Int>>()
        if (granted.contains(HealthPermission.getReadPermission(HeartRateRecord::class))) {
            val response = client.readRecords(ReadRecordsRequest(
                HeartRateRecord::class, TimeRangeFilter.between(start, now)))
            for (record in response.records) {
                val day = record.startTime.atZone(zone).toLocalDate()
                val bpm = record.samples.map { it.beatsPerMinute }
                if (bpm.isEmpty()) continue
                val acc = heartRateDays[day] ?: (0.0 to 0)
                heartRateDays[day] =
                    (acc.first + bpm.average() * bpm.size) to (acc.second + bpm.size)
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
                DailyHeartRatePoint(day, if (acc.second > 0) acc.first / acc.second else 0.0)
            }.sortedBy { it.date },
            energyDays = energyDays.map { (day, kcal) -> DailyEnergyPoint(day, kcal) }
                .sortedBy { it.date },
            externalActivities = externalActivities.sortedBy { it.epochMillis }
        )
    }
}
