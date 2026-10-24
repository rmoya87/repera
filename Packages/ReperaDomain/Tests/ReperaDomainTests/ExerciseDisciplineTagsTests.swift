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
        XCTAssertEqual(weightlifting.count, 48)
        XCTAssertTrue(weightlifting.allSatisfy { $0.disciplineTags.contains("CrossFit") })
    }

    func testGymnasticMovementsAlsoAppearInCrossFitWithoutCloning() {
        check("Toes to bar", includes: ["Gimnasia", "CrossFit"])
        check("Muscle-up barra", includes: ["Gimnasia", "CrossFit"])
        check("Box jump over", includes: ["CrossFit", "Gimnasia"])
        check("Burpee", includes: ["CrossFit", "Gimnasia"])

        let gymnastics = Catalog.seed().filter { $0.sportTag == "Gimnasia" }
        XCTAssertEqual(gymnastics.count, 58)
        XCTAssertTrue(gymnastics.allSatisfy { $0.disciplineTags.contains("CrossFit") })
    }

    func testHyroxStationsRetainOriginalDisciplineAndAddOthers() {
        check("Wall ball", includes: ["CrossFit", "HYROX"])
        check("SkiErg", includes: ["CrossFit", "HYROX", "Cardio"])
        check("Burpee Broad Jump", includes: ["HYROX", "CrossFit"])
        check("Sandbag Lunges", includes: ["HYROX", "CrossFit"])
        check("Remo máquina", includes: ["HYROX", "CrossFit", "Cardio"])
    }

    func testCommonStrengthMovementsCrossFitButMachinesStayGymOnly() {
        check("Peso muerto", includes: ["CrossFit"])
        check("Dominadas", includes: ["CrossFit", "Gimnasia"])
        XCTAssertTrue(exercise("Prensa").disciplineTags.isEmpty)
        XCTAssertTrue(exercise("Curl femoral").disciplineTags.isEmpty)
    }

    func testMobilityIsNotAutomaticallyCrossFitAndIDsRemainUnique() {
        let mobility = exercise("Gato-vaca")
        XCTAssertEqual(mobility.disciplineTags, ["Movilidad"])
        let all = Catalog.seed()
        XCTAssertEqual(all.count, 288)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        XCTAssertEqual(Set(all.map(\.name)).count, all.count)
        XCTAssertTrue(all.allSatisfy { $0.disciplineTags.count == Set($0.disciplineTags).count })
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
