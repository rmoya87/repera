import Foundation
import ReperaDomain
import HealthKit

/// Traduce actividades de Apple Salud a estímulo muscular y muestras diarias.
/// Alimenta equilibrio / fatiga (`MuscleMapEngine`) y carga del periodo (`MuscleLoadEngine`).
enum HealthMuscleMapper {
    static func stimuli(from activities: [HealthKitStore.ExternalActivity]) -> [ExternalMuscleStimulus] {
        activities.compactMap { activity in
            let load = muscleLoad(for: activity.activityType, durationMinutes: activity.durationMinutes)
            guard !load.isEmpty else { return nil }
            return ExternalMuscleStimulus(date: activity.start, load: load)
        }
    }

    static func daySamples(from activities: [HealthKitStore.ExternalActivity]) -> [ExternalDaySample] {
        activities.map { activity in
            let mins = max(0, activity.durationMinutes)
            // Solo tipos cardio reales en «cardioMinutes» (fuerza no infla la tile Cardio).
            let cardio = isCardio(activity.activityType) ? mins : 0
            return ExternalDaySample(
                date: activity.start,
                minutes: mins,
                volumeKg: 0,
                activeEnergyKcal: max(0, activity.activeEnergyKcal ?? 0),
                cardioMinutes: cardio
            )
        }
    }

    static func isCardio(_ type: HKWorkoutActivityType) -> Bool {
        switch type {
        case .running, .walking, .hiking, .cycling, .handCycling,
             .swimming, .elliptical, .rowing, .stairClimbing,
             .highIntensityIntervalTraining, .mixedCardio, .crossTraining,
             .dance, .wheelchairRunPace, .paddleSports:
            return true
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return false
        default:
            // Deportes y resto: cuentan como cardio para minutos de Progreso.
            return true
        }
    }

    static func muscleLoad(for type: HKWorkoutActivityType, durationMinutes: Double) -> [String: Double] {
        let sets = setUnits(durationMinutes: durationMinutes, for: type)
        let template = template(for: type)
        guard !template.isEmpty else { return [:] }
        return template.mapValues { $0 * sets }
    }

    /// Minutos por «serie efectiva»: deportes/HIIT pesan más que paseo suave.
    private static func setUnits(durationMinutes: Double, for type: HKWorkoutActivityType) -> Double {
        let minutesPerSet: Double = {
            switch type {
            case .highIntensityIntervalTraining, .mixedCardio, .crossTraining:
                return 10
            case .traditionalStrengthTraining, .functionalStrengthTraining,
                 .coreTraining, .martialArts:
                return 12
            case .tennis, .pickleball, .racquetball, .squash, .badminton,
                 .soccer, .basketball, .volleyball, .americanFootball,
                 .baseball, .softball, .hockey, .lacrosse, .rugby,
                 .boxing, .kickboxing, .wrestling:
                return 12
            case .running, .stairClimbing, .elliptical, .rowing, .swimming,
                 .paddleSports, .cycling, .handCycling:
                return 15
            case .walking, .hiking, .wheelchairRunPace, .yoga, .pilates,
                 .flexibility, .cooldown, .dance, .golf:
                return 22
            default:
                return 16
            }
        }()
        return max(0.5, durationMinutes / minutesPerSet)
    }

