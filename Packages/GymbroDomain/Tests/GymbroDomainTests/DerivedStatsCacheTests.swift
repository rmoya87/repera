import XCTest
@testable import GymbroDomain

final class DerivedStatsCacheTests: XCTestCase {
    func testPersonalRecordsCacheHitDoesNotRecompute() {
        let cache = DerivedStatsCache()
        let key = DerivedStatsCache.Key(revision: 1, rangeRaw: "week", mondayFirst: true, workoutCount: 0)
        var computeCount = 0
        let first = cache.personalRecords(key: key) {
            computeCount += 1
            return []
        }
        let second = cache.personalRecords(key: key) {
            computeCount += 1
            return [PersonalRecord(
                exerciseId: UUID(),
                exerciseName: "x",
                weightKg: 100,
                reps: 5,
                date: Date()
            )]
        }
        XCTAssertEqual(computeCount, 1)
        XCTAssertEqual(first, second)
    }

    func testInvalidateForcesRecompute() {
        let cache = DerivedStatsCache()
        let key = DerivedStatsCache.Key(revision: 2, rangeRaw: "month", mondayFirst: true, workoutCount: 1)
        var computeCount = 0
        _ = cache.personalRecords(key: key) { computeCount += 1; return [] }
        cache.invalidate()
        _ = cache.personalRecords(key: key) { computeCount += 1; return [] }
        XCTAssertEqual(computeCount, 2)
    }

    func testGoldenPersonalRecordsStableAcrossCache() {
        // Same mathematical result with and without cache.
        let session = SessionController.demoPushPull()
        var ctrl = SessionController(session: session)
        ctrl.startOnPhone()
        ctrl.logSet(reps: 5, weightKg: 100)
        ctrl.finishWorkout()
        let workouts = [ctrl.session]

        let direct = StatsEngine.personalRecords(from: workouts)
        let cache = DerivedStatsCache()
        let key = DerivedStatsCache.Key(
            revision: 1,
            rangeRaw: "all",
            mondayFirst: true,
            workoutCount: workouts.count
        )
        let cached = cache.personalRecords(key: key) {
            StatsEngine.personalRecords(from: workouts)
        }
        // PersonalRecord.id is random per construction — compare math fields.
        XCTAssertEqual(direct.count, cached.count)
        XCTAssertEqual(direct.first?.exerciseId, cached.first?.exerciseId)
        XCTAssertEqual(direct.first?.weightKg, cached.first?.weightKg)
        XCTAssertEqual(direct.first?.reps, cached.first?.reps)
        XCTAssertEqual(direct.first?.estimatedOneRM, cached.first?.estimatedOneRM)
        XCTAssertFalse(direct.isEmpty)
    }
}
