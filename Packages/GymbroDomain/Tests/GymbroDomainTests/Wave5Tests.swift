import XCTest
@testable import GymbroDomain

final class Wave5Tests: XCTestCase {
    func testRestPauseSumsClustersAndVolume() {
        let set = LoggedSet(
            reps: 0,
            weightKg: 60,
            kind: .restpause,
            clusters: [
                RestPauseCluster(reps: 8, restSeconds: 15),
                RestPauseCluster(reps: 4, restSeconds: 15),
                RestPauseCluster(reps: 2, restSeconds: 15),
            ]
        )
        XCTAssertEqual(set.kind, .restpause)
        XCTAssertEqual(set.reps, 14)
        XCTAssertEqual(set.volumeKg, 60 * 14)
    }

    func testCoachInsightsForEmptyHistory() {
        let state = AppState(exercises: Catalog.seed(), routines: [], workouts: [])
        let insights = CoachEngine.insights(state: state)
        XCTAssertFalse(insights.isEmpty)
        XCTAssertTrue(insights.contains { $0.title.lowercased().contains("empieza") })
    }

    func testCoachFlagsFatigue() {
        let squat = Catalog.seed().first { $0.name == "Sentadilla" }!
        let workout = WorkoutSession(
            title: "Legs",
            exercises: [
                SessionExercise(
                    exercise: squat,
                    plannedSets: [],
                    loggedSets: (0..<8).map { _ in LoggedSet(reps: 8, weightKg: 100, rir: 1) },
                    isCompleted: true
                ),
            ],
            phase: .finished,
            finishedAt: Date()
        )
        let state = AppState(
            exercises: Catalog.seed(),
            workouts: [workout]
        )
        let insights = CoachEngine.insights(state: state)
        XCTAssertTrue(insights.contains { $0.title.contains("Piernas") || $0.detail.lowercased().contains("fatig") || $0.title.lowercased().contains("fatig") })
    }
}
