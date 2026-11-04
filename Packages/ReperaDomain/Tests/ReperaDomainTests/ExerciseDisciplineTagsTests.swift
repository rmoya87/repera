import XCTest
@testable import ReperaDomain

final class ExerciseDisciplineTagsTests: XCTestCase {
    private func exercise(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Exercise {
        let found = Catalog.seed().first { $0.name == name }
        XCTAssertNotNil(found, name, file: file, line: line)
        return found ?? Exercise(name: name, muscleGroup: "Custom")
    }

    private func check(_ name: String, includes expected: Set<String>,
                       file: StaticString = #filePath, line: UInt = #line) {
        let item = exercise(name, file: file, line: line)
        let tags = item.disciplineTags
        XCTAssertTrue(expected.isSubset(of: Set(tags)), "\(name): \(tags)", file: file, line: line)
        XCTAssertEqual(tags.count, Set(tags).count, "Hay disciplinas duplicadas en \(name)", file: file, line: line)
    }

    func testCleanAndPressAndAllWeightliftingAreCrossFitCompatible() {
        check("Clean and Press", includes: ["Halterofilia", "CrossFit"])
        check("Clean and Jerk", includes: ["Halterofilia", "CrossFit"])
        check("Snatch", includes: ["Halterofilia", "CrossFit"])
        check("Dumbbell Snatch", includes: ["CrossFit"])
        XCTAssertFalse(exercise("Dumbbell Snatch").disciplineTags.contains("Halterofilia"),
                       "La mancuerna no es una arrancada olímpica con barra")

        let weightlifting = Catalog.seed().filter { $0.sportTag == "Halterofilia" }
        // 48 olímpicos + 9 fuerza Enrichment (sentadilla/peso muerto/press militar…).
        XCTAssertEqual(weightlifting.count, 57)
        XCTAssertTrue(weightlifting.allSatisfy { $0.disciplineTags.contains("CrossFit") })
    }

    func testGymnasticMovementsAlsoAppearInCrossFitWithoutCloning() {
        check("Toes to bar", includes: ["Gimnasia", "CrossFit"])
        check("Muscle-up barra", includes: ["Gimnasia", "CrossFit"])
        check("Box jump over", includes: ["CrossFit", "Gimnasia"])
        check("Burpee", includes: ["CrossFit", "Gimnasia"])

        let gymnastics = Catalog.seed().filter { $0.sportTag == "Gimnasia" }
        // 58 gimnasia pura + 6 Enrichment (dominadas/fondos/plancha…).
        XCTAssertEqual(gymnastics.count, 64)
        XCTAssertTrue(gymnastics.allSatisfy { $0.disciplineTags.contains("CrossFit") })
    }

    func testHyroxStationsRetainOriginalDisciplineAndAddOthers() {
        check("Wall ball", includes: ["CrossFit", "HYROX"])
        check("SkiErg", includes: ["CrossFit", "HYROX", "Cardio"])
        check("Burpee Broad Jump", includes: ["HYROX", "CrossFit"])
        check("Sandbag Lunges", includes: ["HYROX", "CrossFit"])
        check("Remo máquina", includes: ["HYROX", "CrossFit", "Cardio"])
    }

    func testEnrichmentGymSportTagsAndMultiFilters() {
        check("Peso muerto", includes: ["Halterofilia", "CrossFit"])
        check("Sentadilla", includes: ["Halterofilia", "CrossFit"])
        check("Dominadas", includes: ["Gimnasia", "CrossFit"])
        check("Plancha", includes: ["Gimnasia", "CrossFit"])
        check("Prensa", includes: ["CrossFit"])
        check("Curl femoral", includes: ["CrossFit"])
        // Remo máquina también es estación HYROX → CrossFit + HYROX + Cardio.
        check("Remo máquina", includes: ["CrossFit", "HYROX", "Cardio"])
        check("Cinta / carrera", includes: ["CrossFit", "Cardio"])
        check("Bici estática", includes: ["CrossFit", "Cardio"])
    }

    func testMobilityIsNotAutomaticallyCrossFitAndIDsRemainUnique() {
        let mobility = exercise("Gato-vaca")
        XCTAssertEqual(mobility.disciplineTags, ["Movilidad"])
        let all = Catalog.seed()
        XCTAssertEqual(all.count, 447)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        XCTAssertEqual(Set(all.map(\.name)).count, all.count)
        XCTAssertTrue(all.allSatisfy { $0.disciplineTags.count == Set($0.disciplineTags).count })
        XCTAssertTrue(all.allSatisfy { ($0.sportTag ?? "").isEmpty == false || $0.isCustom })
        // Tras el assign: ninguna ficha seed sin sportTag.
        XCTAssertEqual(all.filter { $0.sportTag == nil }.count, 0)
    }

    func testRepeatedAccessIsStableAndDoesNotChangeCodableOrigin() throws {
        let cleanAndPress = exercise("Clean and Press")
        XCTAssertEqual(cleanAndPress.disciplineTags, cleanAndPress.disciplineTags)
        let decoded = try JSONDecoder().decode(Exercise.self, from: JSONEncoder().encode(cleanAndPress))
        XCTAssertEqual(decoded.sportTag, "Halterofilia")
        XCTAssertEqual(decoded.id, cleanAndPress.id)
        XCTAssertEqual(decoded.disciplineTags, cleanAndPress.disciplineTags)
    }
}
