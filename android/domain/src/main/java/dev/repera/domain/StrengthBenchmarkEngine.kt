package dev.repera.domain

/** Competition percentile reference; never a percentile of the general population. */
enum class StrengthBenchmarkLift { SQUAT, BENCH_PRESS, DEADLIFT }
enum class StrengthBenchmarkSex { FEMALE, MALE }
enum class StrengthBenchmarkEquipment { RAW, WRAPS, SINGLE_PLY, MULTI_PLY }

/** Amateur = gym seed / Repera aggregates; Elite = competition meets. */
enum class StrengthReferenceFrame {
    AMATEUR, ELITE;

    val allowedSources: Set<String>
        get() = when (this) {
            AMATEUR -> setOf("SymmetricStrength")
            ELITE -> setOf("OpenPowerlifting")
        }

    val wire: String
        get() = when (this) {
            AMATEUR -> "amateur"
            ELITE -> "elite"
        }

    companion object {
        fun fromWire(raw: String?): StrengthReferenceFrame =
            when (raw) {
                "elite" -> ELITE
                else -> AMATEUR
            }
    }
}

data class StrengthBenchmarkCohort(
    val lift: StrengthBenchmarkLift,
    val sex: StrengthBenchmarkSex,
    val equipment: StrengthBenchmarkEquipment,
    val ageMin: Int,
    val ageMax: Int,
    val bodyWeightMinKg: Double,
    val bodyWeightMaxKg: Double
) {
    fun matches(lift: StrengthBenchmarkLift, sex: StrengthBenchmarkSex,
                equipment: StrengthBenchmarkEquipment, age: Int, bodyWeightKg: Double): Boolean =
        this.lift == lift && this.sex == sex && this.equipment == equipment &&
            age in ageMin..ageMax && bodyWeightKg >= bodyWeightMinKg &&
            bodyWeightKg < bodyWeightMaxKg
}

data class StrengthBenchmarkQuantile(val percentile: Double, val weightKg: Double)
data class StrengthBenchmarkDistribution(
    val cohort: StrengthBenchmarkCohort,
    val source: String,
    val sourceRevision: String,
    val sampleCount: Int,
    val quantiles: List<StrengthBenchmarkQuantile>
)
data class StrengthBenchmarkResult(
    val percentile: Double,
    val sampleCount: Int,
    val source: String,
    val sourceRevision: String,
    val ageSpecific: Boolean
)

object StrengthBenchmarkLiftResolver {
    fun liftForExerciseName(name: String): StrengthBenchmarkLift? = when (
        name.trim().lowercase()
    ) {
        "sentadilla", "sentadilla trasera", "back squat", "barbell back squat" ->
            StrengthBenchmarkLift.SQUAT
        "press banca", "press de banca", "bench press", "barbell bench press" ->
            StrengthBenchmarkLift.BENCH_PRESS
        "peso muerto", "peso muerto convencional", "deadlift", "conventional deadlift" ->
            StrengthBenchmarkLift.DEADLIFT
        else -> null
    }

    fun wire(lift: StrengthBenchmarkLift): String = when (lift) {
        StrengthBenchmarkLift.SQUAT -> "squat"
        StrengthBenchmarkLift.BENCH_PRESS -> "benchPress"
        StrengthBenchmarkLift.DEADLIFT -> "deadlift"
    }
}

/** Anonymized bands for opt-in Amateur contributions (no exact age/weight published). */
object StrengthContributionBands {
    val bodyWeightClasses: List<Pair<Double, Double>> = listOf(
        0.0 to 59.0001, 59.0001 to 66.0001, 66.0001 to 74.0001, 74.0001 to 83.0001,
        83.0001 to 93.0001, 93.0001 to 105.0001, 105.0001 to 120.0001, 120.0 to 400.0
    )

    fun ageBand(age: Int): String? = if (age in 14..100) "14-100" else null

    fun bodyWeightBand(kg: Double): String? {
        if (!kg.isFinite() || kg <= 0) return null
        val band = bodyWeightClasses.firstOrNull { kg >= it.first && kg < it.second } ?: return null
        return "${band.first}-${band.second}"
    }
}

object StrengthBenchmarkEngine {
    const val MINIMUM_SAMPLE_COUNT = 100

    /** Positions a 1RM-equivalent against competition quantiles. The UI must
     * label an estimated e1RM explicitly and never imply an official lift. */
    fun compareCompetitionOneRepMax(
        weightKg: Double, lift: StrengthBenchmarkLift, sex: StrengthBenchmarkSex,
        equipment: StrengthBenchmarkEquipment, age: Int, bodyWeightKg: Double,
        distributions: List<StrengthBenchmarkDistribution>,
        frame: StrengthReferenceFrame = StrengthReferenceFrame.AMATEUR
    ): StrengthBenchmarkResult? {
        if (!weightKg.isFinite() || weightKg <= 0 || !bodyWeightKg.isFinite() ||
            bodyWeightKg <= 0 || age !in 14..100) return null
        val allowed = frame.allowedSources
        val eligible = distributions.filter {
            it.cohort.matches(lift, sex, equipment, age, bodyWeightKg)
        }
        val candidates = eligible.filter {
            it.sampleCount >= MINIMUM_SAMPLE_COUNT && it.source in allowed &&
                it.sourceRevision.isNotBlank() && it.quantiles.size >= 2
        }
        val minSpan = candidates.minOfOrNull { it.cohort.ageMax - it.cohort.ageMin } ?: return null
        val narrow = candidates.filter { it.cohort.ageMax - it.cohort.ageMin == minSpan }
        // Prefer larger samples, then newer revision (Repera opt-in can supersede seed).
        val reference = narrow.maxWithOrNull(
            compareBy<StrengthBenchmarkDistribution> { it.sampleCount }
                .thenBy { it.sourceRevision }
        ) ?: return null
        val points = reference.quantiles.sortedBy { it.percentile }
        if (points.any { !it.percentile.isFinite() || !it.weightKg.isFinite() ||
                it.percentile !in 0.0..100.0 || it.weightKg <= 0 } ||
            points.zipWithNext().any { (a, b) ->
                a.percentile >= b.percentile || a.weightKg >= b.weightKg
            }) return null
        if (weightKg < points.first().weightKg || weightKg > points.last().weightKg) return null
        for ((lower, upper) in points.zipWithNext()) {
            if (weightKg !in lower.weightKg..upper.weightKg) continue
            val fraction = (weightKg - lower.weightKg) / (upper.weightKg - lower.weightKg)
            return StrengthBenchmarkResult(
                lower.percentile + fraction * (upper.percentile - lower.percentile),
                reference.sampleCount, reference.source, reference.sourceRevision,
                reference.cohort.ageMin == reference.cohort.ageMax
            )
        }
        return null
    }
}
