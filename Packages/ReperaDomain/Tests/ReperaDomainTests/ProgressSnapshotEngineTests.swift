import XCTest
@testable import ReperaDomain

/// Domain-side coverage for Progress period filtering / weight bucketing invariants.
final class ProgressSnapshotEngineTests: XCTestCase {
    func testAllSixRangesFilterWorkoutsWithoutCrashing() {
        let now = Date()
        let sessions = (0..<40).map { i -> WorkoutSession in
            WorkoutSession(
                title: "W\(i)",
                exercises: [],
                startedAt: Calendar.current.date(byAdding: .day, value: -i, to: now),
                finishedAt: Calendar.current.date(byAdding: .day, value: -i, to: now)
            )
        }
        for range in ProgressTimeRange.allCases {
            let filtered = StatsEngine.filterWorkouts(
                sessions,
                range: range,
                weekStartsOnMonday: true,
                now: now
            )
            XCTAssertLessThanOrEqual(filtered.count, sessions.count)
            let summary = StatsEngine.progressHealthSummary(
                workouts: sessions,
                range: range,
                weekStartsOnMonday: true,
                now: now
            )
            XCTAssertGreaterThanOrEqual(summary.sessionCount, 0)
        }
    }

    func testRapidRangeSwitchDoesNotDuplicateSessionCounts() {
        let now = Date()
        let finished = now.addingTimeInterval(45 * 60)
        let s = WorkoutSession(
            title: "Only",
            exercises: [],
            startedAt: now,
            finishedAt: finished,
            appleDurationSeconds: 45 * 60
        )
        let week = StatsEngine.progressHealthSummary(
            workouts: [s],
            range: .week,
            weekStartsOnMonday: true,
            now: finished
        )
        let days360 = StatsEngine.progressHealthSummary(
            workouts: [s],
            range: .days360,
            weekStartsOnMonday: true,
            now: finished
        )
        XCTAssertEqual(week.sessionCount, 1)
        XCTAssertEqual(days360.sessionCount, 1)
    }

    func testAveragedSeriesKeepsStableBucketDates() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let points = (0..<14).map { i -> ProgressDayPoint in
            let d = cal.date(byAdding: .day, value: -i, to: start)!
            return ProgressDayPoint(dayKey: "\(i)", date: d, value: Double(70 + i))
        }
        let weekly = StatsEngine.averagedSeries(
            points,
            granularity: .week,
            weekStartsOnMonday: true
        )
        XCTAssertFalse(weekly.isEmpty)
        // Same input → same bucket dates (stable chart identity).
        let again = StatsEngine.averagedSeries(
            points,
            granularity: .week,
            weekStartsOnMonday: true
        )
        XCTAssertEqual(weekly.map(\.date), again.map(\.date))
        XCTAssertEqual(weekly.map(\.value), again.map(\.value))
    }
}
