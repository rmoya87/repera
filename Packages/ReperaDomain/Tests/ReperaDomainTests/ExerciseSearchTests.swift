import XCTest
@testable import ReperaDomain

final class ExerciseSearchTests: XCTestCase {
    private func exercise(
        name: String,
        muscle: String,
        equipment: String? = nil,
        target: String? = nil
    ) -> Exercise {
        Exercise(
            name: name,
            muscleGroup: muscle,
            equipment: equipment,
            targetMuscle: target
        )
    }

    func testEnglishSpanishMovementQueries() {
        let catalog = [
            exercise(name: "Sentadilla", muscle: "Piernas"),
            exercise(name: "Arrancada de potencia", muscle: "Piernas", equipment: "Barra"),
            exercise(name: "Arrancada colgante completa", muscle: "Piernas", equipment: "Barra"),
            exercise(name: "Back rack reverse lunge", muscle: "Piernas", equipment: "Barra"),
            exercise(name: "Walking lunge", muscle: "Piernas"),
        ]
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "back squat").first?.name, "Sentadilla")
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "power snatch").first?.name, "Arrancada de potencia")
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "high hsq snatch").first?.name, "Arrancada colgante completa")
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "zancadas caminando").first?.name, "Walking lunge")
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "zancadas inversas con barra").first?.name, "Back rack reverse lunge")
    }

    func testChinUpMapsToSupinatedNotGenericPullUp() {
        let catalog = [
            exercise(name: "Dominadas", muscle: "Espalda"),
            exercise(name: "Dominadas estrictas", muscle: "Espalda"),
            exercise(name: "Dominadas kipping", muscle: "Espalda"),
            exercise(name: "Dominadas butterfly", muscle: "Espalda"),
            exercise(name: "Dominadas supinas", muscle: "Espalda"),
            exercise(name: "Chest to bar", muscle: "Espalda"),
        ]
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "chin up").first?.name, "Dominadas supinas")
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "chin-ups").first?.name, "Dominadas supinas")
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "pull up").first?.name, "Dominadas")
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "strict pull up").first?.name, "Dominadas estrictas")
        XCTAssertEqual(ExerciseSearch.ranked(catalog, query: "kipping pull-up").first?.name, "Dominadas kipping")
    }

    func testEnglishVariantsMapToSpecificCatalogEntries() {
        let catalog = Catalog.seed()
        let cases: [(String, String)] = [
            ("chin up", "Dominadas supinas"),
            ("pull up", "Dominadas"),
            ("walking lunge", "Walking lunge"),
            ("front rack lunge", "Front rack lunge"),
            ("overhead squat", "Overhead squat"),
            ("front squat", "Sentadilla frontal"),
            ("back squat", "Sentadilla"),
            ("rdl", "Peso muerto rumano"),
            ("sumo deadlift", "Peso muerto sumo"),
            ("incline bench press", "Press banca inclinada"),
            ("db thruster", "Thruster mancuernas"),
            ("kb thruster", "Thruster kettlebell"),
            ("power clean", "Cargada de potencia"),
            ("hang snatch", "Arrancada colgante"),
            ("chest to bar", "Chest to bar"),
        ]
        for (query, expected) in cases {
            XCTAssertEqual(
                ExerciseSearch.ranked(catalog, query: query).first?.name,
                expected,
                "«\(query)» debería abrir «\(expected)»"
            )
        }
    }

    func testPressDeBancaFindsPressBanca() {
        let ex = exercise(name: "Press banca", muscle: "Pecho", equipment: "Barra")
        XCTAssertTrue(ExerciseSearch.matches(ex, query: "press de banca"))
        XCTAssertTrue(ExerciseSearch.matches(ex, query: "Press Banca"))
    }

    func testPressDeBancaRanksDerivativesFirst() {
        let catalog = [
            exercise(name: "Aperturas", muscle: "Pecho"),
            exercise(name: "Press militar", muscle: "Hombros"),
            exercise(name: "Press mancuernas", muscle: "Pecho"),
            exercise(name: "Press banca inclinada", muscle: "Pecho"),
            exercise(name: "Press banca declinado", muscle: "Pecho"),
            exercise(name: "Press banca", muscle: "Pecho", equipment: "Barra"),
            exercise(name: "Curl bíceps", muscle: "Bíceps"),
            exercise(name: "Cruce de poleas", muscle: "Pecho"),
        ]
        let ranked = ExerciseSearch.ranked(catalog, query: "press de banca")
        let names = ranked.map(\.name)
        XCTAssertEqual(names.first, "Press banca")
        XCTAssertEqual(Array(names.prefix(3)), [
            "Press banca",
            "Press banca declinado",
            "Press banca inclinada",
        ])
        XCTAssertFalse(names.contains("Aperturas"))
        XCTAssertFalse(names.contains("Press militar"))
        XCTAssertFalse(names.contains("Curl bíceps"))
        XCTAssertFalse(names.contains("Press mancuernas"))
    }

    func testScoreWeightsPreferExactNameOverLongerDerivative() {
        let exact = exercise(name: "Press banca", muscle: "Pecho")
        let long = exercise(name: "Press banca inclinada", muscle: "Pecho")
        let q = "press de banca"
        XCTAssertGreaterThan(ExerciseSearch.score(exact, query: q), ExerciseSearch.score(long, query: q))
    }

    func testEjercicioDePechoFindsChest() {
        let chest = exercise(name: "Aperturas", muscle: "Pecho")
        let back = exercise(name: "Dominadas", muscle: "Espalda")
        XCTAssertTrue(ExerciseSearch.matches(chest, query: "ejercicio de pecho"))
        XCTAssertTrue(ExerciseSearch.matches(chest, query: "pecho"))
        XCTAssertFalse(ExerciseSearch.matches(back, query: "ejercicio de pecho"))
    }

    func testDiacriticsAndPartialTokens() {
        let ex = exercise(name: "Curl bíceps", muscle: "Bíceps")
        XCTAssertTrue(ExerciseSearch.matches(ex, query: "biceps"))
        XCTAssertTrue(ExerciseSearch.matches(ex, query: "curl"))
    }

    func testBancaAlonePrefersBenchPressFamily() {
        let catalog = [
            exercise(name: "Aperturas", muscle: "Pecho"),
            exercise(name: "Press banca", muscle: "Pecho"),
            exercise(name: "Press banca inclinada", muscle: "Pecho"),
        ]
        let ranked = ExerciseSearch.ranked(catalog, query: "banca")
        XCTAssertEqual(ranked.first?.name, "Press banca")
        XCTAssertTrue(ranked.map(\.name).contains("Press banca inclinada"))
        XCTAssertFalse(ranked.map(\.name).contains("Aperturas"))
    }

    func testRankedIndexMatchesExerciseAPI() {
        let catalog = [
            exercise(name: "Press banca", muscle: "Pecho"),
            exercise(name: "Aperturas", muscle: "Pecho"),
        ]
        let viaDocs = ExerciseSearch.rankedDocuments(ExerciseSearch.makeIndex(catalog), query: "press de banca")
        let viaList = ExerciseSearch.ranked(catalog, query: "press de banca")
        XCTAssertEqual(viaDocs.map(\.displayName), viaList.map(\.name))
    }

    func testBilingualMovementNamesAndAbbreviations() {
        let catalog = Catalog.seed()
        let searches: [(String, String)] = [
            ("back squat", "Sentadilla"),
            ("sentadilla trasera", "Sentadilla"),
            ("power snatch", "Arrancada de potencia"),
            ("arrancada de potencia", "Arrancada de potencia"),
            ("high hsq snatch", "Arrancada colgante completa"),
            ("back rack r. lunges", "Zancadas inversas con barra"),
            ("walking lunge", "Walking lunge"),
            ("zancadas caminando", "Walking lunge"),
            ("deadlift", "Peso muerto"),
            ("peso muerto", "Peso muerto"),
        ]
        for (query, expectedName) in searches {
            XCTAssertTrue(
                ExerciseSearch.ranked(catalog, query: query).contains { $0.name == expectedName },
                "No encuentra \\(expectedName) al buscar \\(query)"
            )
        }
    }

    func testRankPerfUnder2ms() {
        var catalog: [Exercise] = []
        catalog.reserveCapacity(220)
        for i in 0..<220 {
            catalog.append(
                Exercise(
                    name: "Ejercicio \(i) press banca \(i % 7)",
                    muscleGroup: i % 2 == 0 ? "Pecho" : "Espalda"
                )
            )
        }
        let index = ExerciseSearch.makeIndex(catalog)
        let t0 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<80 {
            _ = ExerciseSearch.rankedDocuments(index, query: "press de banca")
        }
        let ms = (CFAbsoluteTimeGetCurrent() - t0) * 1000 / 80
        XCTAssertLessThan(ms, 3.0, "ranked avg \(ms)ms")
    }
}
