import XCTest
@testable import ReperaDomain

final class CompletedWorkoutEditingTests: XCTestCase {
    func testReorderAndEditCompletedValuesKeepHistoryIdentity() {
        let squat = Exercise(name: "Sentadilla con barra", muscleGroup: "Piernas")
        let press = Exercise(name: "Press banca", muscleGroup: "Pecho")
        let routine = Routine(
            title: "Fuerza",
            blocks: [.strength(title: "Bloque A", exercises: [
                RoutineExercise(exerciseId: squat.id, plannedSets: [PlannedSet(targetReps: 8, targetWeightKg: 40)]),
                RoutineExercise(exerciseId: press.id, plannedSets: [PlannedSet(targetReps: 8, targetWeightKg: 30)])
            ])]
        )
        var session = SessionController.from(routine: routine, exercises: [squat, press])
        session.phase = .finished
        session.startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        session.finishedAt = session.startedAt!.addingTimeInterval(3600)
        session.exercises[0].loggedSets = [LoggedSet(reps: 5, weightKg: 60, rir: 2)]
        session.exercises[1].loggedSets = [LoggedSet(reps: 6, weightKg: 35, rir: 1)]
        session.exercises[0].isCompleted = true
        session.exercises[1].isCompleted = true
        let oldIDs = session.exercises.map(\.id)
        let oldSetID = session.exercises[0].loggedSets[0].id
        var draft = CompletedWorkoutEditing.routine(from: session)
        XCTAssertEqual(draft.blocks[0].exercises[0].plannedSets[0].targetWeightKg, 60)
        XCTAssertEqual(draft.blocks[0].exercises[0].plannedSets[0].targetReps, 5)
        draft.blocks[0].exercises.swapAt(0, 1)
        draft.blocks[0].exercises[1].plannedSets[0].targetWeightKg = 70
        draft.blocks[0].exercises[1].plannedSets[0].targetReps = 4
        let updated = CompletedWorkoutEditing.applying(draft, to: session, catalog: [squat, press])
        XCTAssertEqual(updated.id, session.id)
        XCTAssertEqual(updated.exercises.map(\.id), Array(oldIDs.reversed()))
        XCTAssertEqual(updated.exercises[1].loggedSets[0].id, oldSetID)
        XCTAssertEqual(updated.exercises[1].loggedSets[0].weightKg, 70)
        XCTAssertEqual(updated.exercises[1].loggedSets[0].reps, 4)
        XCTAssertEqual(updated.exercises[0].loggedSets[0].reps, 6)
        XCTAssertEqual(updated.finishedAt, session.finishedAt)
        XCTAssertEqual(updated.phase, .finished)
        XCTAssertNotNil(updated.routineBlocks)
    }

    func testNewUnloggedExerciseDoesNotInventCompletedSets() {
        let squat = Exercise(name: "Sentadilla con barra", muscleGroup: "Piernas")
        let press = Exercise(name: "Press banca", muscleGroup: "Pecho")
        let routine = Routine(title: "A", blocks: [.strength(exercises: [
            RoutineExercise(exerciseId: squat.id, plannedSets: [PlannedSet(targetReps: 5)])
        ])])
        var session = SessionController.from(routine: routine, exercises: [squat, press])
        session.phase = .finished
        var draft = CompletedWorkoutEditing.routine(from: session)
        draft.blocks[0].exercises.append(RoutineExercise(
            exerciseId: press.id, plannedSets: [PlannedSet(targetReps: 8)]
        ))
        let saved = CompletedWorkoutEditing.applying(draft, to: session, catalog: [squat, press])
        XCTAssertEqual(saved.exercises.count, 2)
        XCTAssertTrue(saved.exercises[1].loggedSets.isEmpty)
        XCTAssertFalse(saved.exercises[1].isCompleted)
    }

    func testWODRestAndScoreSurviveEditingSnapshot() {
        let burpee = Exercise(name: "Burpees", muscleGroup: "Otros")
        let block = RoutineBlock(
            title: "RFT", kind: .wod,
            movements: [
                WODMovement(exerciseId: burpee.id, name: burpee.name, reps: 10),
                WODMovement(name: "REST", isRest: true, restSeconds: 45)
            ],
            wodFormat: .forTime, rounds: 3
        )
        let routine = Routine(title: "Circuito", blocks: [block])
        var session = SessionController.from(routine: routine, exercises: [burpee])
        session.phase = .finished
        session.wodResults = [WODBlockResult(id: block.id, format: .forTime, elapsedSeconds: 250)]
        var draft = CompletedWorkoutEditing.routine(from: session)
        XCTAssertEqual(draft.blocks[0].movements.count, 2)
        XCTAssertTrue(draft.blocks[0].movements[1].isRest)
        draft.blocks[0].movements[1].restSeconds = 60
        let saved = CompletedWorkoutEditing.applying(draft, to: session, catalog: [burpee])
        XCTAssertEqual(saved.routineBlocks?[0].movements[1].restSeconds, 60)
        XCTAssertEqual(saved.wodResults[0].elapsedSeconds, 250)
    }
}
