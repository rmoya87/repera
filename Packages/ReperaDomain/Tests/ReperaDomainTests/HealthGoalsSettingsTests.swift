import Foundation
import Testing
@testable import ReperaDomain

@Suite("Objetivos de Salud - compatibilidad de ajustes")
struct HealthGoalsSettingsTests {
    @Test func legacySettingsKeepExistingWeightGoal() throws {
        // Simula los ajustes antiguos: el JSON no incluye las claves nuevas.
        let old = AppSettings(bodyWeightGoalKg: 78.5)
        let data = try JSONEncoder().encode(old)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(decoded.bodyWeightGoalKg == 78.5)
        #expect(decoded.dailyStepsGoal == nil)
        #expect(decoded.dailyActiveEnergyGoalKcal == nil)
        #expect(decoded.dailyAverageHeartRateGoalBpm == nil)
        #expect(decoded.dailyWorkoutMinutesGoal == nil)
        #expect(decoded.weeklyWorkoutGoal == nil)
    }

    @Test func newGoalsRoundTripThroughCodable() throws {
        let goals = AppSettings(
            bodyWeightGoalKg: 80.5,
            dailyStepsGoal: 12_000,
            dailyActiveEnergyGoalKcal: 600,
            dailyAverageHeartRateGoalBpm: 125,
            dailyWorkoutMinutesGoal: 45,
            weeklyWorkoutGoal: 5
        )
        let data = try JSONEncoder().encode(goals)
        let restored = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(restored == goals)
        #expect(restored.dailyStepsGoal == 12_000)
        #expect(restored.dailyActiveEnergyGoalKcal == 600)
        #expect(restored.dailyAverageHeartRateGoalBpm == 125)
        #expect(restored.dailyWorkoutMinutesGoal == 45)
        #expect(restored.weeklyWorkoutGoal == 5)
    }

    @Test func goalsCanBeUnsetWithoutRemovingWeightHistory() throws {
        let blank = AppSettings(bodyWeightGoalKg: 75)
        let restored = try JSONDecoder().decode(
            AppSettings.self, from: JSONEncoder().encode(blank)
        )
        #expect(restored.bodyWeightGoalKg == 75)
        #expect(restored.dailyStepsGoal == nil)
        #expect(restored.dailyAverageHeartRateGoalBpm == nil)
        #expect(restored.weeklyWorkoutGoal == nil)
    }
}
