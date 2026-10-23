import XCTest
@testable import ReperaDomain

final class CatalogWeightliftingCoverageTests: XCTestCase {
    private let added: [String] = [
        "Tirón alto de arrancada",
        "Tirón alto de cargada",
        "Peso muerto de cargada",
        "Envión en sentadilla",
        "Dip y drive de envión",
        "Arrancada de potencia desde bloques",
        "Cargada de potencia desde bloques",
        "Push press con agarre de arrancada",
    ]

    func testEightUniqueVariantsKeepCanonicalCatalogKeys() {
        let all = Catalog.seed()
        let lifts = all.filter { $0.sportTag == "Halterofilia" }
        XCTAssertEqual(lifts.count, 48)
        XCTAssertEqual(all.count, 288)
        XCTAssertEqual(Set(all.map(\.catalogId)).count, all.count)
        for name in added {
            let matches = all.filter { $0.name == name }
            XCTAssertEqual(matches.count, 1, "Duplicado o ausente: \(name)")
            XCTAssertEqual(matches.first?.sportTag, "Halterofilia")
            XCTAssertEqual(matches.first?.catalogId, "catalog:\(name)")
        }
    }

    func testExistingCompetitionLiftsStayUntouched() {
        let byName = Dictionary(uniqueKeysWithValues: Catalog.seed().map { ($0.name, $0) })
        for name in ["Arrancada", "Cargada", "Cargada y envión", "Split jerk",
                     "Tirón de arrancada", "Tirón de cargada",
                     "Arrancada desde bloques", "Cargada desde bloques"] {
            XCTAssertNotNil(byName[name])
            XCTAssertEqual(byName[name]?.sportTag, "Halterofilia")
        }
    }

    func testEnglishAndSpanishQueriesResolveNewMovements() {
        let all = Catalog.seed()
        let samples: [(String, String)] = [
            ("snatch high pull", "Tirón alto de arrancada"),
            ("clean high pull", "Tirón alto de cargada"),
            ("clean deadlift", "Peso muerto de cargada"),
            ("squat jerk", "Envión en sentadilla"),
            ("jerk dip and drive", "Dip y drive de envión"),
            ("block power snatch", "Arrancada de potencia desde bloques"),
            ("block power clean", "Cargada de potencia desde bloques"),
            ("snatch grip push press", "Push press con agarre de arrancada"),
        ]
        for (query, name) in samples {
            XCTAssertTrue(
                ExerciseSearch.ranked(all, query: query).contains { $0.name == name },
                "Búsqueda inglesa no encuentra \(name): \(query)"
            )
            XCTAssertTrue(
                ExerciseSearch.ranked(all, query: name).contains { $0.name == name },
                "Búsqueda española no encuentra \(name)"
            )
        }
    }
}
