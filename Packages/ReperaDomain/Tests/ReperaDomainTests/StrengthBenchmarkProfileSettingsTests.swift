import Foundation
import Testing
@testable import ReperaDomain

struct StrengthBenchmarkProfileSettingsTests {
    @Test func persistsCompetitionProfileWithoutDuplicatedCardInputs() throws {
        let settings = AppSettings(competitionSex: .male, birthYear: 1987)
        let bytes = try JSONEncoder().encode(settings)
        let loaded = try JSONDecoder().decode(AppSettings.self, from: bytes)
        #expect(loaded.competitionSex == .male)
        #expect(loaded.birthYear == 1987)
        #expect(loaded.bodyWeightGoalKg == nil)
    }

    @Test func oldSettingsDecodeWithoutGenderOrBirthYear() throws {
        let bytes = try JSONEncoder().encode(AppSettings())
        var json = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        json.removeValue(forKey: "competitionSex")
        json.removeValue(forKey: "birthYear")
        let old = try JSONSerialization.data(withJSONObject: json)
        let loaded = try JSONDecoder().decode(AppSettings.self, from: old)
        #expect(loaded.competitionSex == nil)
        #expect(loaded.birthYear == nil)
    }

    @Test func rejectsOutOfRangeBirthYearOnDecode() throws {
        let bytes = try JSONEncoder().encode(AppSettings(competitionSex: .female, birthYear: 1900))
        let settings = try JSONDecoder().decode(AppSettings.self, from: bytes)
        #expect(settings.birthYear == nil)
        #expect(settings.competitionSex == .female)
    }
}
