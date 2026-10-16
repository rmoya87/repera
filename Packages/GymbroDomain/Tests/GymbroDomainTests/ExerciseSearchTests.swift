import XCTest
@testable import GymbroDomain

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
        let viaIndex = ExerciseSearch.ranked(ExerciseSearch.makeIndex(catalog), query: "press de banca")
        let viaList = ExerciseSearch.ranked(catalog, query: "press de banca")
        XCTAssertEqual(viaIndex.map(\.name), viaList.map(\.name))
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
            _ = ExerciseSearch.ranked(index, query: "press de banca")
        }
        let ms = (CFAbsoluteTimeGetCurrent() - t0) * 1000 / 80
        XCTAssertLessThan(ms, 3.0, "ranked avg \(ms)ms")
    }
}
