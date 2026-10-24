package dev.repera.domain

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.round

/**
 * Cálculo orientativo y determinista de recuperación. No diagnostica,
 * confirma ovulación, predice fertilidad ni altera resultados deportivos.
 * Port 1:1 de RecoveryEngine.swift (iOS).
 */
object RecoveryEngine {

    enum class CyclePhase(val wire: String) {
        MENSTRUAL("menstrual"), FOLLICULAR("follicular"),
        OVULATORY("ovulatory"), LUTEAL("luteal"), UNKNOWN("unknown")
    }

    /** Señales diarias observadas de salud. null = no disponible,
     *  NUNCA cero ni saludable. */
    data class DailyVitals(
        val day: LocalDate,
        val hrvMilliseconds: Double? = null,
        val restingHeartRateBpm: Double? = null,
        val respiratoryRateBpm: Double? = null,
        val oxygenSaturationPercent: Double? = null,
        val wristTemperatureCelsius: Double? = null,
        val heartRateRecoveryBpm: Double? = null
    )

    data class VitalContext(
        val penalty: Double,
        val calibratedSignals: Int,
        val notes: List<String>
    )

    /** Calibra cada señal aceptada contra ≥7 días distintos previos en los
     *  28 anteriores. Ignora muestras ausentes o inválidas. */
    fun vitalContext(at: LocalDate, history: List<DailyVitals>): VitalContext {
        val previous = history.filter {
            it.day.isBefore(at) && !it.day.isBefore(at.minusDays(28))
        }
        val today = history.lastOrNull { it.day == at }
            ?: return VitalContext(0.0, 0, emptyList())

        fun baseline(select: (DailyVitals) -> Double?,
                     valid: ClosedFloatingPointRange<Double>): Double? {
            val values = previous.mapNotNull { row ->
                val v = select(row)
                if (v != null && v.isFinite() && v in valid) row.day to v else null
            }
            // Siete días naturales distintos, no siete mediciones del reloj.
            if (values.map { it.first }.toSet().size < 7) return null
            val sorted = values.map { it.second }.sorted()
            val n = sorted.size
            return if (n % 2 == 0) (sorted[n / 2 - 1] + sorted[n / 2]) / 2
            else sorted[n / 2]
        }

        var penalty = 0.0
        var calibrated = 0
        val notes = mutableListOf<String>()
        val hrv = today.hrvMilliseconds
        if (hrv != null && hrv in 5.0..300.0) {
            val base = baseline({ it.hrvMilliseconds }, 5.0..300.0)
            if (base != null && base > 0) {
                calibrated += 1
                if (hrv < base * 0.70) {
                    penalty += 0.9
                    notes.add("VFC considerablemente inferior a tu referencia")
                } else if (hrv < base * 0.85) {
                    penalty += 0.45
                    notes.add("VFC inferior a tu referencia")
                }
            }
        }
        val rhr = today.restingHeartRateBpm
        if (rhr != null && rhr in 30.0..130.0) {
            val base = baseline({ it.restingHeartRateBpm }, 30.0..130.0)
            if (base != null) {
                calibrated += 1
                if (rhr - base >= 10) {
                    penalty += 0.85
                    notes.add("Pulso en reposo claramente elevado")
                } else if (rhr - base >= 5) {
                    penalty += 0.45
                    notes.add("Pulso en reposo elevado")
                }
            }
        }
        val rr = today.respiratoryRateBpm
        if (rr != null && rr in 6.0..40.0) {
            val base = baseline({ it.respiratoryRateBpm }, 6.0..40.0)
            if (base != null && base > 0) {
                calibrated += 1
                if (rr > base * 1.20) {
                    penalty += 0.4
                    notes.add("Respiración superior a tu referencia")
                }
            }
        }
        // SpO2, temperatura de muñeca y recuperación de FC a 1 min solo se
        // presentan como contexto: distintos dispositivos pueden confundirlos.
        return VitalContext(min(1.8, penalty), calibrated, notes)
    }

    /** Puntuación SOLO del sueño observado; nunca se suma al score del entreno. */
    fun sleepIndex(hours: Double?, recentAverage: Double?): Int? {
        if (hours == null || !hours.isFinite() || hours <= 0) return null
        val baseline = if (recentAverage != null && recentAverage.isFinite() &&
            recentAverage > 0) recentAverage else 8.0
        val target = max(7.0, min(9.0, baseline))
        return (100 * min(max(0.0, hours / target), 1.0)).let { kotlin.math.round(it).toInt() }
    }

    /** Entrenos de Salud no vinculados a una sesión de Repera. */
    data class ObservedActivity(
        val epochMillis: Long,
        val durationMinutes: Double,
        val isCardio: Boolean
    )

    enum class TrainingReadinessAdvice(val label: String) {
        USUAL("Entreno habitual según sensaciones"),
        MODERATE("Modera carga e intensidad"),
        REST("Prioriza descanso o actividad suave")
    }

