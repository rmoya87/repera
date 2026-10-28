package dev.repera.domain

import java.util.UUID

/**
 * Port 1:1 de SessionReview.swift + el subconjunto de Models.swift que el
 * motor v11 necesita (VerifiedSessionReviewEngine). Los ids son String con
 * formato UUID (mismo wire que el JSON compartido iOS/Android).
 */

// MARK: - Modelo de sesión (subconjunto del engine)

enum class ExerciseLoggingStyle(val wire: String) {
    LOAD_AND_REPS("loadAndReps"),
    REPS_ONLY("repsOnly"),
    REPS_AND_TIME("repsAndTime"),
    MACHINE_WORK("machineWork")
}

enum class ExerciseLoadField(val wire: String) {
    NONE("none"), WEIGHT_KG("weightKg"), DEFICIT_CM("deficitCm")
}

/** Exercise (iOS) reducido a lo que equivalencia y valoración consultan. */
data class ReviewExercise(
    val id: String,
    val name: String,
    val equipment: String? = null,
    val catalogId: String? = null,
    val loggingStyle: ExerciseLoggingStyle,
    val loadField: ExerciseLoadField
)

data class ReviewLoggedSet(
    val reps: Int,
    val weightKg: Double? = null,
    val durationSeconds: Int? = null,
    val isWarmup: Boolean = false,
    val rir: Double? = null
)

data class ReviewPlannedSet(
    val targetReps: Int,
    val targetWeightKg: Double? = null
)

data class ReviewSessionExercise(
    val id: String,
    val exercise: ReviewExercise,
    val plannedSets: List<ReviewPlannedSet>,
    val loggedSets: List<ReviewLoggedSet>,
    val adaptedReps: Int? = null,
    val adaptedWeightKg: Double? = null,
    val blockId: String? = null,
    val wodFormat: WodFormat? = null,
    val blockTimeCapMinutes: Int? = null,
    val blockIntervalSeconds: Int? = null
) {
    /** Port de SessionExercise.hasWODScaling (Models.swift:1651). */
    val hasWODScaling: Boolean
        get() {
            if (adaptedReps != null && adaptedReps != plannedSets.firstOrNull()?.targetReps)
                return true
            if (adaptedWeightKg != null) {
                val rxKg = plannedSets.firstOrNull()?.targetWeightKg ?: return true
                if (kotlin.math.abs(adaptedWeightKg - rxKg) >= 0.05) return true
            }
            return false
        }
}

data class ReviewWodMovement(
    val name: String,
    val reps: Int? = null,
    val repScheme: List<Int>? = null,
    val distanceMeters: Int? = null,
    val calories: Int? = null,
    val weightMaleKg: Double? = null,
    val weightFemaleKg: Double? = null,
    val isRest: Boolean = false,
    val scaleAlternative: String? = null
)

data class ReviewRoutineBlock(
    val id: String,
    val title: String,
    val movements: List<ReviewWodMovement>,
    val wodFormat: WodFormat? = null,
    val timeCapMinutes: Int? = null,
    val emomIntervalSeconds: Int? = null,
    val rounds: Int? = null
)

data class ReviewWodBlockResult(
    val id: String,
    val format: WodFormat? = null,
    val totalReps: Int? = null,
    val elapsedSeconds: Int? = null,
    val roundsCompleted: Int? = null,
    val wodTemplateId: String? = null
)

data class ReviewWorkoutSession(
    val id: String,
    val title: String,
    val finished: Boolean,
    val finishedAtMillis: Long?,
    val exercises: List<ReviewSessionExercise>,
    val wodResults: List<ReviewWodBlockResult>,
    val routineBlocks: List<ReviewRoutineBlock>?
)

// MARK: - Modelo de valoración (SessionReview.swift)

enum class AthleteLevel(val wire: String, val label: String) {
    BEGINNER("beginner", "Principiante"), INTERMEDIATE("intermediate", "Intermedio"),
    ADVANCED("advanced", "Avanzado"), ELITE("elite", "Élite");
    companion object { fun fromWire(w: String) = entries.firstOrNull { it.wire == w } }
}

