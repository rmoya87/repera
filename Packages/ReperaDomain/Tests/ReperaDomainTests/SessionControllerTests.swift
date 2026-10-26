import XCTest
@testable import ReperaDomain

final class SessionControllerTests: XCTestCase {
    func testScheduledBTTAndT2BRelinkOldIdsToCatalog() {
        let catalog = Catalog.seed()
        guard let target = catalog.first(where: { $0.name == "Burpee to target" }),
              let toes = catalog.first(where: { $0.name == "Toes to bar" }) else {
            XCTFail("El catálogo debe incluir BTT y T2B")
            return
        }
        // Reproducción del estado local real: fichas provisionales que
        // comparten nombre con la oficial y fueron guardadas antes del seed.
        let provisional = Exercise(name: "Burpee to target", muscleGroup: "Custom", isCustom: true)
        let oldToes = Exercise(name: "Toes to bar", muscleGroup: "Custom", isCustom: true)
        XCTAssertEqual(CrossFitGlossary.resolveCatalogName("BTt"), "Burpee to target")
        XCTAssertEqual(CrossFitGlossary.resolveCatalogName("T2B"), "Toes to bar")
        var wod = RoutineBlock.wod(format: .emom, title: "EMOM 16'")
        wod.movements = [
            WODMovement(exerciseId: provisional.id, name: "BTt", reps: 8),
            WODMovement(exerciseId: oldToes.id, name: "T2B", reps: 10)
        ]
        let session = SessionController.from(
            routine: Routine(title: "Mañana", blocks: [wod]),
            exercises: [provisional, oldToes] + catalog
        )
        XCTAssertEqual(session.exercises.count, 2)
        XCTAssertEqual(session.exercises[0].exercise.id, target.id)
        XCTAssertEqual(session.exercises[1].exercise.id, toes.id)
        XCTAssertFalse(session.exercises[0].exercise.isCustom)
        XCTAssertFalse(session.exercises[1].exercise.isCustom)
    }
    func testEditedPlaySetsPersistAfterFinishAndCodableRoundTrip() throws {
        let lift = Exercise(name: "Sentadilla", muscleGroup: "Piernas")
        let entry = RoutineExercise(
            exerciseId: lift.id,
            plannedSets: [PlannedSet(targetReps: 5, targetWeightKg: 60)]
        )
        let block = RoutineBlock.strength(title: "Fuerza", exercises: [entry])
        var controller = SessionController(
            session: SessionController.from(
                routine: Routine(title: "Escáner", blocks: [block]), exercises: [lift]
            )
        )
        controller.startOnPhone()
        XCTAssertEqual(controller.session.currentExercise?.id, entry.id)
        let edited = [
            PlannedSet(targetReps: 5, targetWeightKg: 72.5, targetRir: 2),
            PlannedSet(targetReps: 4, targetWeightKg: 80, targetRir: 1),
            PlannedSet(targetReps: 3, targetWeightKg: 85, targetRir: 0),
        ]
        XCTAssertTrue(controller.updateExerciseDraft(
            id: entry.id, plannedSets: edited, quantityUnit: nil
        ))
        controller.logSet(reps: 5, weightKg: 72.5)
        controller.finishWorkout()

        let saved = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(controller.session)
        )
        XCTAssertEqual(saved.exercises[0].plannedSets, edited)
        XCTAssertEqual(saved.routineBlocks?.first?.exercises.first?.plannedSets, edited)
        XCTAssertEqual(saved.exercises[0].loggedSets.count, 1)
        XCTAssertEqual(saved.exercises[0].loggedSets.first?.weightKg, 72.5)
        XCTAssertEqual(saved.exercises[0].isCompleted, true)
    }

    func testAutosaveRecordedSetEditsWithoutChecksAndKeepIDs() throws {
        let squat = Exercise(name: "Back Squat", muscleGroup: "Piernas")
        let item = RoutineExercise(exerciseId: squat.id, plannedSets: [
            PlannedSet(targetReps: 5, targetWeightKg: 50),
            PlannedSet(targetReps: 5, targetWeightKg: 50)
        ])
        var controller = SessionController(session: SessionController.from(
            routine: Routine(title: "Fuerza", blocks: [
                .strength(title: "Sentadilla", exercises: [item])
            ]), exercises: [squat]
        ))
        controller.startOnPhone()
        let firstID = UUID()
        let secondID = UUID()
        let first = LoggedSet(id: firstID, reps: 5, weightKg: 65, rir: 2)
        let second = LoggedSet(id: secondID, reps: 4, weightKg: 67.5, rir: 1)
        XCTAssertTrue(controller.replaceRecordedSets(
            exerciseID: item.id, sets: [first, second]
        ))
        XCTAssertEqual(controller.session.currentExercise?.loggedSets.map(\.id), [firstID, secondID])
        XCTAssertFalse(controller.replaceRecordedSets(
            exerciseID: item.id, sets: [first, second]
        ))

        var revised = first
        revised.weightKg = 70
        revised.reps = 6
        XCTAssertTrue(controller.replaceRecordedSets(
            exerciseID: item.id, sets: [revised, second]
        ))
        XCTAssertEqual(controller.session.currentExercise?.loggedSets.count, 2)
        XCTAssertEqual(controller.session.currentExercise?.completedReps, 10)
        XCTAssertEqual(controller.session.totalVolumeKg, 690, accuracy: 0.001)
        controller.finishWorkout()
        let restored = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(controller.session)
        )
        XCTAssertEqual(restored.exercises[0].loggedSets.map(\.id), [firstID, secondID])
        XCTAssertEqual(restored.exercises[0].loggedSets.first?.weightKg, 70)
        XCTAssertEqual(restored.totalVolumeKg, 690, accuracy: 0.001)
        XCTAssertTrue(restored.exercises[0].isCompleted)
    }

    func testRepeatedExerciseEditsRemainAttachedToCorrectOccurrence() throws {
        let lift = Exercise(name: "Peso muerto", muscleGroup: "Piernas")
        let first = RoutineExercise(
            exerciseId: lift.id, plannedSets: [PlannedSet(targetReps: 5, targetWeightKg: 50)]
        )
        let second = RoutineExercise(
            exerciseId: lift.id, plannedSets: [PlannedSet(targetReps: 3, targetWeightKg: 100)]
        )
        let block = RoutineBlock.strength(title: "Dos tandas", exercises: [first, second])
        let routine = Routine(title: "Dos tandas", blocks: [block])
        var controller = SessionController(
            session: SessionController.from(routine: routine, exercises: [lift])
        )
        let modified = [PlannedSet(targetReps: 2, targetWeightKg: 120)]
        XCTAssertTrue(controller.updateExerciseDraft(
            id: second.id, plannedSets: modified, quantityUnit: nil
        ))
        XCTAssertEqual(controller.session.exercises[0].plannedSets.first?.targetWeightKg, 50)
        XCTAssertEqual(controller.session.exercises[1].plannedSets, modified)
        XCTAssertEqual(controller.session.routineBlocks?[0].exercises[0].plannedSets.first?.targetWeightKg, 50)
        XCTAssertEqual(controller.session.routineBlocks?[0].exercises[1].plannedSets, modified)
        // El orden del editor puede cambiar; los IDs estables mantienen la identidad.
        var reordered = routine
        reordered.blocks[0].exercises.swapAt(0, 1)
        let fresh = SessionController.from(routine: reordered, exercises: [lift])
        XCTAssertEqual(fresh.exercises.map(\.id), [second.id, first.id])
    }

    func testEditedWODMovementSnapshotPreservesBlockScore() throws {
        let movement = WODMovement(name: "Burpee", reps: 10)
        var block = RoutineBlock.wod(format: .forTime, title: "3 RFT")
        block.rounds = 3
        block.movements = [movement]
        var controller = SessionController(
            session: SessionController.from(
                routine: Routine(title: "Pizarra", blocks: [block]), exercises: []
            )
        )
        let adjusted = [
            PlannedSet(targetReps: 12),
            PlannedSet(targetReps: 12),
            PlannedSet(targetReps: 8),
            PlannedSet(targetReps: 8),
        ]
        XCTAssertTrue(controller.updateExerciseDraft(
            id: movement.id, plannedSets: adjusted, quantityUnit: nil
        ))
        XCTAssertEqual(controller.session.exercises[0].loggedSets.count, 0)
        XCTAssertEqual(
            controller.session.routineBlocks?[0].movements[0].explicitPlannedSets, adjusted
        )
        controller.startOnPhone()
        controller.finishWorkout()
        let restored = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(controller.session)
        )
        XCTAssertEqual(restored.exercises[0].plannedSets.count, 4)
        XCTAssertEqual(restored.routineBlocks?[0].movements[0].explicitPlannedSets?.count, 4)
        XCTAssertTrue(restored.wodResults.isEmpty)
    }

    func testDraftNeverReplacesConfirmedLoggedSets() {
        let lift = Exercise(name: "Press", muscleGroup: "Pecho")
        let entry = RoutineExercise(
            exerciseId: lift.id, plannedSets: [
                PlannedSet(targetReps: 8, targetWeightKg: 40),
                PlannedSet(targetReps: 8, targetWeightKg: 40),
            ]
        )
        let routine = Routine(title: "Press", blocks: [
            .strength(title: "Fuerza", exercises: [entry])
        ])
        var controller = SessionController(
            session: SessionController.from(routine: routine, exercises: [lift])
        )
        controller.startOnPhone()
        controller.logSet(reps: 7, weightKg: 45)
        let recorded = controller.session.exercises[0].loggedSets
        XCTAssertTrue(controller.updateExerciseDraft(
            id: entry.id, plannedSets: [
                PlannedSet(targetReps: 7, targetWeightKg: 45),
                PlannedSet(targetReps: 10, targetWeightKg: 50),
                PlannedSet(targetReps: 6, targetWeightKg: 55),
            ], quantityUnit: nil
        ))
        XCTAssertEqual(controller.session.exercises[0].loggedSets, recorded)
        XCTAssertEqual(controller.session.exercises[0].plannedSets.count, 3)
    }

    func testLivePlayEditsMoreOrFewerSetsAndWeightsPersistWithoutInventingLoggedSets() throws {
        let squat = Exercise(name: "Sentadilla", muscleGroup: "Piernas")
        let item = RoutineExercise(exerciseId: squat.id, plannedSets: [
            PlannedSet(targetReps: 5, targetWeightKg: 60),
            PlannedSet(targetReps: 5, targetWeightKg: 60)
        ])
        let block = RoutineBlock.strength(title: "Fuerza", exercises: [item])
        let routine = Routine(title: "Escaneado", blocks: [block])
        var session = SessionController.from(routine: routine, exercises: [squat])
        XCTAssertEqual(session.exercises.first?.id, item.id)
        session.exercises[0].loggedSets = [LoggedSet(reps: 5, weightKg: 65, rir: 2)]
        var controller = SessionController(session: session)
        let updated = [
            PlannedSet(targetReps: 5, targetWeightKg: 65),
            PlannedSet(targetReps: 6, targetWeightKg: 72.5),
            PlannedSet(targetReps: 7, targetWeightKg: 75)
        ]
        XCTAssertTrue(controller.updateExerciseDraft(
            id: item.id, plannedSets: updated, quantityUnit: nil
        ))
        XCTAssertEqual(controller.session.exercises[0].plannedSets, updated)
        XCTAssertEqual(controller.session.routineBlocks?[0].exercises[0].plannedSets, updated)
        XCTAssertEqual(controller.session.exercises[0].loggedSets.count, 1)
        XCTAssertEqual(controller.session.exercises[0].loggedSets[0].weightKg, 65)

        var shortened = updated
        shortened.removeLast()
        XCTAssertTrue(controller.updateExerciseDraft(
            id: item.id, plannedSets: shortened, quantityUnit: nil
        ))
        controller.finishWorkout()
        let persisted = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(controller.session)
        )
        XCTAssertEqual(persisted.routineBlocks?[0].exercises[0].plannedSets, shortened)
        XCTAssertEqual(persisted.exercises[0].plannedSets, shortened)
        XCTAssertEqual(persisted.exercises[0].loggedSets.count, 1)
    }

    func testRepeatedExerciseEditTargetsOnlyCorrectOccurrence() {
        let squat = Exercise(name: "Sentadilla", muscleGroup: "Piernas")
        let first = RoutineExercise(exerciseId: squat.id, plannedSets: [
            PlannedSet(targetReps: 3, targetWeightKg: 80)
        ])
        let second = RoutineExercise(exerciseId: squat.id, plannedSets: [
            PlannedSet(targetReps: 8, targetWeightKg: 40)
        ])
        let block = RoutineBlock.strength(title: "Dos variantes", exercises: [first, second])
        var controller = SessionController(session: SessionController.from(
            routine: Routine(title: "Mismo ejercicio", blocks: [block]),
            exercises: [squat]
        ))
        let updated = [PlannedSet(targetReps: 10, targetWeightKg: 45)]
        XCTAssertTrue(controller.updateExerciseDraft(
            id: second.id, plannedSets: updated, quantityUnit: nil
        ))
        XCTAssertEqual(controller.session.exercises[0].plannedSets, first.plannedSets)
        XCTAssertEqual(controller.session.exercises[1].plannedSets, updated)
        XCTAssertEqual(controller.session.routineBlocks?[0].exercises[0].plannedSets, first.plannedSets)
        XCTAssertEqual(controller.session.routineBlocks?[0].exercises[1].plannedSets, updated)
    }

    func testScannedRFTMovementRetainsEditedSetsWithOriginalScore() throws {
        let burpee = Exercise(name: "Burpees", muscleGroup: "Otros")
        let move = WODMovement(exerciseId: burpee.id, name: burpee.name, reps: 12)
        let block = RoutineBlock(
            title: "RFT", kind: .wod, movements: [move],
            wodFormat: .forTime, rounds: 4
        )
        var session = SessionController.from(
            routine: Routine(title: "Pizarra", blocks: [block]),
            exercises: [burpee]
        )
        session.wodResults = [WODBlockResult(id: block.id, format: .forTime, elapsedSeconds: 793)]
        var controller = SessionController(session: session)
        let edited = [
            PlannedSet(targetReps: 10),
            PlannedSet(targetReps: 11),
            PlannedSet(targetReps: 12),
            PlannedSet(targetReps: 13),
            PlannedSet(targetReps: 14)
        ]
        XCTAssertTrue(controller.updateExerciseDraft(
            id: move.id, plannedSets: edited, quantityUnit: nil
        ))
        controller.finishWorkout()
        let restored = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(controller.session)
        )
        XCTAssertEqual(restored.exercises[0].plannedSets.count, 5)
        XCTAssertEqual(restored.routineBlocks?[0].movements[0].explicitPlannedSets, edited)
        XCTAssertEqual(restored.wodResults[0].elapsedSeconds, 793)
        XCTAssertTrue(restored.exercises[0].loggedSets.isEmpty)
    }

    func testCardioUnitsPersistFromRoutineIntoWorkoutAndThroughJSON() throws {
        let bike = Exercise(name: "Air Bike", muscleGroup: "Cardio")
        let block = RoutineBlock.strength(
            title: "Bike",
            exercises: [RoutineExercise(
                exerciseId: bike.id,
                plannedSets: [PlannedSet(targetReps: 500)],
                quantityUnit: .meters
            )]
        )
        let routine = Routine(title: "Cardio", blocks: [block])
        let restored = try JSONDecoder().decode(Routine.self, from: JSONEncoder().encode(routine))
        XCTAssertEqual(restored.blocks.first?.exercises.first?.quantityUnit, .meters)
        let session = SessionController.from(routine: restored, exercises: [bike])
        XCTAssertEqual(session.currentExercise?.quantityUnit, .meters)
        XCTAssertEqual(session.currentExercise?.plannedSets.first?.targetReps, 500)
    }

    func testStrengthBlocksRetainOptionalTimerFormatsInPlay() {
        let exercise = Exercise(name: "Back Squat", muscleGroup: "Piernas")
        var amrap = RoutineBlock.strength(
            title: "Bloque 1",
            exercises: [RoutineExercise(
                exerciseId: exercise.id,
                plannedSets: [PlannedSet(targetReps: 8, targetWeightKg: 60)]
            )]
        )
        amrap.wodFormat = .amrap
        amrap.timeCapMinutes = 14
        let routine = Routine(title: "Sesión", blocks: [amrap])
        let session = SessionController.from(routine: routine, exercises: [exercise])
        XCTAssertEqual(session.exercises.count, 1)
        XCTAssertEqual(session.currentExercise?.wodFormat, .amrap)
        XCTAssertEqual(session.currentExercise?.blockTimeCapMinutes, 14)
        XCTAssertEqual(session.currentExercise?.blockHeader, "Bloque 1")
        XCTAssertEqual(session.currentExercise?.plannedSets.first?.targetWeightKg, 60)
    }

    func testStrengthBlockWithoutFormatOpensAsFreeClock() {
        let exercise = Exercise(name: "Push-up", muscleGroup: "Pecho")
        let block = RoutineBlock.strength(
            title: "Bloque libre",
            exercises: [RoutineExercise(
                exerciseId: exercise.id,
                plannedSets: [PlannedSet(targetReps: 10)]
            )]
        )
        let routine = Routine(title: "Libre", blocks: [block])
        let session = SessionController.from(routine: routine, exercises: [exercise])
        XCTAssertNil(session.currentExercise?.wodFormat)
        XCTAssertNil(session.currentExercise?.blockTimeCapMinutes)
        XCTAssertEqual(session.currentExercise?.blockHeader, "Bloque libre")
    }

    func testStrengthBlockEmomDerivesIntervalsFromTimeCap() {
        let exercise = Exercise(name: "Deadlift", muscleGroup: "Piernas")
        var block = RoutineBlock.strength(
            title: "Deadlift Every 2",
            exercises: [RoutineExercise(
                exerciseId: exercise.id,
                plannedSets: [PlannedSet(targetReps: 4)]
            )]
        )
        block.wodFormat = .emom
        block.timeCapMinutes = 12
        block.emomIntervalSeconds = 120
        let session = SessionController.from(
            routine: Routine(title: "Strength", blocks: [block]),
            exercises: [exercise]
        )
        XCTAssertEqual(session.currentExercise?.plannedIntervals, 6)
        XCTAssertEqual(session.currentExercise?.blockIntervalSeconds, 120)
    }

    func testTimedBlockFinishesAllItsMovementsWithoutCreatingSets() {
        var emom = RoutineBlock.wod(format: .emom, title: "EMOM")
        emom.movements = [WODMovement(name: "Push-up", reps: 10), WODMovement(name: "Squat", reps: 10)]
        var next = RoutineBlock.wod(format: .emom, title: "EMOM 2")
        next.movements = [WODMovement(name: "Burpee", reps: 10)]
        let routine = Routine(title: "Test", blocks: [emom, next])
        var controller = SessionController(
            session: SessionController.from(routine: routine, exercises: [])
        )
        controller.startOnPhone()
        XCTAssertEqual(controller.session.exercises.count, 3)

        let hasNext = controller.finishCurrentBlock()
        XCTAssertTrue(hasNext)
        XCTAssertEqual(controller.session.currentIndex, 2)
        XCTAssertEqual(controller.session.phase, .ready)
        XCTAssertTrue(controller.session.exercises[0].isCompleted)
        XCTAssertTrue(controller.session.exercises[1].isCompleted)
        XCTAssertFalse(controller.session.exercises[2].isCompleted)
        XCTAssertTrue(controller.session.exercises.allSatisfy { $0.loggedSets.isEmpty })
    }

    func testFinalTimedBlockFinishesWorkout() {
        var emom = RoutineBlock.wod(format: .emom, title: "EMOM")
        emom.movements = [WODMovement(name: "Burpee", reps: 10)]
        let routine = Routine(title: "Test", blocks: [emom])
        var controller = SessionController(
            session: SessionController.from(routine: routine, exercises: [])
        )
        controller.startOnPhone()
        let hasNext = controller.finishCurrentBlock()
        XCTAssertFalse(hasNext)
        XCTAssertEqual(controller.session.phase, .finished)
        XCTAssertNotNil(controller.session.finishedAt)
        XCTAssertTrue(controller.session.exercises[0].isCompleted)
        XCTAssertTrue(controller.session.exercises[0].loggedSets.isEmpty)
    }

    func testConfirmAndFinishAdvances() {
        var controller = SessionController(session: SessionController.demoPushPull())
        controller.startOnPhone()
        XCTAssertEqual(controller.session.phase, SessionPhase.ready)
        XCTAssertFalse(controller.session.exercises.isEmpty)

        controller.confirmCurrentExercise()
        XCTAssertEqual(controller.session.phase, SessionPhase.counting)

        controller.setRepCount(8)
        XCTAssertEqual(controller.session.currentExercise?.completedReps, 8)

        let hasNext = controller.finishCurrentExercise()
        XCTAssertTrue(hasNext)
        XCTAssertEqual(controller.session.phase, SessionPhase.ready)
    }

    func testLogSetAndFinishWorkout() {
        var controller = SessionController(session: SessionController.demoPushPull())
        controller.startOnPhone()
        controller.logSet(reps: 8, weightKg: 60)
        XCTAssertEqual(controller.session.currentExercise?.loggedSets.count, 1)
        controller.finishWorkout()
        XCTAssertEqual(controller.session.phase, SessionPhase.finished)
        XCTAssertNotNil(controller.session.finishedAt)
    }

    func testWatchCommitReps() {
        var controller = SessionController(session: SessionController.demoPushPull())
        controller.startOnPhone()
        controller.confirmCurrentExercise()
        controller.setRepCount(12)
        controller.commitWatchRepsAsSet(weightKg: 40)
        XCTAssertEqual(controller.session.currentExercise?.loggedSets.last?.reps, 12)
    }

    func testMotionRepCounterDetectsPeak() {
        var counter = MotionRepCounter(threshold: 1.2, minInterval: 0.1)
        let t0 = Date()
        counter.ingest(magnitude: 1.0, at: t0)
        counter.ingest(magnitude: 1.5, at: t0.addingTimeInterval(0.05))
        counter.ingest(magnitude: 1.1, at: t0.addingTimeInterval(0.1))
        XCTAssertEqual(counter.count, 1)

        counter.applyManualDelta(1)
        XCTAssertEqual(counter.count, 2)
        counter.applyManualDelta(-5)
        XCTAssertEqual(counter.count, 0)
    }

    func testStatsPersonalRecords() {
        var controller = SessionController(session: SessionController.demoPushPull())
        controller.startOnPhone()
        controller.logSet(reps: 5, weightKg: 100)
        controller.finishWorkout()
        let prs = StatsEngine.personalRecords(from: [controller.session])
        XCTAssertFalse(prs.isEmpty)
    }

    func testDefaultWeekPlanLinksExercises() {
        let exercises = Catalog.seed()
        let plan = Catalog.defaultWeekPlan(exercises: exercises)
        XCTAssertFalse(plan.isEmpty)
        for routine in plan {
            for item in routine.exercises {
                XCTAssertTrue(exercises.contains { $0.id == item.exerciseId })
            }
        }
    }

    func testEmomExpandsPlannedSetsByRounds() {
        let catalog = Catalog.seed()
        var emom = RoutineBlock.wod(format: .emom, title: "EMOM 12'")
        emom.timeCapMinutes = 12
        emom.emomIntervalSeconds = 60
        emom.rounds = 4
        emom.movements = [
            WODMovement(name: "Pull-up", reps: 5),
            WODMovement(name: "HSPU", reps: 8),
            WODMovement(name: "REST", isRest: true, restSeconds: 60),
        ]
        let strength = RoutineBlock.strength(
            title: "Fuerza",
            exercises: [
                RoutineExercise(
                    exerciseId: catalog[0].id,
                    plannedSets: (0..<5).map { _ in PlannedSet(targetReps: 5) }
                ),
            ]
        )
        let routine = Routine(title: "Test", blocks: [strength, emom])
        let session = SessionController.from(routine: routine, exercises: catalog)

        XCTAssertEqual(session.exercises.first?.plannedSets.count, 5)
        let pull = session.exercises.first {
            $0.exercise.name.localizedCaseInsensitiveContains("pull")
                || $0.exercise.name.localizedCaseInsensitiveContains("dominad")
        }
        XCTAssertEqual(pull?.plannedSets.count, 4)
        XCTAssertEqual(pull?.blockRounds, 4)
        XCTAssertEqual(pull?.plannedIntervals, 12)
        let hspu = session.exercises.first { $0.exercise.name.localizedCaseInsensitiveContains("HSPU") }
        XCTAssertEqual(hspu?.plannedSets.count, 4)
        XCTAssertFalse(session.exercises.contains { $0.exercise.name == "REST" })
    }

    func testRFTExpandsSetsChipperDoesNot() {
        var rft = RoutineBlock.wod(format: .forTime, title: "4 RFT")
        rft.rounds = 4
        rft.movements = [WODMovement(name: "Burpee", reps: 10)]
        var chipper = RoutineBlock.wod(format: .chipper, title: "Chipper")
        chipper.movements = [WODMovement(name: "Run", distanceMeters: 400)]
        let routine = Routine(title: "T", blocks: [rft, chipper])
        let session = SessionController.from(routine: routine, exercises: [])
        XCTAssertEqual(session.exercises.first { $0.exercise.name == "Burpee" }?.plannedSets.count, 4)
        // Run se normaliza al nombre canónico del catálogo en español.
        XCTAssertEqual(session.exercises.first {
            $0.exercise.name == CrossFitGlossary.canonicalName(for: "Run")
        }?.plannedSets.count, 1)
    }

    func testWaveSchemeNotMultipliedAgain() {
        var emom = RoutineBlock.wod(format: .emom, title: "EMOM")
        emom.timeCapMinutes = 12
        emom.rounds = 4
        emom.movements = [
            WODMovement(name: "Push press", repScheme: [4, 4, 3, 3]),
        ]
        let session = SessionController.from(
            routine: Routine(title: "T", blocks: [emom]),
            exercises: []
        )
        XCTAssertEqual(session.exercises.first?.plannedSets.count, 4)
        XCTAssertEqual(session.exercises.first?.plannedSets.map(\.targetReps), [4, 4, 3, 3])
    }

    func testAscendingRepRangeExpandsToEmomRounds() {
        var emom = RoutineBlock.wod(format: .emom, title: "EMOM 12'")
        emom.timeCapMinutes = 12
        emom.emomIntervalSeconds = 60
        emom.rounds = 4
        emom.movements = [
            WODMovement(name: "Pull-up", repScheme: [4, 3, 3, 2]),
            WODMovement(name: "HSPU", repScheme: [5, 10]), // rango, no ola
            WODMovement(name: "REST", isRest: true, restSeconds: 60),
        ]
        let session = SessionController.from(
            routine: Routine(title: "T", blocks: [emom]),
            exercises: []
        )
        let pull = session.exercises.first {
            $0.exercise.name.localizedCaseInsensitiveContains("pull")
                || $0.exercise.name.localizedCaseInsensitiveContains("dominad")
        }
        XCTAssertEqual(pull?.plannedSets.map(\.targetReps), [4, 3, 3, 2])
        let hspu = session.exercises.first { $0.exercise.name.localizedCaseInsensitiveContains("HSPU") }
        XCTAssertEqual(hspu?.plannedSets.count, 4)
        XCTAssertEqual(hspu?.plannedSets.map(\.targetReps), [10, 10, 10, 10])
    }

    func testWODResultCaptureFollowsFormatInsteadOfExerciseSets() {
        XCTAssertEqual(WODFormat.amrap.resultCapture, .totalReps)
        XCTAssertEqual(WODFormat.deathBy.resultCapture, .totalReps)
        XCTAssertEqual(WODFormat.maxEffort.resultCapture, .totalReps)
        for format in [WODFormat.forTime, .chipper, .afap, .ladder, .buyInCashOut] {
            XCTAssertEqual(format.resultCapture, .elapsedTime)
        }
        for format in [WODFormat.emom, .tabata, .circuit, .partner,
                       .roundsForQuality, .strength] {
            XCTAssertEqual(format.resultCapture, .perMovementSets)
        }
        let amrap = WODBlockResult(id: UUID(), format: .amrap, totalReps: 7, roundsCompleted: 5)
        XCTAssertEqual(amrap.summaryLabel, "5 rondas + 7 reps")
        let forTime = WODBlockResult(id: UUID(), format: .forTime, elapsedSeconds: 731)
        XCTAssertEqual(forTime.summaryLabel, "12:11")
    }

    func testTabataWorkIntervalsAreDistributedAcrossMovements() {
        var tabata = RoutineBlock.wod(format: .tabata)
        tabata.rounds = 8
        tabata.workSeconds = 20
        tabata.restSeconds = 10
        tabata.movements = [
            WODMovement(name: "Burpee", reps: 7),
            WODMovement(name: "Air Squat", reps: 12),
        ]
        let session = SessionController.from(
            routine: Routine(title: "Tabata", blocks: [tabata]), exercises: []
        )
        XCTAssertEqual(session.exercises.count, 2)
        XCTAssertEqual(session.exercises.map { $0.plannedSets.count }, [4, 4])
        XCTAssertTrue(session.exercises.allSatisfy { $0.blockWorkSeconds == 20 })
        XCTAssertTrue(session.exercises.allSatisfy { $0.blockRestSeconds == 10 })
        XCTAssertTrue(session.exercises.allSatisfy { $0.usesBlockScoreResult == false })
    }

    func testCircuitRestBetweenRoundsPersistsIntoWorkoutAndJSON() throws {
        var circuit = RoutineBlock.wod(format: .circuit)
        circuit.timeCapMinutes = nil
        circuit.rounds = 3
        circuit.emomIntervalSeconds = 45
        circuit.restBetweenRoundsSeconds = 25
        circuit.movements = [
            WODMovement(name: "Push-up", reps: 10),
            WODMovement(name: "Air Squat", reps: 12),
        ]
        let session = SessionController.from(
            routine: Routine(title: "Circuito", blocks: [circuit]), exercises: []
        )
        XCTAssertEqual(session.exercises.map { $0.plannedSets.count }, [3, 3])
        XCTAssertTrue(session.exercises.allSatisfy { $0.blockRestBetweenRoundsSeconds == 25 })
        let decoded = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(session))
        XCTAssertTrue(decoded.exercises.allSatisfy { $0.blockRestBetweenRoundsSeconds == 25 })
    }

    func testShortWavePadsWithLastRepForEmomRounds() {
        var emom = RoutineBlock.wod(format: .emom, title: "EMOM 12'")
        emom.timeCapMinutes = 12
        emom.rounds = 4
        emom.movements = [
            WODMovement(name: "Push press", repScheme: [4, 3, 3]), // 3 números, 4 rondas → 4-3-3-3
        ]
        let session = SessionController.from(
            routine: Routine(title: "T", blocks: [emom]),
            exercises: []
        )
        XCTAssertEqual(session.exercises.first?.plannedSets.map(\.targetReps), [4, 3, 3, 3])
    }
}
