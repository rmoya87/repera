import XCTest
@testable import ReperaDomain

final class LiveSportPersonalReviewTests: XCTestCase {
    private func outing(daysAgo: Int, distance: Double, seconds: Double, sport: String = "running") -> WorkoutSession {
        let end = Date().addingTimeInterval(-Double(daysAgo) * 86_400 - 3_600)
        return WorkoutSession(
            title: "Actividad deportiva",
            exercises: [],
            phase: .finished,
            startedAt: end.addingTimeInterval(-seconds),
            finishedAt: end,
            liveSportID: sport,
            recordedDistanceMeters: distance,
            activeDurationSeconds: seconds
        )
    }

    func testGPSActivityNeedsTwoIndependentComparableDays() {
        let current = outing(daysAgo: 0, distance: 5_000, seconds: 1_600)
        let first = outing(daysAgo: 5, distance: 5_000, seconds: 1_700)
        XCTAssertNil(VerifiedSessionReviewEngine.review(session: current, history: [first]))
        let second = outing(daysAgo: 3, distance: 5_100, seconds: 1_750)
        let grade = VerifiedSessionReviewEngine.review(session: current, history: [first, second])
        XCTAssertEqual(grade?.scoreBasis, .personalHistory)
        XCTAssertNotNil(grade)
    }

    func testUnrelatedSportOrDistanceNeverBecomesEvidence() {
        let current = outing(daysAgo: 0, distance: 5_000, seconds: 1_600)
        let wrongSport = outing(daysAgo: 5, distance: 5_000, seconds: 1_800, sport: "cycling")
        let wrongDistance = outing(daysAgo: 3, distance: 12_000, seconds: 3_900)
        XCTAssertNil(VerifiedSessionReviewEngine.review(
            session: current, history: [wrongSport, wrongDistance]
        ))
    }

    func testWithoutMeasuredGPSPerformanceDoesNotInventScore() {
        let noDistance = outing(daysAgo: 0, distance: 0, seconds: 1_600)
        let past = [
            outing(daysAgo: 5, distance: 5_000, seconds: 1_800),
            outing(daysAgo: 3, distance: 5_000, seconds: 1_900)
        ]
        XCTAssertNil(VerifiedSessionReviewEngine.review(session: noDistance, history: past))
    }
}
