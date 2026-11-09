import XCTest
@testable import ReperaDomain

final class StrengthBenchmarkEngineTests: XCTestCase {
    private let cohort = StrengthBenchmarkCohort(
        lift: .squat, sex: .male, equipment: .raw,
        ageMin: 35, ageMax: 39, bodyWeightMinKg: 80, bodyWeightMaxKg: 90
    )

    private func distribution(count: Int = 200) -> StrengthBenchmarkDistribution {
        StrengthBenchmarkDistribution(
            cohort: cohort, source: "OpenPowerlifting", sourceRevision: "sample-v1",
            sampleCount: count, quantiles: [
                .init(percentile: 10, weightKg: 100),
                .init(percentile: 50, weightKg: 150),
                .init(percentile: 90, weightKg: 200)
            ]
        )
    }

    func testInterpolatesWithinSameCohort() {
        let result = StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            weightKg: 175, lift: .squat, sex: .male, equipment: .raw,
            age: 37, bodyWeightKg: 85, distributions: [distribution()]
        )
        XCTAssertEqual(result?.percentile, 70)
        XCTAssertEqual(result?.sampleCount, 200)
    }

    func testRejectsSmallSamplesAndWrongCohorts() {
        let args = [distribution(count: 10)]
        XCTAssertNil(StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            weightKg: 175, lift: .squat, sex: .male, equipment: .raw,
            age: 37, bodyWeightKg: 85, distributions: args))
        XCTAssertNil(StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            weightKg: 175, lift: .benchPress, sex: .male, equipment: .raw,
            age: 37, bodyWeightKg: 85, distributions: [distribution()]))
    }

    func testDoesNotExtrapolateOrMixOverlappingCohorts() {
        XCTAssertNil(StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            weightKg: 300, lift: .squat, sex: .male, equipment: .raw,
            age: 37, bodyWeightKg: 85, distributions: [distribution()]))
        XCTAssertNil(StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            weightKg: 175, lift: .squat, sex: .male, equipment: .raw,
            age: 37, bodyWeightKg: 85, distributions: [distribution(), distribution()]))
    }
}
