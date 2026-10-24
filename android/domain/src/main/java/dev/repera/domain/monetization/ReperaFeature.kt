package dev.repera.domain.monetization

import dev.repera.domain.ProgressTimeRange

/**
 * Catálogo tipado de funcionalidades sujetas a la política comercial.
 * Port 1:1 de ReperaFeature.swift.
 */
enum class ReperaFeature(val wire: String) {
    UNLIMITED_ROUTINES("unlimitedRoutines"),
    UNLIMITED_CUSTOM_EXERCISES("unlimitedCustomExercises"),
    UNLIMITED_BOARD_SCANS("unlimitedBoardScans"),
    EXERCISE_FULL_HISTORY("exerciseFullHistory"),
    EXERCISE_EVOLUTION("exerciseEvolution"),
    HISTORICAL_WOD_RESULTS("historicalWODResults"),
    WOD_RESULT_COMPARISONS("wodResultComparisons"),
    ADVANCED_PROGRESS("advancedProgress"),
    ADVANCED_MUSCLE_ANALYSIS("advancedMuscleAnalysis"),
    ADVANCED_STRENGTH_PROGRESSION("advancedStrengthProgression"),
    ADVANCED_REPORTS("advancedReports"),
    PROGRESS_PERIOD_BEYOND_WEEK("progressPeriodBeyondWeek");

    companion object {
        /** Periodos de Progreso que requieren Pro (Gratis = solo semana). */
        fun requiresPro(range: ProgressTimeRange): Boolean = range != ProgressTimeRange.WEEK
    }
}

/** Límites cuantitativos del plan gratuito (única fuente de verdad numérica). */
object FreePlanLimits {
    const val MAX_LIBRARY_ROUTINES = 3
    const val MAX_CUSTOM_EXERCISES = 5
    const val MAX_BOARD_SCANS_PER_MONTH = 4
}

/** Origen tipado del paywall (contexto comercial, no UI). */
enum class PaywallContext(val wire: String) {
    ROUTINES_LIMIT("routinesLimit"),
    CUSTOM_EXERCISES_LIMIT("customExercisesLimit"),
    BOARD_SCANS_LIMIT("boardScansLimit"),
    EXERCISE_EVOLUTION("exerciseEvolution"),
    EXERCISE_HISTORY("exerciseHistory"),
    WOD_HISTORY("wodHistory"),
    PROGRESS("progress"),
    MUSCLE_ANALYSIS("muscleAnalysis"),
    ADVANCED_PROGRESSION("advancedProgression"),
    SETTINGS("settings"),
    ONBOARDING("onboarding"),
    GENERIC("generic")
}
