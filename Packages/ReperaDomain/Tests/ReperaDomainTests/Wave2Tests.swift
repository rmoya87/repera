import XCTest
@testable import ReperaDomain

final class Wave2Tests: XCTestCase {
    func testLinearProgressionAddsWeightOnHit() {
        let exercises = Catalog.seed()
        let bench = exercises.first { $0.name == "Press banca" }!
        var session = WorkoutSession(
            title: "A",
            exercises: [
                SessionExercise(
                    exercise: bench,
                    plannedSets: [PlannedSet(targetReps: 8, targetWeightKg: 60)],
                    loggedSets: [
                        LoggedSet(reps: 8, weightKg: 60),
                        LoggedSet(reps: 8, weightKg: 60),
                        LoggedSet(reps: 8, weightKg: 60),
                    ],
                    isCompleted: true
                ),
            ],
            phase: .finished,
            finishedAt: Date()
        )
        // planned had 1 set but we logged 3 hits at target — treat as hit via planned count 1
        session.exercises[0].plannedSets = [
            PlannedSet(targetReps: 8, targetWeightKg: 60),
            PlannedSet(targetReps: 8, targetWeightKg: 60),
            PlannedSet(targetReps: 8, targetWeightKg: 60),
        ]

        let suggestion = ProgressionEngine.suggest(
            exerciseId: bench.id,
            planned: session.exercises[0].plannedSets,
            policy: .linear,
            workouts: [session],
            incrementKg: 2.5
        )
        XCTAssertEqual(suggestion.weightKg, 62.5)
        XCTAssertTrue(suggestion.reason.contains("+"))
    }

    func testMuscleFatigueAfterRecentWork() {
        let exercises = Catalog.seed()
        let squat = exercises.first { $0.name == "Sentadilla" }!
        let workout = WorkoutSession(
            title: "Legs",
            exercises: [
                SessionExercise(
                    exercise: squat,
                    plannedSets: [],
                    loggedSets: (0..<6).map { _ in LoggedSet(reps: 8, weightKg: 100) },
                    isCompleted: true
                ),
            ],
            phase: .finished,
            finishedAt: Date()
        )
        let scores = MuscleMapEngine.retainedLoad(workouts: [workout])
        let quads = scores["quadriceps"] ?? 0
        XCTAssertGreaterThan(quads, 0.2)
        XCTAssertNotEqual(MuscleMapEngine.state(forScore: quads), .ready)
        XCTAssertGreaterThanOrEqual(MuscleMapEngine.level(forScore: quads), 3)
    }

    func testExternalHealthStimulusFeedsFatigue() {
        // Simula ~45 min tenis / carrera vía estímulo Salud (mismo contrato que HealthMuscleMapper).
        let tennis = ExternalMuscleStimulus(
            date: Date(),
            load: [
                "quadriceps": 0.2 * 3.75, "deltoids": 0.15 * 3.75, "forearm": 0.12 * 3.75,
                "calves": 0.12 * 3.75, "obliques": 0.1 * 3.75,
            ]
        )
        let run = ExternalMuscleStimulus(
            date: Date(),
            load: [
                "quadriceps": 0.3 * 3.0, "hamstring": 0.25 * 3.0, "gluteal": 0.2 * 3.0,
                "calves": 0.15 * 3.0,
            ]
        )
        let scores = MuscleMapEngine.retainedLoad(workouts: [], external: [tennis, run])
        XCTAssertGreaterThan(scores["quadriceps"] ?? 0, 0.15)
        XCTAssertGreaterThan(scores["deltoids"] ?? 0, 0.05)
        XCTAssertGreaterThan(scores["calves"] ?? 0, 0.05)
    }

    func testStrongCSVImport() {
        let csv = """
        Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE
        2026-04-02 18:05:00,"Upper A",1h 5m,"Bench Press (Barbell)",1,60,8,0,0,"","Good day",8
        2026-04-02 18:05:00,"Upper A",1h 5m,"Bench Press (Barbell)",2,60,8,0,0,"","Good day",8
        2026-04-05 17:00:00,"Legs",52m,"Squat (Barbell)",1,80,5,0,0,"","",
        """
        let result = WorkoutCSVImporter.parse(csv: csv, existingExercises: Catalog.seed())
        XCTAssertEqual(result.source, .strong)
        XCTAssertEqual(result.workouts.count, 2)
        XCTAssertGreaterThanOrEqual(result.matchedSets, 3)
        XCTAssertTrue(result.workouts.contains { $0.title == "Upper A" })
    }

    func testHevyCSVImport() {
        let csv = """
        "title","start_time","end_time","description","exercise_title","superset_id","exercise_notes","set_index","set_type","weight_kg","reps","distance_km","duration_seconds","rpe"
        "Push","2026-02-03 18:00:00","2026-02-03 19:10:00","Felt fresh","Bench Press (Barbell)",,"",0,"normal",62.5,8,,,8
        "Push","2026-02-03 18:00:00","2026-02-03 19:10:00","Felt fresh","Lateral Raise (Dumbbell)",0,"",0,"normal",10,12,,,
        """
        let result = WorkoutCSVImporter.parse(csv: csv, existingExercises: Catalog.seed())
        XCTAssertEqual(result.source, .hevy)
        XCTAssertEqual(result.workouts.count, 1)
        XCTAssertEqual(result.matchedSets, 2)
    }
}
