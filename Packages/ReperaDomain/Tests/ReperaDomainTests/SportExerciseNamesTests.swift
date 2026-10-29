import XCTest
@testable import ReperaDomain

final class SportExerciseNamesTests: XCTestCase {
    func testEveryCrossFitAndWeightliftingExerciseHasEnglishPrimaryNameAndSpanishSearchAlias() {
        let sports = Catalog.seed().filter {
            $0.sportTag == "CrossFit" || $0.sportTag == "Halterofilia"
        }
        XCTAssertEqual(sports.count, 94)

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
            XCTAssertEqual(SportExerciseNames.localizedDisplayName(english), spanish)
        }
    }

    func testLocalizedDisplayNamePrefersSpanishAlias() {
        XCTAssertEqual(
            SportExerciseNames.localizedDisplayName("Clean and Jerk"),
            "Cargada y envión"
        )
        XCTAssertEqual(
            SportExerciseNames.localizedDisplayName("Cargada y envión"),
            "Cargada y envión"
        )
        XCTAssertEqual(
            SportExerciseNames.localizedDisplayName("Press banca"),
            "Press banca"
        )
    }

    func testAcronymsAndExtraBilingualAliasesFindCorrectMovements() {
        let indexed = ExerciseSearch.makeIndex(Catalog.seed())
        let samples: [(String, String)] = [
            ("C&J", "Clean and Jerk"),
            ("dos tiempos", "Clean and Jerk"),
            ("SHP", "Snatch High Pull"),
            ("CHP", "Clean High Pull"),
            ("SGDL", "Snatch-Grip Deadlift"),
            ("HPC", "Hang power clean"),
            ("HPSn", "Hang power snatch"),
            ("OHS", "Overhead squat"),
            ("BPSn", "Block Power Snatch"),
            ("BPC", "Block Power Clean"),
            ("SJ", "Split jerk"),
            ("BBJ", "Burpee Broad Jump"),
            ("BBJO", "Burpee box jump over"),
            ("DU", "Double-Under"),
            ("T2B", "Toes to bar"),
            ("C2B", "Chest to bar"),
            ("BMU", "Muscle-up barra"),
            ("RMU", "Muscle-up anillas"),
            ("K2E", "Knees to elbows"),
            ("WB", "Wall ball"),
            ("SDHP", "Sumo high pull"),
        ]
        for (alias, exercise) in samples {
            let expected = SportExerciseNames.localizedDisplayName(exercise)
            XCTAssertTrue(
                ExerciseSearch.rankedDocuments(indexed, query: alias)
                    .contains { $0.displayName == expected },
                "\(alias) debería encontrar \(expected)"
            )
        }
        XCTAssertEqual(
            ExerciseSearch.scannerCatalogName(forNormalizedQuery: ExerciseSearch.normalize("C&J")),
            "Clean and Jerk"
        )
        XCTAssertNil(SportExerciseNames.canonicalName(forSearchAlias: "PS"))
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
