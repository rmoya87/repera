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
    func testAllGlobalWODResultsCanBeCorrectedWithoutCreatingCompletedSets() {
        let burpee = Exercise(name: "Burpees", muscleGroup: "Otros")
        for format in [WODFormat.amrap, .deathBy, .maxEffort, .forTime,
                                  .chipper, .afap, .ladder, .buyInCashOut] {
            let block = RoutineBlock(
                title: "WOD", kind: .wod,
                movements: [WODMovement(exerciseId: burpee.id, name: burpee.name, reps: 10)],
                wodFormat: format, timeCapMinutes: 8
            )
            var session = SessionController.from(
                routine: Routine(title: "Hecho", blocks: [block]), exercises: [burpee]
            )
            session.phase = .finished
            session.wodResults = [WODBlockResult(
                id: block.id, format: format,
                totalReps: format.resultCapture == .totalReps ? 4 : nil,
                elapsedSeconds: format.resultCapture == .elapsedTime ? 480 : nil,
                roundsCompleted: (format == .amrap || format == .deathBy) ? 3 : nil
            )]
            let draft = CompletedWorkoutEditing.routine(from: session)
            // Los valores modificados son datos realizados, no series prescritas.
            session.wodResults[0].totalReps = format.resultCapture == .totalReps ? 7 : nil
            session.wodResults[0].elapsedSeconds = format.resultCapture == .elapsedTime ? 392 : nil
            if format == .amrap || format == .deathBy {
                session.wodResults[0].roundsCompleted = 5
            }
            let saved = CompletedWorkoutEditing.applying(
                draft, to: session, catalog: [burpee]
            )
            XCTAssertEqual(saved.id, session.id)
            XCTAssertEqual(saved.phase, .finished)
            XCTAssertEqual(saved.wodResults.count, 1, "\(format)")
            XCTAssertEqual(saved.wodResults[0].format, format)
            XCTAssertEqual(saved.wodResults[0].totalReps,
                           format.resultCapture == .totalReps ? 7 : nil)
            XCTAssertEqual(saved.wodResults[0].elapsedSeconds,
                           format.resultCapture == .elapsedTime ? 392 : nil)
            XCTAssertEqual(saved.wodResults[0].roundsCompleted,
                           (format == .amrap || format == .deathBy) ? 5 : nil)
            XCTAssertTrue(saved.exercises.allSatisfy { $0.loggedSets.isEmpty })
        }
    }

    func testPerMovementFormatsSaveEditedLoggedSetsWithoutInventingNewResults() {
        let press = Exercise(name: "Push press", muscleGroup: "Hombros")
        let squat = Exercise(name: "Sentadilla", muscleGroup: "Piernas")
        for format in [WODFormat.emom, .tabata, .circuit, .partner,
                                  .roundsForQuality, .strength] {
            let block = RoutineBlock(
                title: "Por serie", kind: .wod,
                movements: [
                    WODMovement(exerciseId: press.id, name: press.name, reps: 5),
                    WODMovement(exerciseId: squat.id, name: squat.name, reps: 8)
                ],
                wodFormat: format, timeCapMinutes: 8, rounds: 4,
                restBetweenRoundsSeconds: format == .circuit ? 25 : nil
            )
            var session = SessionController.from(
                routine: Routine(title: "Hecho", blocks: [block]), exercises: [press, squat]
            )
            session.phase = .finished
            XCTAssertEqual(session.exercises.count, 2)
            session.exercises[0].loggedSets = [LoggedSet(reps: 5, weightKg: 30, rir: 2)]
            let oldSetID = session.exercises[0].loggedSets[0].id
            var draft = CompletedWorkoutEditing.routine(from: session)
            var sets = draft.blocks[0].movements[0].explicitPlannedSets!
            sets[0].targetReps = 6
            sets[0].targetWeightKg = 35
            sets[0].targetRir = 1
            draft.blocks[0].movements[0].explicitPlannedSets = sets
            let saved = CompletedWorkoutEditing.applying(
                draft, to: session, catalog: [press, squat]
            )
            XCTAssertEqual(saved.exercises[0].loggedSets.count, 1, "\(format)")
            XCTAssertEqual(saved.exercises[0].loggedSets[0].id, oldSetID)
            XCTAssertEqual(saved.exercises[0].loggedSets[0].reps, 6)
            XCTAssertEqual(saved.exercises[0].loggedSets[0].weightKg, 35)
            XCTAssertEqual(saved.exercises[0].loggedSets[0].rir, 1)
            XCTAssertTrue(saved.exercises[1].loggedSets.isEmpty)
            XCTAssertTrue(saved.wodResults.isEmpty)
            if format == .circuit {
                XCTAssertEqual(saved.exercises[0].blockRestBetweenRoundsSeconds, 25)
                XCTAssertEqual(saved.routineBlocks?[0].restBetweenRoundsSeconds, 25)
            }
        }
    }

    func testStrengthBlockUsingGlobalWODFormatKeepsItsEditedScore() {
        let exercise = Exercise(name: "Sentadilla", muscleGroup: "Piernas")
        let block = RoutineBlock(
            title: "AMRAP con barra", kind: .strength,
            exercises: [
                RoutineExercise(exerciseId: exercise.id,
                    plannedSets: [PlannedSet(targetReps: 8, targetWeightKg: 40)])
            ],
            wodFormat: .amrap, timeCapMinutes: 8
        )
        var session = SessionController.from(
            routine: Routine(title: "WOD mixto", blocks: [block]), exercises: [exercise]
        )
        session.phase = .finished
        session.wodResults = [
            WODBlockResult(id: block.id, format: .amrap,
                           totalReps: 5, roundsCompleted: 4)
        ]
        let edited = CompletedWorkoutEditing.routine(from: session)
        session.wodResults[0].roundsCompleted = 6
        session.wodResults[0].totalReps = 3
        let saved = CompletedWorkoutEditing.applying(edited, to: session, catalog: [exercise])
        XCTAssertEqual(saved.id, session.id)
        XCTAssertEqual(saved.wodResults.count, 1)
        XCTAssertEqual(saved.wodResults[0].roundsCompleted, 6)
        XCTAssertEqual(saved.wodResults[0].totalReps, 3)
    }

    func testScaledMovementAndWODScorePersistAcrossEditAndJSON() throws {
        let exercise = Exercise(name: "Cargada y envión", muscleGroup: "Hombros")
        let block = RoutineBlock(
            title: "AMRAP 8'", kind: .wod,
            movements: [WODMovement(exerciseId: exercise.id, name: exercise.name,
                                    reps: 20, weightMaleKg: 40)],
            wodFormat: .amrap, timeCapMinutes: 8
        )
        var session = SessionController.from(
            routine: Routine(title: "Adaptado", blocks: [block]), exercises: [exercise]
        )
        session.phase = .finished
        session.wodResults = [WODBlockResult(
            id: block.id, format: .amrap, totalReps: 4, roundsCompleted: 5
        )]
        session.exercises[0].adaptedReps = 15
        session.exercises[0].adaptedWeightKg = 25.5
        let edit = CompletedWorkoutEditing.routine(from: session)
        let saved = CompletedWorkoutEditing.applying(edit, to: session, catalog: [exercise])
        XCTAssertEqual(saved.id, session.id)
        XCTAssertEqual(saved.wodResults[0].roundsCompleted, 5)
        XCTAssertEqual(saved.wodResults[0].totalReps, 4)
        XCTAssertEqual(saved.exercises[0].adaptedReps, 15)
        XCTAssertEqual(saved.exercises[0].adaptedWeightKg, 25.5)
        XCTAssertTrue(saved.exercises[0].loggedSets.isEmpty)
        XCTAssertTrue(saved.exercises[0].adjustedSummaryLine?.contains("Adaptado") == true)
        let decoded = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(saved))
        XCTAssertEqual(decoded.exercises[0].adaptedReps, 15)
        XCTAssertEqual(decoded.exercises[0].adaptedWeightKg, 25.5)
        XCTAssertTrue(decoded.exercises[0].loggedSets.isEmpty)
    }

    func testEditingOriginalWODPrescriptionPreservesAdaptationGlobalScoreAndLoggedSet() {
        let clean = Exercise(name: "Cargada y envión", muscleGroup: "Hombros")
        let movement = WODMovement(
            exerciseId: clean.id, name: clean.name, reps: 20, weightMaleKg: 40
        )
        let block = RoutineBlock(
            title: "AMRAP 8'", kind: .wod,
            movements: [movement], wodFormat: .amrap, timeCapMinutes: 8
        )
        let originalRoutine = Routine(title: "WOD original", blocks: [block])
        var session = SessionController.from(routine: originalRoutine, exercises: [clean])
        session.phase = .finished
        session.wodResults = [WODBlockResult(
            id: block.id, format: .amrap, totalReps: 4, roundsCompleted: 5
        )]
        session.exercises[0].loggedSets = [LoggedSet(reps: 16, weightKg: 27)]
        session.exercises[0].adaptedReps = 15
        session.exercises[0].adaptedWeightKg = 25

        var editor = CompletedWorkoutEditing.routine(from: session)
        // El formulario Rx NO se inicializa con el set realizado (16 @ 27).
        XCTAssertEqual(editor.blocks[0].movements[0].explicitPlannedSets?.first?.targetReps, 20)
        XCTAssertEqual(editor.blocks[0].movements[0].explicitPlannedSets?.first?.targetWeightKg, 40)
        editor.blocks[0].movements[0].reps = 18
        editor.blocks[0].movements[0].weightMaleKg = 35
        editor.blocks[0].movements[0].explicitPlannedSets?[0].targetReps = 18
        editor.blocks[0].movements[0].explicitPlannedSets?[0].targetWeightKg = 35

        let saved = CompletedWorkoutEditing.applying(editor, to: session, catalog: [clean])
        XCTAssertEqual(saved.id, session.id)
        XCTAssertEqual(saved.routineBlocks?[0].movements[0].reps, 18)
        XCTAssertEqual(saved.routineBlocks?[0].movements[0].weightMaleKg, 35)
        XCTAssertEqual(saved.exercises[0].plannedSets.first?.targetReps, 18)
        XCTAssertEqual(saved.exercises[0].plannedSets.first?.targetWeightKg, 35)
        XCTAssertEqual(saved.exercises[0].adaptedReps, 15)
        XCTAssertEqual(saved.exercises[0].adaptedWeightKg, 25)
        XCTAssertTrue(saved.exercises[0].hasWODScaling)
        XCTAssertEqual(saved.exercises[0].loggedSets.first?.reps, 16)
        XCTAssertEqual(saved.exercises[0].loggedSets.first?.weightKg, 27)
        XCTAssertEqual(saved.wodResults[0].roundsCompleted, 5)
        XCTAssertEqual(saved.wodResults[0].totalReps, 4)
        // El WOD plantilla nunca se actualiza por editar su sesión histórica.
        XCTAssertEqual(originalRoutine.blocks[0].movements[0].weightMaleKg, 40)
        XCTAssertEqual(originalRoutine.blocks[0].movements[0].reps, 20)
    }

    func testPerformedValuesEqualToEditedPrescriptionDoNotClaimScaled() {
        let ex = Exercise(name: "Cargada y envión", muscleGroup: "Hombros")
        var entry = SessionExercise(
            exercise: ex,
            plannedSets: [PlannedSet(targetReps: 20, targetWeightKg: 40)],
            adaptedReps: 15, adaptedWeightKg: 25
        )
        XCTAssertTrue(entry.hasWODScaling)
        XCTAssertEqual(entry.adjustedSummaryLine, "Adaptado · 15 reps · 25 kg")
        // Corregir el Rx original al valor realmente prescrito: el registro de
        // ejecución no desaparece, pero deja de ser una adaptación.
        entry.plannedSets[0].targetReps = 15
        entry.plannedSets[0].targetWeightKg = 25
        XCTAssertTrue(entry.hasRecordedWODExecution)
        XCTAssertFalse(entry.hasWODScaling)
        XCTAssertEqual(entry.adjustedSummaryLine, "Realizado · 15 reps · 25 kg")
    }

    func testConvertedStrengthGlobalWODRetainsRxAndLoggedSetsSeparately() {
        let press = Exercise(name: "Push press", muscleGroup: "Hombros")
        let originalRoutine = Routine(title: "Bloque", blocks: [
            RoutineBlock(
                title: "AMRAP 8'", kind: .strength,
                exercises: [RoutineExercise(
                    exerciseId: press.id,
                    plannedSets: [PlannedSet(targetReps: 10, targetWeightKg: 40)]
                )],
                wodFormat: .amrap, timeCapMinutes: 8
            ),
        ])
        var session = SessionController.from(routine: originalRoutine, exercises: [press])
        session.phase = .finished
        session.exercises[0].loggedSets = [LoggedSet(reps: 8, weightKg: 30)]
        let draft = CompletedWorkoutEditing.routine(from: session)
        XCTAssertEqual(draft.blocks[0].exercises[0].plannedSets.first?.targetWeightKg, 40)
        let saved = CompletedWorkoutEditing.applying(draft, to: session, catalog: [press])
        XCTAssertEqual(saved.exercises[0].plannedSets.first?.targetWeightKg, 40)
        XCTAssertEqual(saved.exercises[0].loggedSets.first?.weightKg, 30)
    }

    func testAllGlobalWODFormatsAllowEditingAndPersistingResultWithNoPriorScore() throws {
        let burpee = Exercise(name: "Burpees", muscleGroup: "Otros")
        let formats: [WODFormat] = [
            .amrap, .deathBy, .maxEffort,
            .forTime, .chipper, .afap, .ladder, .buyInCashOut
        ]
        for format in formats {
            let block = RoutineBlock(
                title: "WOD", kind: .wod,
                movements: [WODMovement(exerciseId: burpee.id, name: burpee.name, reps: 12)],
                wodFormat: format, timeCapMinutes: 22
            )
            var original = SessionController.from(
                routine: Routine(title: "Registrado", blocks: [block]), exercises: [burpee]
            )
            original.phase = .finished
            original.startedAt = Date(timeIntervalSince1970: 1_700_000_000)
            original.finishedAt = original.startedAt?.addingTimeInterval(1_200)
            XCTAssertTrue(original.wodResults.isEmpty, "\(format)")
            let edited: WorkoutSession
            if format.resultCapture == .totalReps {
                var partial = CompletedWorkoutEditing.changingScore(
                    in: original, for: block, field: .reps, value: 11
                )
                XCTAssertEqual(CompletedWorkoutEditing.scoreValue(
                    for: block, in: partial, field: .reps
                ), 11, "\(format)")
                if format == .amrap || format == .deathBy {
                    partial = CompletedWorkoutEditing.changingScore(
                        in: partial, for: block, field: .rounds, value: 5
                    )
                }
                edited = partial
            } else {
                let minutes = CompletedWorkoutEditing.changingScore(
                    in: original, for: block, field: .minutes, value: 12
                )
                edited = CompletedWorkoutEditing.changingScore(
                    in: minutes, for: block, field: .seconds, value: 37
                )
                XCTAssertEqual(CompletedWorkoutEditing.scoreValue(
                    for: block, in: edited, field: .minutes
                ), 12, "\(format)")
                XCTAssertEqual(CompletedWorkoutEditing.scoreValue(
                    for: block, in: edited, field: .seconds
                ), 37, "\(format)")
            }
            let draft = CompletedWorkoutEditing.routine(from: edited)
            let saved = CompletedWorkoutEditing.applying(
                draft, to: edited, catalog: [burpee]
            )
            let restored = try JSONDecoder().decode(
                WorkoutSession.self, from: JSONEncoder().encode(saved)
            )
            XCTAssertEqual(restored.wodResults.count, 1, "\(format)")
            XCTAssertEqual(restored.wodResults[0].format, format)
            XCTAssertEqual(restored.wodResults[0].totalReps,
                           format.resultCapture == .totalReps ? 11 : nil, "\(format)")
            XCTAssertEqual(restored.wodResults[0].roundsCompleted,
                           (format == .amrap || format == .deathBy) ? 5 : nil, "\(format)")
            XCTAssertEqual(restored.wodResults[0].elapsedSeconds,
                           format.resultCapture == .elapsedTime ? 757 : nil, "\(format)")
            XCTAssertTrue(restored.exercises.allSatisfy { $0.loggedSets.isEmpty })
            XCTAssertEqual(restored.id, original.id)
            XCTAssertEqual(restored.finishedAt, original.finishedAt)
        }
    }

    func testEditingRFTTimePreservesOtherBlockResultsAndHealthData() throws {
        let exercise = Exercise(name: "Thruster", muscleGroup: "Hombros")
        let rft = RoutineBlock(
            title: "RFT", kind: .wod,
            movements: [WODMovement(exerciseId: exercise.id, name: exercise.name, reps: 10)],
            wodFormat: .forTime, rounds: 4
        )
        let amrap = RoutineBlock(
            title: "AMRAP", kind: .wod,
            movements: [WODMovement(exerciseId: exercise.id, name: exercise.name, reps: 8)],
            wodFormat: .amrap, timeCapMinutes: 8
        )
        var session = SessionController.from(
            routine: Routine(title: "Dos WOD", blocks: [rft, amrap]), exercises: [exercise]
        )
        session.phase = .finished
        let healthUUID = UUID()
        session.healthKitWorkoutUUID = healthUUID
        session.appleActiveEnergyKcal = 212
        session.wodResults = [
            WODBlockResult(id: rft.id, format: .forTime, elapsedSeconds: 800),
            WODBlockResult(id: amrap.id, format: .amrap, totalReps: 3, roundsCompleted: 6)
        ]
        let minutes = CompletedWorkoutEditing.changingScore(
            in: session, for: rft, field: .minutes, value: 10
        )
        let seconds = CompletedWorkoutEditing.changingScore(
            in: minutes, for: rft, field: .seconds, value: 25
        )
        let saved = CompletedWorkoutEditing.applying(
            CompletedWorkoutEditing.routine(from: seconds),
            to: seconds, catalog: [exercise]
        )
        let result = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(saved)
        )
        XCTAssertEqual(result.wodResults.count, 2)
        XCTAssertEqual(result.wodResults.first(where: { $0.id == rft.id })?.elapsedSeconds, 625)
        XCTAssertEqual(result.wodResults.first(where: { $0.id == amrap.id })?.roundsCompleted, 6)
        XCTAssertEqual(result.healthKitWorkoutUUID, healthUUID)
        XCTAssertEqual(result.appleActiveEnergyKcal, 212)
    }

    func testLegacyAMRAPSingleSetBecomesEditableScoreWithoutInventingSets() {
        let exercise = Exercise(name: "Burpees", muscleGroup: "Otros")
        let block = RoutineBlock(
            title: "AMRAP antiguo", kind: .wod,
            movements: [WODMovement(exerciseId: exercise.id, name: exercise.name, reps: 9)],
            wodFormat: .amrap, timeCapMinutes: 10
        )
        var session = SessionController.from(
            routine: Routine(title: "Histórico", blocks: [block]), exercises: [exercise]
        )
        session.phase = .finished
        session.exercises[0].loggedSets = [LoggedSet(reps: 16)]
        XCTAssertEqual(CompletedWorkoutEditing.scoreValue(
            for: block, in: session, field: .reps
        ), 16)
        let corrected = CompletedWorkoutEditing.changingScore(
            in: session, for: block, field: .rounds, value: 4
        )
        XCTAssertEqual(corrected.wodResults.count, 1)
        XCTAssertEqual(corrected.wodResults[0].totalReps, 16)
        XCTAssertEqual(corrected.wodResults[0].roundsCompleted, 4)
        XCTAssertEqual(corrected.exercises[0].loggedSets[0].reps, 16)
        let saved = CompletedWorkoutEditing.applying(
            CompletedWorkoutEditing.routine(from: corrected),
            to: corrected, catalog: [exercise]
        )
        XCTAssertEqual(saved.wodResults.count, 1)
        XCTAssertEqual(saved.wodResults[0].summaryLabel, "4 rondas + 16 reps")
    }

    func testChangingWODFormatDropsIncompatibleStoredScore() {
        let exercise = Exercise(name: "Burpees", muscleGroup: "Otros")
        let block = RoutineBlock(
            title: "AMRAP", kind: .wod,
            movements: [WODMovement(exerciseId: exercise.id, name: exercise.name, reps: 10)],
            wodFormat: .amrap, timeCapMinutes: 8
        )
        var session = SessionController.from(
            routine: Routine(title: "Hecho", blocks: [block]), exercises: [exercise]
        )
        session.phase = .finished
        session.wodResults = [WODBlockResult(
            id: block.id, format: .amrap, totalReps: 5, roundsCompleted: 4
        )]
        var draft = CompletedWorkoutEditing.routine(from: session)
        draft.blocks[0].wodFormat = .forTime
        let saved = CompletedWorkoutEditing.applying(draft, to: session, catalog: [exercise])
        XCTAssertTrue(saved.wodResults.isEmpty)
        XCTAssertTrue(saved.exercises.allSatisfy { $0.loggedSets.isEmpty })
    }

    func testPlayExtraPendingSetsSurviveFinishCompletedEditorAndReload() throws {
        let squat = Exercise(name: "Sentadilla", muscleGroup: "Piernas")
        let base = Routine(title: "Escáner / plan", blocks: [
            .strength(exercises: [RoutineExercise(exerciseId: squat.id, plannedSets: [
                PlannedSet(targetReps: 8, targetWeightKg: 40),
                PlannedSet(targetReps: 8, targetWeightKg: 45)
            ])])
        ])
        var controller = SessionController(session: SessionController.from(
            routine: base, exercises: [squat]
        ))
        controller.startOnPhone()
        let exerciseID = try XCTUnwrap(controller.session.exercises.first?.id)
        var editedInPlay = controller.session.exercises[0].plannedSets
        editedInPlay[1].targetWeightKg = 47.5
        editedInPlay.append(PlannedSet(targetReps: 6, targetWeightKg: 50, targetRir: 2))
        XCTAssertTrue(controller.updateExerciseDraft(
            id: exerciseID, plannedSets: editedInPlay, quantityUnit: nil
        ))
        controller.confirmCurrentExercise()
        controller.logSet(reps: 8, weightKg: 42, rir: 1)
        controller.finishWorkout()

        let finished = controller.session
        let editor = CompletedWorkoutEditing.routine(from: finished)
        let rows = try XCTUnwrap(editor.blocks.first?.exercises.first?.plannedSets)
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows.map(\.targetWeightKg), [42, 47.5, 50])
        XCTAssertEqual(rows.map(\.targetReps), [8, 8, 6])
        XCTAssertEqual(rows[2].targetRir, 2)

        let saved = CompletedWorkoutEditing.applying(editor, to: finished, catalog: [squat])
        let reopened = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(saved)
        )
        XCTAssertEqual(reopened.exercises[0].plannedSets.count, 3)
        XCTAssertEqual(reopened.exercises[0].loggedSets.count, 1)
        XCTAssertEqual(reopened.exercises[0].loggedSets[0].weightKg, 42)
        XCTAssertEqual(reopened.exercises[0].plannedSets[2].targetWeightKg, 50)
        XCTAssertEqual(reopened.routineBlocks?[0].exercises[0].plannedSets.count, 3)

        var reopenedEditor = CompletedWorkoutEditing.routine(from: reopened)
        reopenedEditor.blocks[0].exercises[0].plannedSets[1].targetWeightKg = 52
        reopenedEditor.blocks[0].exercises[0].plannedSets.removeLast()
        let savedAgain = CompletedWorkoutEditing.applying(
            reopenedEditor, to: reopened, catalog: [squat]
        )
        XCTAssertEqual(savedAgain.exercises[0].plannedSets.count, 2)
        XCTAssertEqual(savedAgain.exercises[0].plannedSets[1].targetWeightKg, 52)
        XCTAssertEqual(savedAgain.exercises[0].loggedSets.count, 1)
        XCTAssertEqual(savedAgain.exercises[0].loggedSets[0].weightKg, 42)
    }

    func testCompletedSetEditAndNewPendingSetDoNotFabricateResult() throws {
        let rope = Exercise(name: "Comba", muscleGroup: "Cardio")
        let wod = RoutineBlock(
            title: "Every X", kind: .wod,
            movements: [WODMovement(
                exerciseId: rope.id, name: rope.name, reps: 25,
                explicitPlannedSets: [
                    PlannedSet(targetReps: 25, targetDurationSeconds: 40),
                    PlannedSet(targetReps: 25, targetDurationSeconds: 45)
                ]
            )],
            wodFormat: .emom, rounds: 2
        )
        var finished = SessionController.from(
            routine: Routine(title: "Pizarra", blocks: [wod]), exercises: [rope]
        )
        finished.phase = .finished
        let done = LoggedSet(
            reps: 20, durationSeconds: 33,
            completedAt: Date(timeIntervalSince1970: 1_700_000_000), rir: 2
        )
        finished.exercises[0].loggedSets = [done]

        var draft = CompletedWorkoutEditing.routine(from: finished)
        var rows = try XCTUnwrap(draft.blocks[0].movements[0].explicitPlannedSets)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows.map(\.targetDurationSeconds), [33, 45])
        rows[0].targetReps = 22
        rows[0].targetDurationSeconds = 37
        rows.append(PlannedSet(targetReps: 18, targetDurationSeconds: 50))
        draft.blocks[0].movements[0].explicitPlannedSets = rows

        let saved = CompletedWorkoutEditing.applying(draft, to: finished, catalog: [rope])
        XCTAssertEqual(saved.exercises[0].loggedSets.count, 1)
        XCTAssertEqual(saved.exercises[0].loggedSets[0].id, done.id)
        XCTAssertEqual(saved.exercises[0].loggedSets[0].completedAt, done.completedAt)
        XCTAssertEqual(saved.exercises[0].loggedSets[0].reps, 22)
        XCTAssertEqual(saved.exercises[0].loggedSets[0].durationSeconds, 37)
        XCTAssertEqual(saved.exercises[0].plannedSets.count, 3)
        XCTAssertEqual(saved.exercises[0].plannedSets[2].targetDurationSeconds, 50)
        XCTAssertTrue(saved.wodResults.isEmpty)

        let restored = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(saved)
        )
        let reopened = CompletedWorkoutEditing.routine(from: restored)
        XCTAssertEqual(reopened.blocks[0].movements[0].explicitPlannedSets?.count, 3)
        XCTAssertEqual(reopened.blocks[0].movements[0].explicitPlannedSets?[0].targetDurationSeconds, 37)
    }

    func testRemovingRecordedSetFromCompletedEditorDoesNotTurnPendingIntoPerformed() {
        let press = Exercise(name: "Press", muscleGroup: "Hombros")
        let routine = Routine(title: "Series", blocks: [
            .strength(exercises: [RoutineExercise(exerciseId: press.id, plannedSets: [
                PlannedSet(targetReps: 5), PlannedSet(targetReps: 5)
            ])])
        ])
        var finished = SessionController.from(routine: routine, exercises: [press])
        finished.phase = .finished
        finished.exercises[0].loggedSets = [LoggedSet(reps: 5, weightKg: 30)]
        var draft = CompletedWorkoutEditing.routine(from: finished)
        draft.blocks[0].exercises[0].plannedSets.removeFirst()
        let saved = CompletedWorkoutEditing.applying(draft, to: finished, catalog: [press])
        XCTAssertTrue(saved.exercises[0].loggedSets.isEmpty)
        XCTAssertEqual(saved.exercises[0].plannedSets.count, 1)
        XCTAssertEqual(saved.exercises[0].plannedSets[0].targetReps, 5)
    }

}
