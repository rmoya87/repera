import XCTest
@testable import GymbroDomain

final class ProgressSeriesAveragingTests: XCTestCase {
    func testDays90UsesWeeklyAverages() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 5))! // lunes
        var points: [ProgressDayPoint] = []
        for i in 0..<14 {
            let day = cal.date(byAdding: .day, value: i, to: start)!
            points.append(ProgressDayPoint(dayKey: "\(i)", date: day, value: Double(i + 1)))
        }
        let granularity = ProgressSeriesGranularity.forChart(range: .days90)
        XCTAssertEqual(granularity, .week)

        let averaged = StatsEngine.averagedSeries(
            points,
            granularity: .week,
            weekStartsOnMonday: true,
            calendar: cal
        )
        XCTAssertEqual(averaged.count, 2)
        XCTAssertEqual(averaged[0].value, 4, accuracy: 0.01)
        XCTAssertEqual(averaged[1].value, 11, accuracy: 0.01)
    }

    func testDays360UsesMonthly() {
        XCTAssertEqual(ProgressSeriesGranularity.forChart(range: .days360), .month)
        XCTAssertEqual(ProgressSeriesGranularity.forChart(range: .days180), .week)
        XCTAssertEqual(ProgressSeriesGranularity.forChart(range: .month), .week)
        XCTAssertEqual(ProgressSeriesGranularity.forChart(range: .week), .day)
    }

    func testCardioSummaryIsAverageNotSum() {
        let cal = Calendar(identifier: .gregorian)
        let day = cal.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        let samples = [
            ExternalDaySample(date: day, minutes: 40, cardioMinutes: 40),
            ExternalDaySample(
                date: cal.date(byAdding: .day, value: 1, to: day)!,
                minutes: 20,
                cardioMinutes: 20
            ),
        ]
        let summary = StatsEngine.progressHealthSummary(
            workouts: [],
            external: samples,
            range: .days90,
            applyRangeFilter: false
        )
        XCTAssertEqual(summary.averageCardioMinutes ?? -1, 30, accuracy: 0.01)
    }

    func testStrengthExternalDoesNotInflateCardioAverage() {
        let cal = Calendar(identifier: .gregorian)
        let day = cal.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        let samples = [
            ExternalDaySample(date: day, minutes: 56, cardioMinutes: 0),
            ExternalDaySample(
                date: cal.date(byAdding: .day, value: 1, to: day)!,
                minutes: 30,
                cardioMinutes: 30
            ),
        ]
        let summary = StatsEngine.progressHealthSummary(
            workouts: [],
            external: samples,
            range: .days90,
            applyRangeFilter: false
        )
        XCTAssertEqual(summary.averageMinutes ?? -1, 43, accuracy: 0.01)
        XCTAssertEqual(summary.averageCardioMinutes ?? -1, 30, accuracy: 0.01)
    }
}
