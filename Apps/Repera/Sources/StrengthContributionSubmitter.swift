import Foundation
import ReperaDomain

/// Best-effort anonymous Amateur contribution when the athlete saves a tested 1RM.
enum StrengthContributionSubmitter {
    static func submitIfNeeded(
        exerciseName: String,
        testedOneRMKg: Double?,
        settings: AppSettings,
        bodyWeightKg: Double?
    ) {
        guard settings.contributeAnonymousStrengthStats,
              let kg = testedOneRMKg, kg.isFinite, kg > 0,
              let lift = StrengthBenchmarkLiftResolver.lift(forExerciseName: exerciseName),
              let sex = settings.competitionSex,
              let birthYear = settings.birthYear,
              let bodyWeightKg, bodyWeightKg.isFinite, bodyWeightKg > 0,
              let client = BusinessAuthStore.shared.apiClient,
              BusinessAuthStore.shared.isConnected,
              !BusinessAuthStore.shared.requiresReauthentication
        else { return }

        let age = Calendar.current.component(.year, from: Date()) - birthYear
        guard StrengthContributionBands.ageBand(age: age) != nil,
              StrengthContributionBands.bodyWeightBand(kg: bodyWeightKg) != nil
        else { return }

        Task.detached(priority: .utility) {
            struct Params: Encodable {
                let p_lift: String
                let p_sex: String
                let p_age: Int
                let p_body_weight_kg: Double
                let p_weight_kg: Double
                let p_source_app: String
            }
            let params = Params(
                p_lift: lift.rawValue,
                p_sex: sex.rawValue,
                p_age: age,
                p_body_weight_kg: bodyWeightKg,
                p_weight_kg: kg,
                p_source_app: "ios"
            )
            _ = try? await client
                .rpc("submit_strength_benchmark_contribution", params: params)
                .execute()
        }
    }
}
