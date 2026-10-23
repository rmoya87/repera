import XCTest
@testable import ReperaDomain

final class CatalogQualityTests: XCTestCase {
    func testEverySeedHasSpanishDescriptionAndInstructions() {
        let seed = Catalog.seed()
        XCTAssertEqual(seed.count, 196)
        for exercise in seed {
            let desc = CatalogSpanish.description(forName: exercise.name)
            XCTAssertNotNil(desc, "Falta descripción ES: \(exercise.name)")
            XCTAssertFalse(desc?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true)

            let steps = CatalogSpanish.instructions(forName: exercise.name)
            XCTAssertNotNil(steps, "Faltan instrucciones ES: \(exercise.name)")
            XCTAssertGreaterThanOrEqual(steps?.count ?? 0, 5, "Pocos pasos de técnica: \(exercise.name)")
            let totalChars = (steps ?? []).map(\.count).reduce(0, +)
            XCTAssertGreaterThanOrEqual(totalChars, 280, "Instrucciones demasiado cortas: \(exercise.name)")
            for step in steps ?? [] {
                XCTAssertFalse(step.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            let joined = (steps ?? []).joined(separator: " ").lowercased()
            let hasCoachVoice = ["error típico", "estándar", "inhala", "exhala", "progresión", "si no"]
                .contains { joined.contains($0) }
            XCTAssertTrue(hasCoachVoice, "Falta tono de entrenador en \(exercise.name)")
        }
    }

    func testEverySeedHasMappedMuscleLoad() {
        for exercise in Catalog.seed() {
            let weights = MuscleTaxonomy.muscleWeights(for: exercise)
            if exercise.muscleGroup == "Cardio" {
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
        if let tri = w["triceps"] {
            XCTAssertLessThan(tri, 1)
            XCTAssertGreaterThan(tri, 0.3)
        } else {
            XCTFail("Press banca debería cargar tríceps")
        }
    }
}
