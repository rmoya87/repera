import XCTest
@testable import ReperaDomain

final class CatalogMovilidadTests: XCTestCase {
    func testCatalogHas82UniqueMobilityMovements() {
        let mobility = Catalog.seed().filter { $0.sportTag == "Movilidad" }
        XCTAssertEqual(mobility.count, 82)
        XCTAssertEqual(Set(mobility.map(\.name)).count, mobility.count)
        XCTAssertEqual(Set(mobility.compactMap(\.catalogId)).count, mobility.count)
        XCTAssertTrue(mobility.allSatisfy { !$0.instructions.isEmpty && !($0.detailDescription ?? "").isEmpty })
        XCTAssertTrue(mobility.allSatisfy { !$0.muscleGroup.isEmpty && $0.targetMuscle != nil })
    }

    func testMobilityLookupInSpanishAndEnglish() {
        let mobility = Catalog.seed().filter { $0.sportTag == "Movilidad" }
        let cases: [(String, String)] = [
            ("gato vaca", "Gato-vaca"),
            ("cat cow", "Gato-vaca"),
            ("90/90 hip mobility", "90/90 de cadera"),
            ("wall slides", "Deslizamientos en pared"),
            ("knee to wall ankle mobility", "Rodilla a pared para tobillo"),
            ("thoracic rotation", "Rotación torácica sentado"),
            ("wrist circles", "Círculos de muñecas"),
            ("worlds greatest stretch", "World's Greatest Stretch"),
        ]
        for (query, expected) in cases {
            let names = ExerciseSearch.ranked(mobility, query: query).map(\.name)
            XCTAssertTrue(names.contains(expected), "No se encuentra \(expected) al buscar \(query)")
        }
    }

    func testMobilityNeverRequestsExternalLoad() {
        for exercise in Catalog.seed() where exercise.sportTag == "Movilidad" {
            XCTAssertEqual(exercise.loggingStyle, .repsOnly, exercise.name)
            XCTAssertEqual(exercise.loadField, .none, exercise.name)
        }
    }
}
