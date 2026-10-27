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

    func testOfficialOfflineFallbackWhenOnlyAProvisionalExerciseExists() {
        for (raw, official) in [("BTt", "Burpee to target"), ("T2B", "Toes to bar")] {
            let provisional = Exercise(name: raw, muscleGroup: "WOD", isCustom: true)
            let movement = WODMovement(exerciseId: provisional.id, name: raw, reps: 6)
            let resolved = CrossFitGlossary.catalogExercise(for: movement, in: [provisional])
            XCTAssertEqual(resolved?.name, official)
            XCTAssertEqual(resolved?.isCustom, false)
            XCTAssertNotEqual(resolved?.id, provisional.id)
        }
    }

    func testOfficialRemoteAliasHasPriorityOverOfflineFallback() {
        let official = Exercise(
            name: "Burpee to target", muscleGroup: "Cardio",
            isCustom: false, searchAliases: ["BTt"]
        )
        let provisional = Exercise(name: "BTt", muscleGroup: "WOD", isCustom: true)
        let movement = WODMovement(exerciseId: provisional.id, name: "BTt", reps: 6)
        XCTAssertEqual(
            CrossFitGlossary.catalogExercise(for: movement, in: [provisional, official])?.id,
            official.id
        )
    }

    func testStaleOfficialAbbreviationDoesNotReplaceTheCanonicalExercise() {
        for (short, canonical) in [("BTt", "Burpee to target"), ("T2B", "Toes to bar")] {
            // Algunos catálogos locales antiguos guardaron estos rótulos con
            // isCustom=false. No deben ganar contra la ficha real.
            let legacy = Exercise(name: short, muscleGroup: "WOD", isCustom: false)
            let correct = Exercise(name: canonical, muscleGroup: "WOD", isCustom: false)
            let movement = WODMovement(exerciseId: legacy.id, name: short, reps: 6)
            XCTAssertEqual(
                CrossFitGlossary.catalogExercise(for: movement, in: [legacy, correct])?.id,
                correct.id
            )
            XCTAssertEqual(
                CrossFitGlossary.catalogExercise(for: movement, in: [legacy])?.name,
                canonical
            )
        }
    }

    func testPreservesOtherCustomMovementsWithoutFalseReplacements() {
        let free = Exercise(name: "Movimiento inventado", muscleGroup: "WOD", isCustom: true)
        let movement = WODMovement(exerciseId: free.id, name: free.name)
        XCTAssertEqual(CrossFitGlossary.catalogExercise(for: movement, in: [free])?.id, free.id)
    }
}
