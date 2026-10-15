import XCTest
@testable import GymbroDomain

final class Wave3Tests: XCTestCase {
    func testGreyskullAddsWeightWhenAMRAPBeatsTarget() {
        let bench = Catalog.seed().first { $0.name == "Press banca" }!
        let workout = WorkoutSession(
            title: "GS",
            exercises: [
                SessionExercise(
                    exercise: bench,
                    plannedSets: [
                        PlannedSet(targetReps: 5, targetWeightKg: 60),
                        PlannedSet(targetReps: 5, targetWeightKg: 60),
                        PlannedSet(targetReps: 5, targetWeightKg: 60),
                    ],
                    loggedSets: [
                        LoggedSet(reps: 5, weightKg: 60),
                        LoggedSet(reps: 5, weightKg: 60),
                        LoggedSet(reps: 8, weightKg: 60),
                    ],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            finishedAt: Date()
        )
        let suggestion = ProgressionEngine.suggest(
            exerciseId: bench.id,
            planned: workout.exercises[0].plannedSets,
            policy: .greyskull,
            workouts: [workout],
            incrementKg: 2.5
        )
        XCTAssertEqual(suggestion.weightKg, 62.5)
        XCTAssertTrue(suggestion.reason.lowercased().contains("greyskull"))
    }

    func testTripleAddsSetAfterRepCap() {
        let squat = Catalog.seed().first { $0.name == "Sentadilla" }!
        let workout = WorkoutSession(
            title: "T",
            exercises: [
                SessionExercise(
                    exercise: squat,
                    plannedSets: Array(repeating: PlannedSet(targetReps: 12, targetWeightKg: 80), count: 3),
                    loggedSets: Array(repeating: LoggedSet(reps: 12, weightKg: 80), count: 3),
                    isCompleted: true
                ),
            ],
            phase: .finished,
            finishedAt: Date()
        )
        let suggestion = ProgressionEngine.suggest(
            exerciseId: squat.id,
            planned: workout.exercises[0].plannedSets,
            policy: .triple,
            workouts: [workout],
            incrementKg: 2.5
        )
        XCTAssertEqual(suggestion.setCount, 4)
        XCTAssertEqual(suggestion.reps, 12)
    }

    func testPlateMathPerSide() {
        let solution = PlateMath.solve(targetKg: 100, barKg: 20, availablePlatesKg: [25, 20, 15, 10, 5, 2.5])
        XCTAssertEqual(solution.achievedKg, 100)
        XCTAssertEqual(solution.remainderKg, 0)
        XCTAssertFalse(solution.perSide.isEmpty)
        let totalPerSide = solution.perSide.reduce(0.0) { $0 + Double($1.countPerSide) * $1.plateKg }
        XCTAssertEqual(totalPerSide, 40)
    }

    func testSupersetPartnerDetection() {
        let exercises = Catalog.seed()
        var controller = SessionController(
            session: WorkoutSession(
                title: "SS",
                exercises: [
                    SessionExercise(exercise: exercises[0], plannedSets: [PlannedSet(targetReps: 8)], supersetGroup: 1),
                    SessionExercise(exercise: exercises[1], plannedSets: [PlannedSet(targetReps: 8)], supersetGroup: 1),
                    SessionExercise(exercise: exercises[2], plannedSets: [PlannedSet(targetReps: 8)], supersetGroup: nil),
                ],
                phase: .ready
            )
        )
        XCTAssertTrue(controller.nextIsSupersetPartner)
        controller.selectExercise(at: 1)
        XCTAssertFalse(controller.nextIsSupersetPartner)
        XCTAssertEqual(SessionController.supersetLabel(1), "SS A")
    }
}
