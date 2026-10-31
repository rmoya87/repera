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


    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testWeekIsRollingSevenDaysPreviousWindow() {
        // Martes 27 → actuales 21–27; previos 14–21 (fin exclusivo).
        let tuesday = day(2026, 10, 27)
        let bounds = ProgressTimeRange.week.previousPeriodBounds(now: tuesday, weekStartsOnMonday: true)!
        let cal = Calendar.current
        XCTAssertTrue(cal.isDate(bounds.start, inSameDayAs: day(2026, 10, 14)))
        XCTAssertTrue(cal.isDate(bounds.end, inSameDayAs: day(2026, 10, 21)))
        XCTAssertTrue(ProgressTimeRange.week.containsInPreviousPeriod(day(2026, 10, 20), now: tuesday))
        XCTAssertFalse(ProgressTimeRange.week.containsInPreviousPeriod(day(2026, 10, 21), now: tuesday))
        XCTAssertEqual(
            ProgressTimeRange.week.startDate(now: tuesday),
            cal.startOfDay(for: day(2026, 10, 21))
        )
    }

    func testWeekRollingIgnoresWeekStartsOnMonday() {
        let monday = day(2026, 10, 26)
        let bounds = ProgressTimeRange.week.previousPeriodBounds(
            now: monday, weekStartsOnMonday: false
        )!
        let cal = Calendar.current
        XCTAssertTrue(cal.isDate(bounds.start, inSameDayAs: day(2026, 10, 13)))
        XCTAssertTrue(cal.isDate(bounds.end, inSameDayAs: day(2026, 10, 20)))
        XCTAssertFalse(ProgressTimeRange.week.containsInPreviousPeriod(
            day(2026, 10, 20), now: monday, weekStartsOnMonday: false
        ))
    }

    func testRollingWeekPreviousSpanIsAlwaysSevenDays() {
        let sunday = day(2026, 11, 1)
        let bounds = ProgressTimeRange.week.previousPeriodBounds(now: sunday)!
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: bounds.start, to: bounds.end).day, 7)
    }

    func testMonthComparisonOnlyUsesSameElapsedMonthDays() {
        let tuesday = day(2026, 10, 27)
        let bounds = ProgressTimeRange.month.previousPeriodBounds(now: tuesday)!
        let cal = Calendar.current
        XCTAssertTrue(cal.isDate(bounds.start, inSameDayAs: day(2026, 9, 1)))
        XCTAssertTrue(cal.isDate(bounds.end, inSameDayAs: day(2026, 9, 28)))
        XCTAssertTrue(ProgressTimeRange.month.containsInPreviousPeriod(day(2026, 9, 27), now: tuesday))
        XCTAssertFalse(ProgressTimeRange.month.containsInPreviousPeriod(day(2026, 9, 28), now: tuesday))
    }

    func testPreviousMonthClampsAtEndOfShorterMonth() {
        let now = day(2026, 3, 31)
        let bounds = ProgressTimeRange.month.previousPeriodBounds(now: now)!
        let cal = Calendar.current
        XCTAssertTrue(cal.isDate(bounds.start, inSameDayAs: day(2026, 2, 1)))
        XCTAssertTrue(cal.isDate(bounds.end, inSameDayAs: day(2026, 3, 1)))
    }

    func testRollingWindowComparesFullPriorWindow() {
        let now = day(2026, 10, 27)
        let b = ProgressTimeRange.days90.previousPeriodBounds(now: now)!
        let currentStart = ProgressTimeRange.days90.startDate(now: now)!
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: b.start, to: b.end).day, 90)
        XCTAssertEqual(b.end, currentStart)
    }

    func testTotalMinutesAreActualRecordedMinutes() {
        let now = day(2026, 10, 27)
        let workout = WorkoutSession(title: "Walk", exercises: [], startedAt: now, finishedAt: now, appleDurationSeconds: 45 * 60)
        let zeroDuration = WorkoutSession(title: "No duration", exercises: [], startedAt: now, finishedAt: now)
        let summary = StatsEngine.progressHealthSummary(workouts: [workout, zeroDuration], range: .today, now: now)
        XCTAssertEqual(summary.totalMinutes, 45, accuracy: 0.01)
        XCTAssertEqual(summary.sessionCount, 2)
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
