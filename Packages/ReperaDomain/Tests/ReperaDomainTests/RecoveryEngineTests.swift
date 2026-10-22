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

    func testTrainingReadinessUsesWholePointsOnZeroToTenScale() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let workout = WorkoutSession(
            title: "WOD de prueba",
            exercises: [],
            startedAt: now.addingTimeInterval(-3600 * 14),
            finishedAt: now.addingTimeInterval(-3600 * 13)
        )
        for hours in [4.5, 5.5, 6.5, 7.25, 8, 9.5] {
            guard let result = RecoveryEngine.trainingReadiness(
                at: now, sleepHours: hours, recentAverageSleepHours: 8,
                workouts: [workout]
            ) else {
                XCTFail("Debe existir una estimación con sueño y carga conocidos")
                continue
            }
            XCTAssertEqual(result.score, result.score.rounded())
            XCTAssertGreaterThanOrEqual(result.score, 0)
            XCTAssertLessThanOrEqual(result.score, 10)
            let expected: RecoveryEngine.TrainingReadinessAdvice =
                result.score >= 8 ? .usual : (result.score >= 6 ? .moderate : .rest)
            XCTAssertEqual(result.advice, expected)
        }
    }

    func testObservedHealthCardioAddsLoadWithoutDoubleCountingLocalWorkouts() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let session = WorkoutSession(
            title: "Fuerza", exercises: [],
            startedAt: now.addingTimeInterval(-14 * 3600),
            finishedAt: now.addingTimeInterval(-13 * 3600)
        )
        let cardio = RecoveryEngine.ObservedActivity(
            date: now.addingTimeInterval(-8 * 3600),
            durationMinutes: 120,
            isCardio: true
        )
        let baseline = RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [session]
        )
        let measured = RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [session], observedActivities: [cardio]
        )
        XCTAssertNotNil(baseline)
        XCTAssertNotNil(measured)
        XCTAssertLessThan(measured!.score, baseline!.score)
        XCTAssertEqual(measured?.cardioMinutes48h, 120)
        XCTAssertNil(baseline?.cardioMinutes48h)
    }

    func testReadinessCanUseHealthOnlyActivityAndDoesNotInventMissingData() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let observed = RecoveryEngine.ObservedActivity(
            date: now.addingTimeInterval(-8 * 3600),
            durationMinutes: 45, isCardio: true
        )
        let score = RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 7.5, recentAverageSleepHours: 8,
            workouts: [], observedActivities: [observed]
        )
        XCTAssertNotNil(score)
        XCTAssertEqual(score?.cardioMinutes48h, 45)
        XCTAssertNil(RecoveryEngine.trainingReadiness(
            at: now, sleepHours: nil, recentAverageSleepHours: 8,
            workouts: [], observedActivities: [observed]
        ))
        XCTAssertNil(RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 7.5, recentAverageSleepHours: 8,
            workouts: [], observedActivities: [
                .init(date: now.addingTimeInterval(3600), durationMinutes: 80, isCardio: true)
            ]
        ))
        XCTAssertNil(RecoveryEngine.trainingReadiness(
            at: now, sleepHours: 7.5, recentAverageSleepHours: 8,
            workouts: [], observedActivities: [
                .init(date: now.addingTimeInterval(-3600), durationMinutes: .nan, isCardio: true)
            ]
        ))
    }

    func testVitalsNeedSevenIndependentHistoricalDaysPerSignal() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        func day(_ offset: Int, hrv: Double? = 60, resting: Double? = 55) -> RecoveryEngine.DailyVitals {
            RecoveryEngine.DailyVitals(
                date: calendar.date(byAdding: .day, value: offset, to: today)!,
                hrvMilliseconds: hrv, restingHeartRateBpm: resting
            )
        }
        let todayLow = day(0, hrv: 35, resting: 67)
        let six = (1...6).map { day(-$0) } + [todayLow]
        let noBaseline = RecoveryEngine.vitalContext(at: today, history: six)
        XCTAssertEqual(noBaseline.penalty, 0)
        XCTAssertEqual(noBaseline.calibratedSignals, 0)

        let seven = (1...7).map { day(-$0) } + [todayLow]
        let withBaseline = RecoveryEngine.vitalContext(at: today, history: seven)
        XCTAssertGreaterThan(withBaseline.penalty, 0)
        XCTAssertEqual(withBaseline.calibratedSignals, 2)
        XCTAssertLessThanOrEqual(withBaseline.penalty, 1.8)

        // Repeated samples on one day must never count as independent days.
        let duplicates = Array(repeating: day(-1), count: 12) + [todayLow]
        XCTAssertEqual(RecoveryEngine.vitalContext(at: today, history: duplicates).penalty, 0)
    }

    func testMissingVitalsNeverChangeReadinessOrPerformanceHistory() {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: Date())
        let pastWorkout = WorkoutSession(
            title: "WOD", exercises: [],
            startedAt: date.addingTimeInterval(-15 * 3600),
            finishedAt: date.addingTimeInterval(-14 * 3600)
        )
        let original = RecoveryEngine.trainingReadiness(
            at: date, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [pastWorkout]
        )
        let partial = RecoveryEngine.trainingReadiness(
            at: date, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [pastWorkout],
            vitalHistory: [RecoveryEngine.DailyVitals(date: date, hrvMilliseconds: 20)]
        )
        XCTAssertEqual(original, partial)
        XCTAssertEqual(partial?.calibratedVitalSignals, 0)

        let seven = (1...7).map { i in RecoveryEngine.DailyVitals(
            date: calendar.date(byAdding: .day, value: -i, to: date)!,
            hrvMilliseconds: 60, restingHeartRateBpm: 55
        ) }
        let low = RecoveryEngine.DailyVitals(
            date: date, hrvMilliseconds: 30, restingHeartRateBpm: 69
        )
        let informed = RecoveryEngine.trainingReadiness(
            at: date, sleepHours: 8, recentAverageSleepHours: 8,
            workouts: [pastWorkout], vitalHistory: seven + [low]
        )
        XCTAssertNotNil(informed)
        XCTAssertLessThanOrEqual(informed!.score, original!.score)
        XCTAssertGreaterThan(informed!.physiologicalPenalty, 0)
        XCTAssertEqual(informed!.calibratedVitalSignals, 2)
        XCTAssertEqual(informed!.score, informed!.score.rounded())
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