    private static func template(for type: HKWorkoutActivityType) -> [String: Double] {
        switch type {
        case .running, .wheelchairRunPace:
            return [
                "quadriceps": 0.3, "hamstring": 0.25, "gluteal": 0.2,
                "calves": 0.15, "tibialis": 0.05, "abs": 0.05,
            ]
        case .walking, .hiking:
            return [
                "quadriceps": 0.3, "gluteal": 0.25, "hamstring": 0.2,
                "calves": 0.15, "tibialis": 0.1,
            ]
        case .cycling, .handCycling:
            return [
                "quadriceps": 0.4, "hamstring": 0.25, "gluteal": 0.2, "calves": 0.15,
            ]
        case .swimming, .paddleSports:
            return [
                "upper-back": 0.2, "deltoids": 0.15, "chest": 0.1, "triceps": 0.1,
                "biceps": 0.1, "abs": 0.1, "quadriceps": 0.1, "hamstring": 0.075, "gluteal": 0.075,
            ]
        case .rowing:
            return [
                "upper-back": 0.25, "biceps": 0.15, "forearm": 0.1, "abs": 0.1,
                "quadriceps": 0.15, "hamstring": 0.1, "gluteal": 0.1, "deltoids": 0.05,
            ]
        case .yoga, .pilates, .flexibility, .cooldown:
            return [
                "abs": 0.25, "obliques": 0.15, "lower-back": 0.15,
                "gluteal": 0.15, "hip-flexors": 0.15, "hamstring": 0.15,
            ]
        case .coreTraining:
            return ["abs": 0.5, "obliques": 0.3, "lower-back": 0.2]
        case .stairClimbing, .elliptical:
            return [
                "quadriceps": 0.35, "gluteal": 0.3, "hamstring": 0.2, "calves": 0.15,
            ]
        case .highIntensityIntervalTraining, .crossTraining, .mixedCardio:
            return [
                "quadriceps": 0.15, "hamstring": 0.1, "gluteal": 0.1,
                "chest": 0.1, "upper-back": 0.1, "deltoids": 0.1,
                "abs": 0.1, "biceps": 0.075, "triceps": 0.075, "calves": 0.1,
            ]
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return [
                "chest": 0.12, "upper-back": 0.12, "deltoids": 0.1,
                "quadriceps": 0.12, "hamstring": 0.1, "gluteal": 0.1,
                "biceps": 0.08, "triceps": 0.08, "abs": 0.08, "calves": 0.1,
            ]
        case .dance:
            return [
                "gluteal": 0.25, "quadriceps": 0.2, "calves": 0.2,
                "abs": 0.15, "hip-flexors": 0.2,
            ]
        case .martialArts, .boxing, .kickboxing, .wrestling:
            return [
                "deltoids": 0.2, "abs": 0.2, "obliques": 0.15,
                "quadriceps": 0.15, "calves": 0.1, "upper-back": 0.1, "triceps": 0.1,
            ]
        // Raqueta: piernas + hombro/antebrazo del golpe.
        case .tennis, .pickleball, .racquetball, .squash, .badminton:
            return [
                "quadriceps": 0.2, "hamstring": 0.12, "gluteal": 0.12, "calves": 0.12,
                "deltoids": 0.15, "forearm": 0.12, "obliques": 0.1, "abs": 0.07,
            ]
        case .soccer, .basketball, .volleyball, .americanFootball,
             .baseball, .softball, .hockey, .lacrosse, .rugby:
            return [
                "quadriceps": 0.25, "hamstring": 0.18, "gluteal": 0.15,
                "calves": 0.15, "abs": 0.1, "deltoids": 0.1, "obliques": 0.07,
            ]
        case .golf:
            return [
                "obliques": 0.3, "lower-back": 0.2, "forearm": 0.2,
                "deltoids": 0.15, "abs": 0.15,
            ]
        case .downhillSkiing, .snowboarding, .skatingSports,
             .crossCountrySkiing, .snowSports:
            return [
                "quadriceps": 0.35, "gluteal": 0.25, "hamstring": 0.2, "calves": 0.2,
            ]
        case .climbing, .equestrianSports, .surfingSports, .waterFitness:
            return [
                "forearm": 0.2, "upper-back": 0.2, "biceps": 0.15, "deltoids": 0.15,
                "abs": 0.1, "quadriceps": 0.1, "calves": 0.1,
            ]
        default:
            // Cualquier otro workout de Salud sigue aportando fatiga genérica (no se ignora).
            return [
                "quadriceps": 0.2, "gluteal": 0.15, "hamstring": 0.15,
                "abs": 0.15, "upper-back": 0.15, "deltoids": 0.1, "calves": 0.1,
            ]
        }
    }
}
