import XCTest
@testable import ReperaDomain

final class CatalogQualityTests: XCTestCase {
    func testHyroxCompetitionStationsAndSecondaryTags() {
        let seed = Catalog.seed()
        let byName = Dictionary(uniqueKeysWithValues: seed.map { ($0.name, $0) })
        XCTAssertEqual(HyroxExercises.competitionStations.count, 9)

        for station in HyroxExercises.competitionStations {
            let exercise = byName[station]
            XCTAssertNotNil(exercise, "Falta estación de HYROX: \(station)")
            XCTAssertTrue(exercise?.disciplineTags.contains("HYROX") == true, station)
        }

        let wallBall = try? XCTUnwrap(byName["Wall ball"])
        XCTAssertEqual(wallBall?.sportTag, "CrossFit")
        XCTAssertEqual(wallBall?.disciplineTags, ["CrossFit", "HYROX"])
        XCTAssertEqual(byName["Sled push"]?.sportTag, "CrossFit")
        XCTAssertEqual(byName["Burpee Broad Jump"]?.sportTag, "HYROX")
        XCTAssertEqual(byName["Sandbag Lunges"]?.sportTag, "HYROX")
        XCTAssertFalse(HyroxExercises.isMovement(named: "Burpee box jump over"))
        XCTAssertFalse(HyroxExercises.isMovement(named: "Remo con barra"))

        let docs = ExerciseSearch.makeIndex(seed)
        XCTAssertEqual(docs.filter { $0.disciplineTags.contains("HYROX") }.count, 11)
        XCTAssertTrue(docs.contains { $0.displayName == "Remo máquina" && $0.disciplineTags.contains("HYROX") })
        XCTAssertTrue(ExerciseSearch.rankedDocuments(docs, query: "HYROX").contains { $0.displayName == "SkiErg" })
        XCTAssertEqual(ExerciseSearch.ranked(seed, query: "zancadas con saco").first?.name, "Sandbag Lunges")
        XCTAssertEqual(ExerciseSearch.ranked(seed, query: "burpee con salto de longitud").first?.name, "Burpee Broad Jump")
        XCTAssertEqual(ExerciseSearch.ranked(seed, query: "rowing").first?.name, "Remo máquina")
    }

    func testEverySeedHasSpanishDescriptionAndInstructions() {
        let seed = Catalog.seed()
        XCTAssertEqual(seed.count, 280)
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
