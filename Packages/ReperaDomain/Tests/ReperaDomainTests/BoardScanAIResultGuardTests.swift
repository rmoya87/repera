import Testing
@testable import ReperaDomain

struct BoardScanAIResultGuardTests {
    @Test func rejectsInventedHeadersAndVideoLinksAsMovements() {
        var original = RoutineBlock.wod(format: .amrap, title: "AMRAP 14'")
        original.timeCapMinutes = 14
        original.movements = [WODMovement(name: "Box Jump", reps: 14)]

        var valid = original
        #expect(BoardScanAIResultGuard.isConsistent(
            localBlocks: [original], proposedBlocks: [valid]
        ))

        valid.movements.append(WODMovement(name: "Warm Up"))
        #expect(!BoardScanAIResultGuard.isConsistent(
            localBlocks: [original], proposedBlocks: [valid]
        ))

        valid.movements.removeLast()
        valid.movements.append(WODMovement(name: "https://youtu.be/abc"))
        #expect(!BoardScanAIResultGuard.isConsistent(
            localBlocks: [original], proposedBlocks: [valid]
        ))
    }

    @Test func rejectsLossOfTimeCapRoundsOrBlockBoundaries() {
        var original = RoutineBlock.wod(format: .forTime, title: "4 RFT TC 13'")
        original.timeCapMinutes = 13
        original.rounds = 4
        original.movements = [WODMovement(name: "Power Clean", reps: 3)]

        var changed = original
        changed.rounds = 13
        #expect(!BoardScanAIResultGuard.isConsistent(
            localBlocks: [original], proposedBlocks: [changed]
        ))
        changed = original
        changed.timeCapMinutes = 20
        #expect(!BoardScanAIResultGuard.isConsistent(
            localBlocks: [original], proposedBlocks: [changed]
        ))
        #expect(!BoardScanAIResultGuard.isConsistent(
            localBlocks: [original], proposedBlocks: [original, original]
        ))
    }

    @Test func preservesNativeStrengthSeriesInsteadOfReplacingWithPseudoWod() {
        let force = RoutineBlock.strength(
            title: "Back Squat · Find 5RM",
            exercises: [RoutineExercise(
                exerciseId: Catalog.seed()[0].id,
                plannedSets: [PlannedSet(targetReps: 5)]
            )]
        )
        let madeUp = RoutineBlock.wod(format: .strength, title: "Back Squat")
        #expect(!BoardScanAIResultGuard.isConsistent(
            localBlocks: [force], proposedBlocks: [madeUp]
        ))
    }
}
