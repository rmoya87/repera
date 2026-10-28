import Foundation

/// Catálogo tipado de funcionalidades sujetas a la política comercial.
public enum ReperaFeature: String, Sendable, CaseIterable, Identifiable, Codable {
    case unlimitedRoutines
    case unlimitedCustomExercises
    case unlimitedBoardScans
    case exerciseFullHistory
    case exerciseEvolution
    case historicalWODResults
    case wodResultComparisons
    case advancedProgress
    case advancedMuscleAnalysis
    case advancedStrengthProgression
    case advancedReports
    case progressPeriodBeyondWeek

    public var id: String { rawValue }

    /// Periodos de Progreso que requieren Pro (Gratis = solo `.week`).
    public static func requiresPro(for range: ProgressTimeRange) -> Bool {
        range != .week
    }
}

/// Límites cuantitativos del plan gratuito (única fuente de verdad numérica).
public enum FreePlanLimits: Sendable {
    public static let maxLibraryRoutines = 3
    /// Límite independiente de favoritos (rutinas marcadas y deportes de Comenzar).
    public static let maxFavoriteItems = 3
    public static let maxCustomExercises = 5
    public static let maxBoardScansPerMonth = 4
}

/// Origen tipado del paywall (contexto comercial, no UI).
public enum PaywallContext: String, Sendable, Codable, Hashable {
    case routinesLimit
    case customExercisesLimit
    case boardScansLimit
    case exerciseEvolution
    case exerciseHistory
    case wodHistory
    case progress
    case muscleAnalysis
    case advancedProgression
    case settings
    case onboarding
    case generic
}
