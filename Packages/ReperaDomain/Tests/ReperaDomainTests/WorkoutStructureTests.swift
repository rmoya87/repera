import Foundation
import Testing
@testable import ReperaDomain

struct WorkoutStructureTests {
    @Test func nestedRepeatedAMRAPWithBuyInAndTeamContext() {
        var block = RoutineBlock.wod(format: .amrap, title: "5min AMRAP (x3)")
        block.timeCapMinutes = 5
        block.rounds = 3
        block.movements = [
            WODMovement(name: "Row", distanceMeters: 400),
            WODMovement(name: "Pull-up", reps: 5),
            WODMovement(name: "Push-up", reps: 10),
            WODMovement(name: "Air Squat", reps: 15),
        ]
        block.wodNotes = """
        Metcon
        5min AMRAP (x3)
        Buy in... 400/320m Row
        Max Rounds of (Cindy):
        5 Pull up
        10 Push up
        15 Air Squat
        2min Rest entre AMRAPs
        *Retoma el Cindy por donde lo dejaste
        """
        WorkoutStructureRecognition.attach(to: &block)
        let phase = block.structure?.phases.first
        #expect(phase?.repeatCount == 3)
        #expect(phase?.workSeconds == 300)
        #expect(phase?.restSeconds == 120)
        #expect(phase?.children.first?.kind == .buyIn)
        #expect(phase?.children.first?.movementIDs == [block.movements[0].id])
        #expect(phase?.children.last?.kind == .main)
        #expect(phase?.children.last?.movementIDs.count == 3)
    }

    @Test func partnerAndMaxEffortMetricsAreIndependentOfFormat() {
        var partner = RoutineBlock.wod(format: .emom, title: "EMOM 40' (TEAM II)")
        partner.movements = [WODMovement(name: "Clean and Jerk", reps: 60)]
        partner.wodNotes = "60 CLEAN & JERK (60/40)\n(I GO YOU GO)"
        WorkoutStructureRecognition.attach(to: &partner)
        #expect(partner.structure?.collaboration == .youGoIGo)
        #expect(partner.wodFormat == .emom)

        var maximum = RoutineBlock.wod(format: .maxEffort, title: "FIND A HEAVY 1RM")
        maximum.movements = [WODMovement(name: "Squat Clean", reps: 1)]
        WorkoutStructureRecognition.attach(to: &maximum)
        #expect(maximum.structure?.resultMetric == .loadKg)
        let result = WODBlockResult(id: maximum.id, format: .maxEffort,
                                    measuredValue: 87.5, measuredMetric: .loadKg)
        #expect(result.summaryLabel.contains("kg"))
        #expect(result.totalReps == nil)
    }

    @Test func precisionAndLegacyCodableRemainCompatible() throws {
        var block = RoutineBlock.wod(format: .forTime, title: "FOR TIME (TC 12:30)")
        block.movements = [WODMovement(name: "Box Jump", reps: 20)]
        WorkoutStructureRecognition.attach(to: &block)
        #expect(block.effectiveTimeCapSeconds == 750)
        let data = try JSONEncoder().encode(block)
        let restored = try JSONDecoder().decode(RoutineBlock.self, from: data)
        #expect(restored.timeCapSeconds == 750)

        var dict = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        dict.removeValue(forKey: "structure")
        dict.removeValue(forKey: "timeCapSeconds")
        let oldData = try JSONSerialization.data(withJSONObject: dict)
        let old = try JSONDecoder().decode(RoutineBlock.self, from: oldData)
        #expect(old.structure == nil)
        #expect(old.timeCapSeconds == nil)
    }

    @Test func copiedRoutineRemapsPhaseIDsInsteadOfReferencingOriginalExercises() {
        var block = RoutineBlock.wod(format: .partner, title: "Partner")
        block.movements = [WODMovement(name: "Box Jump", reps: 14)]
        block.structure = WorkoutStructure(collaboration: .sharedReps, phases: [
            WorkoutPhase(kind: .main, title: "Trabajo en equipo",
                         movementIDs: [block.movements[0].id]),
        ])
        let cloned = block.duplicatingContent()
        #expect(cloned.movements[0].id != block.movements[0].id)
        #expect(cloned.structure?.activeMovementIDs(in: cloned) == Set([cloned.movements[0].id]))
        #expect(cloned.structure?.activeMovementIDs(in: block).isEmpty == true)
    }
    @Test func advancedStrengthTechniquesRemainTypedAndCopyable() throws {
        let technique = WorkoutStrengthTechnique(
            method: .cluster, tempo: "31X1", pauseSeconds: 2,
            intraSetRestSeconds: 20, clusterReps: 3)
        #expect(technique.isValid)
        #expect(!WorkoutStrengthTechnique(method: .tempo, tempo: "abc").isValid)
        let original = PlannedSet(targetReps: 9, targetWeightKg: 70, technique: technique)
        let encoded = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(PlannedSet.self, from: encoded)
        #expect(restored.technique == technique)
        #expect(original.duplicatingContent().technique == technique)

        let movement = RoutineExercise(exerciseId: UUID(), plannedSets: [original])
        var strength = RoutineBlock.strength(title: "Superset", exercises: [movement])
        strength.structure = WorkoutStructure(phases: [
            WorkoutPhase(kind: .main, title: "Cluster",
                         movementIDs: [movement.id], technique: technique)
        ])
        #expect(strength.structure?.technique(for: movement.id) == technique)
    }

    @Test func perAthletePhaseResultsSurviveLegacyResultCodec() throws {
        let id = UUID()
        let phase = UUID()
        let results = [
            WorkoutPhaseResult(phaseID: phase, iteration: 1, participantIndex: 1, completedReps: 12),
            WorkoutPhaseResult(phaseID: phase, iteration: 1, participantIndex: 2, completedReps: 10),
            WorkoutPhaseResult(phaseID: phase, iteration: 2, participantIndex: 1, completedReps: 9)
        ]
        let wod = WODBlockResult(id: id, format: .amrap, phaseResults: results)
        #expect(wod.contribution(for: 1) == 21)
        #expect(wod.contribution(for: 2) == 10)
        let encoded = try JSONEncoder().encode(wod)
        let decoded = try JSONDecoder().decode(WODBlockResult.self, from: encoded)
        #expect(decoded.phaseResults?.count == 3)

        var legacy = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "phaseResults")
        let old = try JSONDecoder().decode(WODBlockResult.self,
            from: JSONSerialization.data(withJSONObject: legacy))
        #expect(old.phaseResults == nil)
        #expect(old.totalRecordedPhaseReps == 0)
    }

}
