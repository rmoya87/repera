package dev.repera.mobile

import dev.repera.domain.HeartRatePlotPoint
import dev.repera.domain.MuscleTaxonomy
import dev.repera.domain.ProgressDayPoint
import dev.repera.domain.ProgressPreparedCharts
import dev.repera.domain.ProgressSeriesGranularity
import dev.repera.domain.ProgressTimeRange
import dev.repera.domain.RecoveryEngine
import dev.repera.domain.RecoverySleepNight
import java.time.LocalDate
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * Formas fijas de ejemplo (teaser Free + revisión visual de gráficas).
 * Nunca deriva valores de mediciones privadas.
 */
internal object ProgressPreview {
    fun charts(today: LocalDate, monday: Boolean): ProgressPreparedCharts {
        val profile = listOf(108.0, 124.0, 118.0, 132.0, 115.0, 128.0, 112.0)
        val hr = (0..6).map { i ->
            val avg = profile[i] + 3 * sin(i * 1.8)
            HeartRatePlotPoint(
                today.minusDays(6L - i),
                (avg - 14 - 8 * abs(sin(i * 1.2 + 0.5))).roundToInt().toDouble(),
                avg.roundToInt().toDouble(),
                (avg + 26 + 14 * abs(cos(i * 1.4 + 0.2))).roundToInt().toDouble()
            )
        }
        val kcal = (0..6).map { i ->
            ProgressDayPoint(
                today.minusDays(6L - i),
                max(
                    200.0,
                    (listOf(320, 610, 480, 720, 390, 680, 350)[i] + 40 * sin(i * 2.1))
                        .roundToInt()
                        .toDouble()
                )
            )
        }
        return ProgressPreparedCharts(
            ProgressTimeRange.WEEK,
            monday,
            hr,
            kcal,
            kcal.sumOf { it.value },
            hr.map { it.avgBpm }.average(),
            ProgressSeriesGranularity.DAY,
            caloriesDailyAverage = kcal.sumOf { it.value } / kcal.size,
            previousCaloriesDailyAverage = 500.0
        )
    }

    fun weight(today: LocalDate) = (0..6).map { i ->
        ProgressDayPoint(
            today.minusDays(6L - i),
            ((listOf(75.1, 74.6, 74.9, 74.2, 74.7, 74.0, 74.4)[i] + 0.15 * sin(i * 2.3)) * 10)
                .roundToInt() / 10.0
        )
    }

    fun sessionScores(today: LocalDate) = (0..6).map { i ->
        ProgressDayPoint(today.minusDays(6L - i), listOf(6.0, 7.0, 7.0, 8.0, 6.0, 8.0, 9.0)[i])
    }

    /** Heatmap 0…4 para 14 días (franja / rejilla según rango). */
    fun heatmap(today: LocalDate, days: Int = 14): List<Pair<LocalDate, Int>> {
        val levels = listOf(0, 1, 2, 3, 4, 2, 1, 3, 4, 2, 0, 3, 4, 1)
        return (0 until days).map { i ->
            today.minusDays((days - 1 - i).toLong()) to levels[i % levels.size]
        }
    }

    fun muscleLoads(): Map<String, Double> =
        MuscleTaxonomy.muscles.mapIndexed { i, slug ->
            slug to (3.0 + (i % 5) * 2.0 + (i % 3))
        }.toMap()

    fun muscleFatigue(): Map<String, Double> =
        muscleLoads().mapValues { (_, v) -> (v * 0.55).coerceIn(0.0, 10.0) }

    /** Nombres reales del catálogo: al pulsar se resuelve por nombre → ficha. */
    fun chartExercises(): List<ProgressExerciseRow> = listOf(
        ProgressExerciseRow("Sentadilla", "Sentadilla", 120.0, System.currentTimeMillis()),
        ProgressExerciseRow("Press banca", "Press banca", 85.0, System.currentTimeMillis() - 86_400_000),
        ProgressExerciseRow("Peso muerto", "Peso muerto", 140.0, System.currentTimeMillis() - 172_800_000)
    )

    fun recoveryTrend(today: LocalDate) = (0..6).map { i ->
        ProgressDayPoint(today.minusDays(6L - i), listOf(5.0, 6.0, 7.0, 6.0, 8.0, 7.0, 9.0)[i])
    }

    fun recoveryNights(today: LocalDate) = (0..6).map { i ->
        RecoverySleepNight(
            day = today.minusDays(6L - i),
            hours = listOf(6.8, 7.2, 7.5, 6.5, 7.8, 7.1, 8.0)[i],
            deepHours = listOf(1.2, 1.4, 1.5, 1.0, 1.6, 1.3, 1.7)[i],
            remHours = listOf(1.5, 1.6, 1.8, 1.4, 1.9, 1.7, 2.0)[i]
        )
    }

    fun recoveryVitals(today: LocalDate) = (0..6).map { i ->
        RecoveryEngine.DailyVitals(
            day = today.minusDays(6L - i),
            hrvMilliseconds = listOf(42.0, 48.0, 45.0, 51.0, 47.0, 53.0, 49.0)[i],
            restingHeartRateBpm = listOf(58.0, 56.0, 57.0, 55.0, 56.0, 54.0, 55.0)[i],
            respiratoryRateBpm = listOf(14.0, 13.5, 14.2, 13.8, 14.0, 13.6, 13.9)[i],
            oxygenSaturationPercent = 97.0 + (i % 2) * 0.5,
            wristTemperatureCelsius = 36.4 + i * 0.02
        )
    }

    fun recoveryReadiness() = RecoveryEngine.TrainingReadiness(
        score = 7.4,
        advice = RecoveryEngine.TrainingReadinessAdvice.USUAL,
        sleepContribution = 0.8,
        fatiguePenalty = 0.1,
        trainingCount = 4
    )
}