    data class TrainingReadiness(
        val score: Double,
        val advice: TrainingReadinessAdvice,
        val sleepContribution: Double,
        val fatiguePenalty: Double,
        val trainingCount: Int,
        val physiologicalPenalty: Double = 0.0,
        val calibratedVitalSignals: Int = 0,
        val vitalNotes: List<String> = emptyList(),
        val cardioMinutes48h: Double? = null
    )

    /**
     * Estimación de disposición para entrenar. Requiere sueño observado y
     * actividad finalizada en los últimos siete días; jamás inventa cero
     * esfuerzo sin registros. Los workouts llegan como StatsWorkout con
     * epochMillis = momento de finalización.
     */
    fun trainingReadiness(
        nowMillis: Long,
        sleepHours: Double?,
        recentAverageSleepHours: Double?,
        workouts: List<StatsWorkout>,
        vitalHistory: List<DailyVitals> = emptyList(),
        observedActivities: List<ObservedActivity> = emptyList(),
        zone: ZoneId = ZoneId.systemDefault()
    ): TrainingReadiness? {
        if (sleepHours == null || !sleepHours.isFinite() || sleepHours <= 0) return null
        val sleep = sleepIndex(sleepHours, recentAverageSleepHours) ?: return null

        val sevenDays = 7L * 24 * 3_600_000
        val twoDays = 48L * 3_600_000
        val fourDays = 96L * 3_600_000
        val recent = workouts.filter {
            val age = nowMillis - it.epochMillis
            it.finished && age in 0..sevenDays
        }
        val recentExternal = observedActivities.filter {
            val age = nowMillis - it.epochMillis
            age in 0..sevenDays && it.durationMinutes.isFinite() && it.durationMinutes > 0
        }
        if (recent.isEmpty() && recentExternal.isEmpty()) return null

        // Solo sesiones ya acabadas; mismo motor del mapa corporal.
        val stimulusWorkouts = recent.map { workout ->
            MuscleStimulusWorkout(workout.epochMillis, workout.exercises.map { ex ->
                MuscleStimulusExercise(
                    sportTag = if (ex.isMobility) "Movilidad" else null,
                    muscleGroup = ex.muscleGroup,
                    sets = ex.sets.map {
                        MuscleStimulusSet(it.reps, it.isWarmup, it.rir,
                            it.weightKg, it.durationSeconds,
                            it.quantityUnit != null)
                    })
            })
        }
        val retained = MuscleMapEngine.retainedLoad(stimulusWorkouts,
            nowMillis = nowMillis)
        val mainGroups = retained.values.sortedDescending().take(3)
        val musclePressure = if (mainGroups.isEmpty()) 0.0 else mainGroups.average()
        var minutes48h = 0.0
        var minutes96h = 0.0
        for (workout in recent) {
            val age = nowMillis - workout.epochMillis
            val minutes = min(180.0, max(0.0, workout.durationMinutes))
            if (age <= fourDays) minutes96h += minutes
            if (age <= twoDays) minutes48h += minutes
        }
        var cardioMinutes48h = 0.0
        for (activity in recentExternal) {
            val age = nowMillis - activity.epochMillis
            val minutes = min(180.0, activity.durationMinutes)
            if (age <= fourDays) minutes96h += minutes
            if (age <= twoDays) {
                minutes48h += minutes
                if (activity.isCardio) cardioMinutes48h += minutes
            }
        }
        // Un WOD con solo duración sigue representando esfuerzo real.
        val durationPressure = 0.55 * min(1.0, minutes48h / 120.0) +
            0.45 * min(1.0, minutes96h / 240.0)
        val muscleLoad = min(1.0, musclePressure / 0.95)
        val hasMeasuredLoad = musclePressure > 0 || minutes96h > 0
        if (!hasMeasuredLoad) return null
        val load = if (musclePressure > 0)
            0.7 * muscleLoad + 0.3 * durationPressure
        else durationPressure
        val sleepContribution = (sleep / 10.0 - 7.0) * 0.45
        val penalty = 3.5 * load
        val today = Instant.ofEpochMilli(nowMillis).atZone(zone).toLocalDate()
        val vitals = vitalContext(today, vitalHistory)
        var score = max(0.0, min(10.0, 7.5 + sleepContribution - penalty - vitals.penalty))
        // Una noche corta no debe catalogarse «lista».
        if (sleepHours < 6) score = min(score, 5.0)
        score = round(score)
        val advice = if (score >= 7.5) TrainingReadinessAdvice.USUAL
        else if (score >= 5.5) TrainingReadinessAdvice.MODERATE
        else TrainingReadinessAdvice.REST
        return TrainingReadiness(
            score = score,
            advice = advice,
            sleepContribution = sleepContribution,
            fatiguePenalty = penalty,
            trainingCount = recent.size + recentExternal.size,
            physiologicalPenalty = vitals.penalty,
            calibratedVitalSignals = vitals.calibratedSignals,
            vitalNotes = vitals.notes,
            cardioMinutes48h = if (recentExternal.any {
                    it.isCardio && nowMillis - it.epochMillis <= twoDays
                }) cardioMinutes48h else null
        )
    }

