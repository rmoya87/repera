package dev.repera.mobile

import android.content.Context
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.records.SkinTemperatureRecord
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.Record
import kotlin.reflect.KClass
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.HeartRateVariabilityRmssdRecord
import androidx.health.connect.client.records.RestingHeartRateRecord
import androidx.health.connect.client.records.MenstruationFlowRecord
import androidx.health.connect.client.records.MenstruationPeriodRecord
import androidx.health.connect.client.records.OvulationTestRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.RespiratoryRateRecord
import androidx.health.connect.client.records.OxygenSaturationRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateGroupByPeriodRequest
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.metadata.DataOrigin
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
    val vitals: List<dev.repera.domain.RecoveryEngine.DailyVitals>,
    val menstrualDays:List<LocalDate> = emptyList(),
    val positiveOvulationTests:List<LocalDate> = emptyList()
)

data class ExternalHealthHistoryEntry(val id:String,val title:String,val startMillis:Long,val endMillis:Long,val minutes:Double,val sourcePackage:String)

data class ExternalHealthDetail(val entry:ExternalHealthHistoryEntry,val heart:List<Pair<Long,Int>>,val activeKcal:Double?)

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
        val optionalVitalPermissions = setOf(
            HealthPermission.getReadPermission(RespiratoryRateRecord::class),
            HealthPermission.getReadPermission(OxygenSaturationRecord::class))
        /** Distancia por sesión (Apple workoutMovementMetrics). Se declara en el manifiesto pero NO entra en
         *  requestedPermissions(): no se pide automáticamente hasta que el propietario decida; solo se lee si ya está concedido. */
        val optionalMovementPermissions = setOf(HealthPermission.getReadPermission(DistanceRecord::class))
        val permissions = setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(ExerciseSessionRecord::class),
            HealthPermission.getWritePermission(ExerciseSessionRecord::class),
            // Apple 435f6992: workoutRoute en la autorizacion de escritura.
            HealthPermission.PERMISSION_WRITE_EXERCISE_ROUTE,
            HealthPermission.getReadPermission(
                HeartRateVariabilityRmssdRecord::class),
            HealthPermission.getReadPermission(RestingHeartRateRecord::class),
            HealthPermission.getReadPermission(WeightRecord::class),
            HealthPermission.getWritePermission(WeightRecord::class)
        )

        internal fun historyPermissionsIfAvailable(available:Boolean):Set<String> =
            if(available) setOf(HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY) else emptySet()

        fun hasReadablePermission(granted:Set<String>):Boolean = granted.any {it in permissions + optionalVitalPermissions + setOf(
            HealthPermission.getReadPermission(SleepSessionRecord::class),HealthPermission.getReadPermission(MenstruationFlowRecord::class),
            HealthPermission.getReadPermission(OvulationTestRecord::class),HealthPermission.getReadPermission(MenstruationPeriodRecord::class),
            HealthPermission.getReadPermission(SkinTemperatureRecord::class)) && it !in setOf(HealthPermission.getWritePermission(WeightRecord::class),HealthPermission.getWritePermission(ExerciseSessionRecord::class),HealthPermission.PERMISSION_WRITE_EXERCISE_ROUTE)}

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

    fun requestedPermissions():Set<String> {
        val settings=PrivateRecoverySettings(context)
        val skinPermission=if(available() && runCatching {HealthConnectClient.getOrCreate(context).features.getFeatureStatus(HealthConnectFeatures.FEATURE_SKIN_TEMPERATURE)==HealthConnectFeatures.FEATURE_STATUS_AVAILABLE}.getOrDefault(false) && settings.sleepEnabled()) setOf(HealthPermission.getReadPermission(SkinTemperatureRecord::class)) else emptySet()
        // Optional extension only. Refusal never disables already granted record reads.
        val historyPermission=historyPermissionsIfAvailable(available() && runCatching {
            HealthConnectClient.getOrCreate(context).features.getFeatureStatus(HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_HISTORY)==HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
        }.getOrDefault(false))
        return permissions + optionalVitalPermissions + skinPermission + historyPermission + (if(settings.sleepEnabled()) setOf(HealthPermission.getReadPermission(SleepSessionRecord::class)) else emptySet()) +
            (if(settings.cycleEnabled()) setOf(HealthPermission.getReadPermission(MenstruationFlowRecord::class),HealthPermission.getReadPermission(MenstruationPeriodRecord::class),HealthPermission.getReadPermission(OvulationTestRecord::class)) else emptySet())
    }

    fun available() = HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE

    suspend fun hasPermissions(): Boolean {
        if (!available()) return false
        val granted = HealthConnectClient.getOrCreate(context)
            .permissionController.getGrantedPermissions()
        return hasReadablePermission(granted)
    }

    suspend fun readToday(): TodayHealth = readDay(LocalDate.now())

    suspend fun readDay(day:LocalDate):TodayHealth {
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        val zone = ZoneId.systemDefault()
        val start = day.atStartOfDay(zone).toInstant()
        val now = minOf(day.plusDays(1).atStartOfDay(zone).toInstant(),Instant.now())
        if(start>=now) return TodayHealth(null,null)
        val metrics=buildSet {
            if(HealthPermission.getReadPermission(StepsRecord::class) in granted) add(StepsRecord.COUNT_TOTAL)
            if(HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class) in granted) add(ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL)
        }
        if(metrics.isEmpty()) return TodayHealth(null,null)
        val result = client.aggregate(
            AggregateRequest(
                metrics = metrics,
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
    /** Reads the linked record by id. Only Found or Unreadable are produced: the Health Connect error that
     *  means "record does not exist" was not verified on a device, so every failure is treated as unknown. */
    private suspend fun lookupLinkedRecord(recordId: String): dev.repera.domain.SessionHealthMatcher.LinkLookup = try {
        val client = HealthConnectClient.getOrCreate(context)
        if (!client.permissionController.getGrantedPermissions().contains(HealthPermission.getReadPermission(ExerciseSessionRecord::class)))
            dev.repera.domain.SessionHealthMatcher.LinkLookup.Unreadable
        else {
            val it = client.readRecord(ExerciseSessionRecord::class, recordId).record
            dev.repera.domain.SessionHealthMatcher.LinkLookup.Found(dev.repera.domain.SessionHealthMatcher.CandidateSession(
                id = it.metadata.id, startEpochMs = it.startTime.toEpochMilli(), endEpochMs = it.endTime.toEpochMilli(),
                packageName = it.metadata.dataOrigin.packageName, clientRecordId = it.metadata.clientRecordId,
                exerciseTypeKey = exerciseTypeKey(it.exerciseType),
                observedDurationMinutes = HealthWorkoutMinutes.measured(it.startTime.toEpochMilli(), it.endTime.toEpochMilli(),
                    it.segments.filter { segment -> segment.segmentType == androidx.health.connect.client.records.ExerciseSegment.EXERCISE_SEGMENT_TYPE_PAUSE }
                        .map { segment -> segment.startTime.toEpochMilli() to segment.endTime.toEpochMilli() })))
        }
    } catch (e: Exception) {
        if (e is kotlinx.coroutines.CancellationException) throw e
        dev.repera.domain.SessionHealthMatcher.LinkLookup.Unreadable
    }

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
                packageName = it.metadata.dataOrigin.packageName,
                clientRecordId=it.metadata.clientRecordId,
                exerciseTypeKey=exerciseTypeKey(it.exerciseType),
                observedDurationMinutes=HealthWorkoutMinutes.measured(it.startTime.toEpochMilli(),it.endTime.toEpochMilli(),
                    it.segments.filter {segment ->segment.segmentType==androidx.health.connect.client.records.ExerciseSegment.EXERCISE_SEGMENT_TYPE_PAUSE}
                        .map {segment ->segment.startTime.toEpochMilli() to segment.endTime.toEpochMilli()})
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
        // Persisted link first, read BY ID (Apple fetchWorkout(uuid)), so editing the session time does not
        // swap it for another record. Unreadable (no permission / transient error) never reassociates.
        if (sessionId != null && !linkedRecordId.isNullOrBlank()) {
            when (val r = dev.repera.domain.SessionHealthMatcher.resolveStoredLink(
                sessionId, linkedRecordId, lookupLinkedRecord(linkedRecordId), context.packageName)) {
                is dev.repera.domain.SessionHealthMatcher.LinkResolution.Use -> return r.record
                dev.repera.domain.SessionHealthMatcher.LinkResolution.KeepLinkUnresolved -> return null
                dev.repera.domain.SessionHealthMatcher.LinkResolution.FallBackToWindow -> {}
            }
        }
        val candidates = readSessionCandidates(startEpochMs, endEpochMs)
        return (dev.repera.domain.SessionHealthMatcher.associate(
            startEpochMs, endEpochMs, dev.repera.domain.SessionHealthMatcher.eligibleForSession(sessionId,candidates,context.packageName), context.packageName)
            as? dev.repera.domain.SessionHealthMatcher.Association.Matched)?.session
    }

    /** Exact provider ID is re-read before using its range/source. No window guessed from UI. */
    suspend fun readExternalDetail(expected:ExternalHealthHistoryEntry):ExternalHealthDetail? {
        if(!available()) return null
        val client=HealthConnectClient.getOrCreate(context)
        val granted=client.permissionController.getGrantedPermissions()
        if(HealthPermission.getReadPermission(ExerciseSessionRecord::class) !in granted) return null
        val record=client.readRecord(ExerciseSessionRecord::class,expected.id).record
        if(record.metadata.id!=expected.id || record.metadata.dataOrigin.packageName!=expected.sourcePackage ||
            record.startTime.toEpochMilli()!=expected.startMillis || record.endTime.toEpochMilli()!=expected.endMillis) return null
        val evidence=readSessionEvidence(expected.startMillis,expected.endMillis)
        // An exact external record does not grant ownership of another app's readings.
        val heart=evidence.heart.filter {it.originPackage==expected.sourcePackage}
        val series=(dev.repera.domain.SessionHealthMatcher.mergeHeartRate(heart) as? dev.repera.domain.SessionHealthMatcher.HeartMerge.Merged)?.series.orEmpty()
        val kcal=evidence.kcal.filter {it.originPackage==expected.sourcePackage && it.startMs>=expected.startMillis && it.endMs<=expected.endMillis}
            .sumOf {it.kcal}.takeIf {it.isFinite() && it>0}
        return ExternalHealthDetail(expected,series,kcal)
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
            durationMinutes = dev.repera.domain.SessionHealthMatcher.observedDurationMinutes(matched),
            sourceRecordId = matched.id
        )
    }

    /** Pasos y distancia de la sesión de Salud asociada (reglas de asociación idénticas a readSessionSample:
     *  sin asociación o ambigua no se lee nada). «Asociado» = mismo origen que la sesión asociada dentro de su rango;
     *  si no hay muestras de ese origen, solo se usa la ventana cuando UN ÚNICO origen aporta datos en el rango (`usesTimeWindow=true`); con varios orígenes no se suma ni se elige: sin dato (fail-closed).
     *  Cada lectura exige su permiso ya concedido; no se solicita ni se estima nada. */
    suspend fun readSessionMovement(startEpochMs: Long, endEpochMs: Long, linkedRecordId: String? = null,
                                    linkedSessionId: String? = null): dev.repera.domain.SessionMovement? {
        if (!available() || endEpochMs <= startEpochMs) return null
        val matched = matchedSession(linkedSessionId, startEpochMs, endEpochMs, linkedRecordId) ?: return null
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        val canSteps = HealthPermission.getReadPermission(StepsRecord::class) in granted
        val canDistance = HealthPermission.getReadPermission(DistanceRecord::class) in granted
        if (!canSteps && !canDistance) return null
        val range = TimeRangeFilter.between(Instant.ofEpochMilli(matched.startEpochMs), Instant.ofEpochMilli(matched.endEpochMs))
        suspend fun total(origins: Set<String>, steps: Boolean): Double? {
            val r = client.aggregate(AggregateRequest(setOf(if (steps) StepsRecord.COUNT_TOTAL else DistanceRecord.DISTANCE_TOTAL),
                range, origins.map { DataOrigin(it) }.toSet()))
            return if (steps) r[StepsRecord.COUNT_TOTAL]?.toDouble() else r[DistanceRecord.DISTANCE_TOTAL]?.inMeters
        }
        // Un origen por vez: nunca se suman apps distintas (pueden guardar los mismos pasos/distancia).
        suspend fun origins(steps: Boolean): Set<String> =
            if (steps) client.readAllRecords(StepsRecord::class, range).map { it.metadata.dataOrigin.packageName }.toSet()
            else client.readAllRecords(DistanceRecord::class, range).map { it.metadata.dataOrigin.packageName }.toSet()
        suspend fun figures(steps: Boolean): Pair<Double?, Double?> {
            val own = total(setOf(matched.packageName), steps)
            val others = origins(steps)
            val perOrigin = others.mapNotNull { o -> total(setOf(o), steps)?.let { o to it } }.toMap()
            return own to dev.repera.domain.SessionMovementMetrics.windowTotal(perOrigin)
        }
        val (ownSteps, winSteps) = if (canSteps) figures(true) else null to null
        val (ownDist, winDist) = if (canDistance) figures(false) else null to null
        return dev.repera.domain.SessionMovementMetrics.resolve(matched.exerciseTypeKey, ownSteps, winSteps, ownDist, winDist)
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

        val heartSamples=mutableListOf<Pair<Long,Double>>()
        if (granted.contains(HealthPermission.getReadPermission(HeartRateRecord::class))) {
            client.readAllRecords(HeartRateRecord::class,TimeRangeFilter.between(start,now)).forEach {record ->
                record.samples.filter {it.time>=start && it.time<=now}.forEach {heartSamples.add(it.time.toEpochMilli() to it.beatsPerMinute.toDouble())}
            }
        }

        val energyDays = mutableMapOf<LocalDate, Double>()
        if (granted.contains(HealthPermission.getReadPermission(
                ActiveCaloriesBurnedRecord::class))) {
            // Calendar buckets preserve 23/25-hour days and allocate intervals across midnight.
            // Ask Health Connect for its aggregate rather than summing overlapping raw sources.
            val response = client.aggregateGroupByPeriod(AggregateGroupByPeriodRequest(
                metrics=setOf(ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL),
                timeRangeFilter=TimeRangeFilter.between(start.atZone(zone).toLocalDateTime(),now.atZone(zone).toLocalDateTime()),
                timeRangeSlicer=java.time.Period.ofDays(1)))
            for (bucket in response) {
                bucket.result[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]?.inKilocalories
                    ?.takeIf {it.isFinite() && it>=0}?.let {energyDays[bucket.startTime.toLocalDate()]=it}
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
            heartRateDays = DailyHeartRates.points(heartSamples,zone),
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
        if (PrivateRecoverySettings(context).sleepEnabled() && granted.contains(HealthPermission.getReadPermission(
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
        val breathing=mutableListOf<Pair<Long,Double>>()
        if(HealthPermission.getReadPermission(RespiratoryRateRecord::class) in granted) {
            client.readAllRecords(RespiratoryRateRecord::class,TimeRangeFilter.between(start,now)).forEach {breathing.add(it.time.toEpochMilli() to it.rate)}
        }
        val oxygen=mutableListOf<Pair<Long,Double>>()
        if(HealthPermission.getReadPermission(OxygenSaturationRecord::class) in granted) {
            client.readAllRecords(OxygenSaturationRecord::class,TimeRangeFilter.between(start,now)).forEach {oxygen.add(it.time.toEpochMilli() to it.percentage.value)}
        }
        val wrist=mutableListOf<Pair<Long,Double>>()
        if(PrivateRecoverySettings(context).sleepEnabled() && HealthPermission.getReadPermission(SkinTemperatureRecord::class) in granted && client.features.getFeatureStatus(HealthConnectFeatures.FEATURE_SKIN_TEMPERATURE)==HealthConnectFeatures.FEATURE_STATUS_AVAILABLE) {
            client.readAllRecords(SkinTemperatureRecord::class,TimeRangeFilter.between(start,now)).forEach {record ->
                record.deltas.forEach {sample ->
                    dev.repera.domain.WristTemperature.observedCelsius(record.baseline?.inCelsius,sample.delta.inCelsius,
                        record.measurementLocation==SkinTemperatureRecord.MEASUREMENT_LOCATION_WRIST,sample.time.toEpochMilli(),stageSamples)?.let {wrist.add(sample.time.toEpochMilli() to it)}
                }
            }
        }
        val daysSet = (hrv + rest + breathing + oxygen + wrist).map {
            Instant.ofEpochMilli(it.first).atZone(zone).toLocalDate()
        }.toSortedSet()
        val vitals = daysSet.map { day ->
            dev.repera.domain.RecoveryEngine.DailyVitals(
                day = day,
                hrvMilliseconds = medianForDay(hrv, day, zone,
                    5.0..300.0, beforeMorning = true),
                restingHeartRateBpm = medianForDay(rest, day, zone,
                    30.0..130.0, beforeMorning = true),
                respiratoryRateBpm=medianForDay(breathing,day,zone,6.0..40.0,beforeMorning=true),
                oxygenSaturationPercent=medianForDay(oxygen,day,zone,0.0..100.0,beforeMorning=false),
                wristTemperatureCelsius=medianForDay(wrist,day,zone,25.0..42.0,beforeMorning=false))
        }
        val menstrualDays=mutableSetOf<LocalDate>()
        val positiveTests=mutableListOf<LocalDate>()
        if(PrivateRecoverySettings(context).cycleEnabled()) {
            val cycleStart=LocalDate.now(zone).minusDays(230).atStartOfDay(zone).toInstant()
            val filter=TimeRangeFilter.between(cycleStart,now)
            if(HealthPermission.getReadPermission(MenstruationFlowRecord::class) in granted) {
                client.readAllRecords(MenstruationFlowRecord::class,filter).forEach {menstrualDays.add(it.time.atZone(zone).toLocalDate())}
            }
            if(HealthPermission.getReadPermission(MenstruationPeriodRecord::class) in granted) {
                client.readAllRecords(MenstruationPeriodRecord::class,filter).forEach {record ->
                    menstrualDays.addAll(dev.repera.domain.observedMenstrualDays(record.startTime,record.endTime,zone))
                }
            }
            if(HealthPermission.getReadPermission(OvulationTestRecord::class) in granted) {
                client.readAllRecords(OvulationTestRecord::class,filter).filter {it.result==OvulationTestRecord.RESULT_POSITIVE}.forEach {positiveTests.add(it.time.atZone(zone).toLocalDate())}
            }
        }
        return RecoveryRead(nights = nights, vitals = vitals,menstrualDays=menstrualDays.sorted(),positiveOvulationTests=positiveTests.sorted())
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
    suspend fun saveBodyMass(kg: Double, epochMillis: Long, owner:String,stillAuthorized:()->Boolean = {true}) {
        require(kg.isFinite() && kg>0 && owner.isNotBlank())
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        require(granted.contains(HealthPermission.getWritePermission(
            WeightRecord::class))) { "Falta el permiso de escritura de peso" }
        val instant = Instant.ofEpochMilli(epochMillis)
        val offset = ZoneId.systemDefault().rules.getOffset(instant)
        check(stillAuthorized()) {"La cuenta cambió antes de guardar peso en Salud"}
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
