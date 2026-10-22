import Foundation
import XCTest
@testable import ReperaDomain

final class RecoveryEngineTests: XCTestCase {
    func testSleepIndexDoesNotChangeSportScoreAndHandlesMissingData() {
        XCTAssertNil(RecoveryEngine.sleepIndex(hours: nil, recentAverage: 8))
        XCTAssertNil(RecoveryEngine.sleepIndex(hours: -2, recentAverage: 8))
        XCTAssertEqual(RecoveryEngine.sleepIndex(hours: 8, recentAverage: 8), 100)
        XCTAssertEqual(RecoveryEngine.sleepIndex(hours: 4, recentAverage: 8), 50)
        XCTAssertEqual(RecoveryEngine.sleepIndex(hours: 10, recentAverage: 8), 100)
    }

    func testTrainingReadinessNeedsObservedSleepAndCompletedWorkouts() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let session = WorkoutSession(
            title: "Sesión",
            exercises: [],
            startedAt: now.addingTimeInterval(-3600 * 14),
            finishedAt: now.addingTimeInterval(-3600 * 13)
        )
        XCTAssertNil(RecoveryEngine.trainingReadiness(
            at: now, sleepHours: nil, recentAverageSleepHours: 8,
            workouts: [session]
        ))
        XCTAssertNil(RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: []
        ))
        XCTAssertNil(RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [WorkoutSession(title: "Sin finalizar", exercises: [], startedAt: now)]
        ))
    }

    func testTrainingReadinessShortSleepDoesNotRecommendNormalSession() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let finished = now.addingTimeInterval(-3600 * 12)
        let session = WorkoutSession(
            title: "WOD", exercises: [],
            startedAt: finished.addingTimeInterval(-3600),
            finishedAt: finished
        )
        let score = RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 4.5, recentAverageSleepHours: 8,
            workouts: [session]
        )
        XCTAssertNotNil(score)
        XCTAssertLessThanOrEqual(score!.score, 5)
        XCTAssertEqual(score?.advice, .rest)
    }

    func testTrainingReadinessPenalizesGreaterRecentLoadAndIgnoresFutureSessions() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let one = WorkoutSession(
            title: "Una sesión", exercises: [],
            startedAt: now.addingTimeInterval(-3600 * 14),
            finishedAt: now.addingTimeInterval(-3600 * 13)
        )
        let two = WorkoutSession(
            title: "Otra sesión", exercises: [],
            startedAt: now.addingTimeInterval(-3600 * 18),
            finishedAt: now.addingTimeInterval(-3600 * 17)
        )
        let future = WorkoutSession(
            title: "Mañana", exercises: [],
            startedAt: now.addingTimeInterval(3600),
            finishedAt: now.addingTimeInterval(7200)
        )
        let base = RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [one]
        )
        let heavier = RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [one, two]
        )
        let ignoringFuture = RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [one, future]
        )
        XCTAssertNotNil(base)
        XCTAssertNotNil(heavier)
        XCTAssertLessThan(heavier!.score, base!.score)
        XCTAssertEqual(base, ignoringFuture)
    }

    func testUnknownWithInsufficientOrIrregularCycles() {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        func date(_ d: Int) -> Date { c.date(from: DateComponents(year: 2026, month: 1, day: d))! }
        XCTAssertEqual(RecoveryEngine.cyclePhase(flowDays: [date(1), date(2)], on: date(15), calendar: c), .unknown)
    }

    func testRecordedMenstruationIsNotPenalized() {
        let c = Calendar(identifier: .gregorian)
        let now = c.startOfDay(for: Date())
        XCTAssertEqual(RecoveryEngine.cyclePhase(flowDays: [now], on: now, calendar: c), .menstrual)
    }

    func testEstimatedPhaseOnlyWithRegularHistory() {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        let d1 = c.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let d2 = c.date(byAdding: .day, value: 28, to: d1)!
        let d3 = c.date(byAdding: .day, value: 28, to: d2)!
        let day14 = c.date(byAdding: .day, value: 14, to: d3)!
        XCTAssertEqual(RecoveryEngine.cyclePhase(flowDays: [d1,d2,d3], on: day14, calendar: c), .ovulatory)
    }
}
