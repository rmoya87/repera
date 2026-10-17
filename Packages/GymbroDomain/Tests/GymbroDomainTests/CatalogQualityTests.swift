import XCTest
@testable import GymbroDomain

final class CatalogQualityTests: XCTestCase {
    func testEverySeedHasSpanishDescriptionAndInstructions() {
        let seed = Catalog.seed()
        XCTAssertEqual(seed.count, 188)
        for exercise in seed {
            let desc = CatalogSpanish.description(forName: exercise.name)
            XCTAssertNotNil(desc, "Falta descripción ES: \(exercise.name)")
            XCTAssertFalse(desc?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true)

            let steps = CatalogSpanish.instructions(forName: exercise.name)
            XCTAssertNotNil(steps, "Faltan instrucciones ES: \(exercise.name)")
            XCTAssertGreaterThanOrEqual(steps?.count ?? 0, 2, "Pocos pasos: \(exercise.name)")
            for step in steps ?? [] {
                XCTAssertFalse(step.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    func testEverySeedHasMappedMuscleLoad() {
        for exercise in Catalog.seed() {
            let weights = MuscleTaxonomy.muscleWeights(for: exercise)
            if exercise.muscleGroup == "Cardio" {
                // Cardio puede pintar piernas/espalda vía secundarios; no exigir vacío.
                continue
            }
            XCTAssertFalse(
                weights.isEmpty,
                "Sin pesos musculares: \(exercise.name) group=\(exercise.muscleGroup)"
            )
            XCTAssertFalse(
                exercise.primaryRegions.isEmpty && (exercise.targetMuscle ?? "").isEmpty,
                "Sin primario: \(exercise.name)"
            )
        }
    }

    func testKnownMuscleCorrections() {
        let byName = Dictionary(uniqueKeysWithValues: Catalog.seed().map { ($0.name, $0) })

        let incline = byName["Press banca inclinada"]!
        XCTAssertEqual(incline.targetMuscle, "pectorals")
        XCTAssertTrue(incline.primaryRegions.contains("chest"))
        XCTAssertEqual(MuscleTaxonomy.muscleWeights(for: incline)["chest"], 1)

        let legExt = byName["Extensión de cuádriceps"]!
        XCTAssertEqual(legExt.targetMuscle, "quads")
        XCTAssertTrue(legExt.primaryRegions.contains("quadriceps"))
        XCTAssertNil(MuscleTaxonomy.muscleWeights(for: legExt)["abs"])

        let closeGrip = byName["Press cerrado"]!
        XCTAssertEqual(closeGrip.targetMuscle, "triceps")
        XCTAssertEqual(MuscleTaxonomy.muscleWeights(for: closeGrip)["triceps"], 1)

        let pushdown = byName["Extensión tríceps polea"]!
        XCTAssertEqual(pushdown.targetMuscle, "triceps")
        XCTAssertEqual(MuscleTaxonomy.muscleWeights(for: pushdown)["triceps"], 1)

        let plank = byName["Plancha"]!
        XCTAssertEqual(plank.targetMuscle, "abs")
        XCTAssertEqual(MuscleTaxonomy.muscleWeights(for: plank)["abs"], 1)
    }

    func testSecondaryIntensityIsGraded() {
        let row = Catalog.seed().first { $0.name == "Press banca" }!
        let w = MuscleTaxonomy.muscleWeights(for: row)
        XCTAssertEqual(w["chest"], 1)
        // Primer secundario ~0.55; no debe ser 1.
        if let tri = w["triceps"] {
            XCTAssertLessThan(tri, 1)
            XCTAssertGreaterThan(tri, 0.3)
        } else {
            XCTFail("Press banca debería cargar tríceps")
        }
    }
}
