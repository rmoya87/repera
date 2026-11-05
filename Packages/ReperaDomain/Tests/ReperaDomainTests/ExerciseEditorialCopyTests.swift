import XCTest
@testable import ReperaDomain

/// La UI de ficha debe mostrar el texto mergeado (Supabase/seed en `Exercise`),
/// no el diccionario embebido `CatalogSpanish` cuando el ejercicio ya trae copy.
final class ExerciseEditorialCopyTests: XCTestCase {
    func testResolvedCopyPrefersExerciseFieldsOverBundledSpanish() {
        let bundled = CatalogSpanish.instructions(forName: "Ring Lower")
        XCTAssertNotNil(bundled)
        XCTAssertFalse(bundled!.isEmpty)

        let remoteSteps = [
            "Desde soporte en anillas o cima de muscle-up.",
            "Baja excéntrico hasta cuelgue o posición prescrita.",
            "Texto solo remoto Ring Lower",
        ]
        let remoteDescription = "Descripción remota Ring Lower para ficha iOS."
        let exercise = Exercise(
            name: "Ring Lower",
            muscleGroup: "Espalda",
            equipment: "Anillas",
            detailDescription: remoteDescription,
            instructions: remoteSteps,
            sportTag: "CrossFit",
            artKeys: ["art_cf_mu_rings", "art_cf_mu_rings_1"]
        )

        XCTAssertEqual(
            CatalogSpanish.resolvedDescription(for: exercise),
            remoteDescription
        )
        XCTAssertEqual(
            CatalogSpanish.resolvedInstructions(for: exercise),
            remoteSteps
        )
        XCTAssertNotEqual(
            CatalogSpanish.resolvedInstructions(for: exercise),
            bundled
        )
    }

    func testResolvedCopyFallsBackToBundledWhenExerciseTextEmpty() {
        let bundledDesc = CatalogSpanish.description(forName: "Ring Lower")
        let bundledSteps = CatalogSpanish.instructions(forName: "Ring Lower")
        XCTAssertNotNil(bundledDesc)
        XCTAssertNotNil(bundledSteps)

        let bare = Exercise(
            name: "Ring Lower",
            muscleGroup: "Espalda",
            detailDescription: nil,
            instructions: [],
            sportTag: "CrossFit"
        )
        XCTAssertEqual(CatalogSpanish.resolvedDescription(for: bare), bundledDesc)
        XCTAssertEqual(CatalogSpanish.resolvedInstructions(for: bare), bundledSteps)
    }

    func testSeedHydrationDoesNotOverwriteRemoteEditorialFields() {
        let id = UUID()
        let remote = Exercise(
            id: id,
            name: "Ring Lower",
            muscleGroup: "Espalda",
            equipment: "Anillas",
            detailDescription: "Copy Supabase",
            instructions: ["Paso remoto 1", "Paso remoto 2"],
            searchAliases: ["Descenso en anillas"],
            isFavorite: true,
            sportTag: "CrossFit",
            skillLevel: "intermediate",
            movementPattern: "pull",
            catalogAlternatives: ["Muscle-up anillas"],
            artKeys: ["art_cf_mu_rings", "art_cf_mu_rings_1"]
        )
        let seed = Exercise(
            id: UUID(),
            name: "Ring Lower",
            muscleGroup: "Espalda",
            equipment: "Anillas",
            catalogId: "seed-ring-lower",
            detailDescription: "Copy seed embebido",
            instructions: ["Paso seed 1"],
            sportTag: "CrossFit"
        )
        let result = CatalogSeedHydration.merge(current: [remote], seed: [seed])
        XCTAssertEqual(result.exercises.count, 1)
        let next = result.exercises[0]
        XCTAssertEqual(next.id, id)
        XCTAssertTrue(next.isFavorite)
        XCTAssertEqual(next.detailDescription, "Copy Supabase")
        XCTAssertEqual(next.instructions, ["Paso remoto 1", "Paso remoto 2"])
        XCTAssertEqual(next.artKeys, ["art_cf_mu_rings", "art_cf_mu_rings_1"])
        XCTAssertEqual(next.skillLevel, "intermediate")
        XCTAssertEqual(next.catalogAlternatives, ["Muscle-up anillas"])
        XCTAssertEqual(next.searchAliases, ["Descenso en anillas"])
        // catalogId vacío en remoto puede rellenarse desde seed sin tocar textos.
        XCTAssertEqual(next.catalogId, "seed-ring-lower")
        XCTAssertTrue(result.changed)
    }
}
