import XCTest
@testable import ReperaDomain

final class SportExerciseNamesTests: XCTestCase {
    func testEveryCrossFitAndWeightliftingExerciseHasEnglishPrimaryNameAndSpanishSearchAlias() {
        let sports = Catalog.seed().filter {
            $0.sportTag == "CrossFit" || $0.sportTag == "Halterofilia"
        }
        XCTAssertEqual(sports.count, 86)

        for exercise in sports {
            guard let spanish = SportExerciseNames.spanishAlias(for: exercise.name) else {
                XCTFail("Sin alias español: \(exercise.name)")
                continue
            }
            XCTAssertNotEqual(
                ExerciseSearch.normalize(exercise.name),
                ExerciseSearch.normalize(spanish),
                "Alias idéntico al nombre principal: \(exercise.name)"
            )
            XCTAssertTrue(
                ExerciseSearch.matches(exercise, query: spanish),
                "La búsqueda por \(spanish) debe encontrar \(exercise.name)"
            )
        }
    }

    func testSpanishLegacyExerciseNamesKeepTheirCatalogIdentity() {
        let cases = [
            ("Arrancada", "Snatch"),
            ("Arrancada de potencia", "Power Snatch"),
            ("Cargada de potencia", "Power Clean"),
            ("Thruster mancuernas", "Dumbbell Thruster"),
            ("Dobles de comba", "Double-Under")
        ]
        for (spanish, english) in cases {
            XCTAssertEqual(SportExerciseNames.canonicalName(spanish), english)
            XCTAssertTrue(ExerciseEquivalence.sameName(spanish, english))
            XCTAssertEqual(SportExerciseNames.spanishAlias(for: english), spanish)
        }
    }

    func testExerciseLoggingRemainsCompatibleAfterRenaming() {
        let english = Exercise(
            name: "Double-Under",
            muscleGroup: "Cardio",
            equipment: "Comba",
            sportTag: "CrossFit"
        )
        XCTAssertEqual(english.loggingStyle, .repsAndTime)
        XCTAssertEqual(english.quantityFieldLabel, "Veces")

        let run = Exercise(
            name: "Run",
            muscleGroup: "Cardio",
            equipment: "Peso corporal",
            sportTag: "CrossFit"
        )
        XCTAssertEqual(run.loggingStyle, .machineWork)
        XCTAssertEqual(run.defaultQuantityUnit, .meters)
    }
}
