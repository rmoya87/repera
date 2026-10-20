import Foundation
import Testing
@testable import ReperaDomain

@Suite("MovementPaceStandards")
struct MovementPaceStandardsTests {
    @Test func classifiesCommonMovements() {
        #expect(MovementPaceStandards.paceKind(forExerciseName: "Thruster") == .thruster)
        #expect(MovementPaceStandards.paceKind(forExerciseName: "Dominadas") == .pullUp)
        #expect(MovementPaceStandards.paceKind(forExerciseName: "Air squat") == .airSquat)
        #expect(MovementPaceStandards.paceKind(forExerciseName: "Burpees") == .burpee)
        #expect(MovementPaceStandards.paceKind(forExerciseName: "Double unders") == .doubleUnder)
        #expect(MovementPaceStandards.paceKind(forExerciseName: "Remoergómetro") == .rowCal)
    }

    @Test func franPrescriptionIntermediateNearTypical() {
        let fran = CatalogWODs.template(id: "fran")!
        let lines = WODPaceEstimator.prescription(fromMovements: fran.movements)
        #expect(lines.count == 6)
        let estimate = WODPaceEstimator.estimateForTime(lines: lines, rounds: 1)
        let mid = estimate.expectedSeconds(for: .intermediate) ?? 0
        let elite = estimate.expectedSeconds(for: .elite) ?? 0
        // Fran típico ~5′; intermedio estimado en zona realista 5–10′ (con roturas).
        #expect(mid >= 5 * 60)
        #expect(mid <= 10 * 60)
        #expect(elite < mid)
        #expect(elite <= 6 * 60)
    }

    @Test func cindyAMRAPIntermediateAroundTenToFifteen() {
        let cindy = CatalogWODs.template(id: "cindy")!
        let lines = WODPaceEstimator.prescription(fromMovements: cindy.movements)
        let estimate = WODPaceEstimator.estimateAMRAP(roundLines: lines, windowSeconds: 20 * 60)
        let mid = estimate.expectedRounds(for: .intermediate) ?? 0
        #expect(mid >= 8)
        #expect(mid <= 16)
    }

    @Test func customForTimeUsesMovementPaceBasis() {
        let blockId = UUID()
        let session = WorkoutSession(
            title: "WOD a medida",
            exercises: [
                SessionExercise(
                    exercise: Exercise(name: "Thruster", muscleGroup: "Piernas", equipment: "Barra"),
                    plannedSets: [PlannedSet(targetReps: 21, targetWeightKg: 40)],
                    loggedSets: [],
                    isCompleted: true,
                    blockId: blockId,
                    blockKind: .wod,
                    wodFormat: .forTime
                ),
                SessionExercise(
                    exercise: Exercise(name: "Dominadas", muscleGroup: "Espalda", equipment: "Peso corporal"),
                    plannedSets: [PlannedSet(targetReps: 21, targetWeightKg: nil)],
                    loggedSets: [],
                    isCompleted: true,
                    blockId: blockId,
                    blockKind: .wod,
                    wodFormat: .forTime
                ),
            ],
            phase: .finished,
            startedAt: Date().addingTimeInterval(-300),
            finishedAt: Date(),
            wodResults: [
                WODBlockResult(
                    id: blockId,
                    format: .forTime,
                    elapsedSeconds: 5 * 60,
                    wodTemplateId: nil
                ),
            ]
        )
        let review = SessionReviewEngine.review(session: session, history: [])
        #expect(review?.scoreBasis == .movementPace)
        #expect(review?.level != nil)
        #expect((review?.overallScore ?? 0) >= 3)
        #expect((review?.overallScore ?? 0) <= 10)
        #expect(review?.vsStandardSummary?.contains("ritmo") == true
            || review?.vsStandardSummary?.contains("Tu tiempo") == true
            || review?.vsStandardSummary?.contains("Hiciste") == true)
    }

    @Test func levelMultipliersAreOrdered() {
        let thruster = MovementPaceKind.thruster
        let elite = MovementPaceStandards.secondsPerUnit(thruster, level: .elite)
        let mid = MovementPaceStandards.secondsPerUnit(thruster, level: .intermediate)
        let beg = MovementPaceStandards.secondsPerUnit(thruster, level: .beginner)
        #expect(elite < mid)
        #expect(mid < beg)
    }
}