enum class MovementVerdict(val wire: String, val label: String) {
    GOOD("good", "Bien"), IMPROVE("improve", "Mejorable"), CAUTION("caution", "Cuidado");
    companion object { fun fromWire(w: String) = entries.firstOrNull { it.wire == w } }
}

/** Origen de la nota 1–10 (rendimiento, no ranking social). */
enum class ScoreBasis(val wire: String, val blurbLabel: String) {
    CATALOG_BANDS("catalogBands", "vs estándar de catálogo"),
    MOVEMENT_PACE("movementPace", "vs ritmos de catálogo por movimiento"),
    TYPICAL_TIME("typicalTime", "vs tiempo típico"),
    FORMAT_HEURISTIC("formatHeuristic", "estimación por formato"),
    EQUIVALENT_HISTORY("equivalentHistory", "vs historial en movimientos similares"),
    SESSION_ESTIMATE("sessionEstimate", "estimación de la sesión"),
    PERSONAL_HISTORY("personalHistory", "historial personal comparable");
    companion object { fun fromWire(w: String) = entries.firstOrNull { it.wire == w } }
}

data class MovementReview(
    val id: String = UUID.randomUUID().toString(),
    val exerciseId: String? = null,
    val name: String,
    val verdict: MovementVerdict,
    val detail: String,
    val comparedToName: String? = null,
    val performanceRatio: Double? = null
)

/** «Cumplimiento» mide cobertura del registro, nunca calidad, y no puntúa. */
enum class ReviewDimension(val wire: String, val title: String) {
    PERSONAL_PROGRESS("personalProgress", "Evolución personal"),
    ADHERENCE("adherence", "Cumplimiento"),
    WOD_PERFORMANCE("wodPerformance", "Rendimiento WOD");
    companion object { fun fromWire(w: String) = entries.firstOrNull { it.wire == w } }
}

data class ReviewIndicator(
    val dimension: ReviewDimension,
    /** nil = todavía sin mínimo de histórico. Nunca mostrar una nota inventada. */
    val score: Int?,
    val detail: String,
    val referenceSessions: Int = 0,
    /** 1: misma referencia; 2: mismo ejercicio en otra estructura; 3: estímulo calibrado. */
    val comparisonLevel: Int? = null
)

/** Informe post-entreno (WOD + movimientos). La nota queda acotada 1..10
 *  como en el init/decodificador iOS. */
data class SessionReview private constructor(
    val overallScore: Int,
    val level: AthleteLevel? = null,
    val headline: String,
    val vsHistorySummary: String? = null,
    val vsStandardSummary: String? = null,
    val keepTips: List<String> = emptyList(),
    val improveTips: List<String> = emptyList(),
    val movements: List<MovementReview> = emptyList(),
    val wodTemplateId: String? = null,
    val scoreBasis: ScoreBasis? = null,
    val indicators: List<ReviewIndicator> = emptyList(),
    val evidenceCoverage: Double? = null,
    val confidenceLabel: String? = null
) {
    val levelLabel: String? get() = level?.label
    val scoreLabel: String get() = "$overallScore/10"

    companion object {
        operator fun invoke(
            overallScore: Int,
            level: AthleteLevel? = null,
            headline: String,
            vsHistorySummary: String? = null,
            vsStandardSummary: String? = null,
            keepTips: List<String> = emptyList(),
            improveTips: List<String> = emptyList(),
            movements: List<MovementReview> = emptyList(),
            wodTemplateId: String? = null,
            scoreBasis: ScoreBasis? = null,
            indicators: List<ReviewIndicator> = emptyList(),
            evidenceCoverage: Double? = null,
            confidenceLabel: String? = null
        ) = SessionReview(
            overallScore.coerceIn(1, 10), level, headline, vsHistorySummary,
            vsStandardSummary, keepTips, improveTips, movements, wodTemplateId,
            scoreBasis, indicators, evidenceCoverage, confidenceLabel)
    }
}

// MARK: - PlateMath (subconjunto)

object PlateMath {
    /** Port de PlateMath.epleyOneRM (PlateMath.swift:188). */
    fun epleyOneRM(weightKg: Double, reps: Int): Double {
        if (weightKg <= 0 || reps <= 0) return 0.0
        return weightKg * (1 + reps / 30.0)
    }
}
