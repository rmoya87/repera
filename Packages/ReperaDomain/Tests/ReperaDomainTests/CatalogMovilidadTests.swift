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
            XCTAssertEqual(exercise.loggingStyle, .repsAndTime, exercise.name)
            XCTAssertEqual(exercise.loadField, .none, exercise.name)
        }
    }

    func testMobilityHoldAndDynamicInputModes() {
        let catalog = Catalog.seed()
        let hold = try! XCTUnwrap(catalog.first { $0.name == "Postura del niño" })
        let dynamic = try! XCTUnwrap(catalog.first { $0.name == "Gato-vaca" })
        XCTAssertTrue(hold.isMobilityHold)
        XCTAssertFalse(dynamic.isMobilityHold)
        XCTAssertTrue(hold.loggingStyle.usesDuration)
        XCTAssertTrue(dynamic.loggingStyle.usesDuration)
        XCTAssertFalse(hold.loggingStyle.usesRIR)
        XCTAssertEqual(hold.loadField, .none)
        XCTAssertEqual(dynamic.quantityFieldLabel, "Reps")
    }

    func testPrescribedDurationSurvivesJSONAndRoutineDuplication() throws {
        let planned = PlannedSet(targetReps: 1, targetDurationSeconds: 45)
        let archived = try JSONEncoder().encode(planned)
        let decoded = try JSONDecoder().decode(PlannedSet.self, from: archived)
        XCTAssertEqual(decoded.targetDurationSeconds, 45)
        XCTAssertEqual(decoded.duplicatingContent().targetDurationSeconds, 45)

        let oldPayload = "{\"id\":\"\(UUID().uuidString)\",\"targetReps\":8}"
        let old = try JSONDecoder().decode(PlannedSet.self, from: Data(oldPayload.utf8))
        XCTAssertNil(old.targetDurationSeconds)
    }

    func testMobilityProgressUsesRecordedSecondsNotPrescribedSeconds() {
        let hold = Catalog.seed().first { $0.name == "Postura del niño" }!
        let date = Date()
        let series = [
            LoggedSet(reps: 1, durationSeconds: 25),
            LoggedSet(reps: 1, durationSeconds: 45),
        ]
        let entry = SessionExercise(
            exercise: hold,
            plannedSets: [PlannedSet(targetReps: 1, targetDurationSeconds: 60)],
            loggedSets: series
        )
        let workout = WorkoutSession(
            title: "Movilidad",
            exercises: [entry],
            phase: .finished,
            startedAt: date.addingTimeInterval(-200),
            finishedAt: date
        )
        let maxHold = StatsEngine.exerciseProgressSeries(
            exerciseId: hold.id, metric: .bestHold, range: .all,
            workouts: [workout], catalog: [hold]
        )
        let time = StatsEngine.exerciseProgressSeries(
            exerciseId: hold.id, metric: .duration, range: .all,
            workouts: [workout], catalog: [hold]
        )
        XCTAssertEqual(maxHold.first?.value, 45)
        XCTAssertEqual(time.first?.value, 70)
        XCTAssertEqual(StatsEngine.history(for: hold.id, workouts: [workout], catalog: [hold]).bestDurationSeconds, 45)
    }
}