    /** Estima una fase únicamente a partir del historial de menstruaciones. */
    fun cyclePhase(flowDays: List<LocalDate>, on: LocalDate): CyclePhase {
        val days = flowDays.toSortedSet().toList()
        val latest = days.lastOrNull() ?: return CyclePhase.UNKNOWN
        if (latest.isAfter(on)) return CyclePhase.UNKNOWN
        if (days.any { it == on }) return CyclePhase.MENSTRUAL
        val starts = mutableListOf<LocalDate>()
        for (day in days) {
            val last = starts.lastOrNull()
            if (last != null && day.toEpochDay() - last.toEpochDay() <= 10) continue
            starts.add(day)
        }
        if (starts.size < 3) return CyclePhase.UNKNOWN
        val current = starts.last()
        val intervals = starts.zipWithNext { a, b -> b.toEpochDay() - a.toEpochDay() }
        if (intervals.size < 2) return CyclePhase.UNKNOWN
        if (!intervals.all { it in 21..40 }) return CyclePhase.UNKNOWN
        if ((intervals.max() - intervals.min()) > 7) return CyclePhase.UNKNOWN
        val elapsed = on.toEpochDay() - current.toEpochDay()
        val meanLength = intervals.average()
        if (elapsed < 0 || elapsed >= round(meanLength).toLong()) return CyclePhase.UNKNOWN
        val midpoint = round(meanLength).toLong() - 14
        if (abs(elapsed - midpoint) <= 1) return CyclePhase.OVULATORY
        return if (elapsed < midpoint) CyclePhase.FOLLICULAR else CyclePhase.LUTEAL
    }
}

/** Una muestra de fase de sueño observada (Health Connect / HealthKit). */
data class SleepStageSample(
    val startMillis: Long,
    val endMillis: Long,
    /** DEEP, REM, LIGHT, AWAKE u OTRO (unspecified cuenta como dormido total). */
    val stage: String,
    val source: String
)

data class RecoverySleepNight(
    val day: LocalDate,
    val hours: Double,
    val deepHours: Double,
    val remHours: Double
)

/**
 * Combina muestras de fases en noches. Port de
 * HealthRecoveryStore.combineSleep (HealthRecovery.swift): agrupa por la
 * medianoche posterior al punto medio de cada muestra, elige la fuente con
 * más fases específicas (desempate por más unión temporal) y une intervalos.
 */
fun combineSleepNights(
    samples: List<SleepStageSample>,
    zone: ZoneId = ZoneId.systemDefault()
): List<RecoverySleepNight> {
    val stages = setOf("LIGHT", "REM", "DEEP", "OTRO")
    data class Segment(val start: Long, val end: Long,
                       val stage: String, val source: String)
    val grouped = mutableMapOf<LocalDate, MutableList<Segment>>()
    for (sample in samples) {
        if (sample.stage !in stages || sample.endMillis <= sample.startMillis) continue
        val midpoint = sample.startMillis + (sample.endMillis - sample.startMillis) / 2
        val night = Instant.ofEpochMilli(midpoint + 12L * 3_600_000)
            .atZone(zone).toLocalDate()
        grouped.getOrPut(night) { mutableListOf() }
            .add(Segment(sample.startMillis, sample.endMillis,
                sample.stage, sample.source))
    }
    fun unionMillis(values: List<Segment>): Long {
        val ordered = values.sortedBy { it.start }
        var end: Long? = null
        var total = 0L
        for (part in ordered) {
            val previous = end
            if (previous != null && previous > part.start) {
                if (part.end > previous) {
                    total += part.end - previous
                    end = part.end
                }
            } else {
                total += part.end - part.start
                end = part.end
            }
        }
        return total
    }
    return grouped.mapNotNull { (night, all) ->
        val bySource = all.groupBy { it.source }
        val segments = bySource.values.maxWithOrNull(compareBy(
            { segs: List<Segment> -> segs.count { it.stage != "OTRO" } },
            { segs: List<Segment> -> unionMillis(segs) }
        )) ?: return@mapNotNull null
        val hours = min(24.0, unionMillis(segments) / 3_600_000.0)
        if (hours < 0.25) return@mapNotNull null
        RecoverySleepNight(
            day = night, hours = hours,
            deepHours = unionMillis(segments.filter { it.stage == "DEEP" }) / 3_600_000.0,
            remHours = unionMillis(segments.filter { it.stage == "REM" }) / 3_600_000.0
        )
    }.sortedBy { it.day }
}
