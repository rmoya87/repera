import XCTest
@testable import ReperaDomain

final class AbbreviatedWODCatalogTests: XCTestCase {
    func testBTTAndT2BResolveAgainstPackagedCatalogEvenWithProvisionalIDs() {
        let seed = Catalog.seed()
        for (raw, expected) in [("BTt", "Burpee to target"), ("T2B", "Toes to bar")] {
            let provisional = Exercise(name: raw, muscleGroup: "WOD", isCustom: true)
            let movement = WODMovement(exerciseId: provisional.id, name: raw, reps: 8)
            let match = CrossFitGlossary.catalogExercise(
                for: movement, in: [provisional] + seed
            )
            XCTAssertEqual(match?.name, expected)
            XCTAssertEqual(match?.isCustom, false)
        }
    }

    func testProvisionalAbbreviationsAreNotAcceptedAsOfficialCatalogMatches() {
        for raw in ["btt", "T2B"] {
            let provisional = Exercise(name: raw, muscleGroup: "WOD", isCustom: true)
            let movement = WODMovement(exerciseId: provisional.id, name: raw, reps: 6)
            XCTAssertNil(CrossFitGlossary.catalogExercise(for: movement, in: [provisional]))
        }
    }

    func testPreservesOtherCustomMovementsWithoutFalseReplacements() {
        let free = Exercise(name: "Movimiento inventado", muscleGroup: "WOD", isCustom: true)
        let movement = WODMovement(exerciseId: free.id, name: free.name)
        XCTAssertEqual(CrossFitGlossary.catalogExercise(for: movement, in: [free])?.id, free.id)
    }
}
