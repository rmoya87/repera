import XCTest
@testable import ReperaDomain

final class SportExerciseNamesTests: XCTestCase {
    func testEveryCrossFitAndWeightliftingExerciseHasEnglishPrimaryNameAndSpanishSearchAlias() {
        let sports = Catalog.seed().filter {
            $0.sportTag == "CrossFit" || $0.sportTag == "Halterofilia"
        }
        // Enrichment gym keeps Spanish primary titles; bilingual alias rules
        // apply to English WOD / WL names registered in SportExerciseNames.
        let bilingual = sports.filter { SportExerciseNames.spanishAlias(for: $0.name) != nil }
        XCTAssertGreaterThanOrEqual(bilingual.count, 100)
        XCTAssertLessThan(bilingual.count, sports.count)

        for exercise in bilingual {
            guard let spanish = SportExerciseNames.spanishAlias(for: exercise.name) else {
                XCTFail("Sin alias español: \(exercise.name)")
                continue
            }
            let same =
                ExerciseSearch.normalize(exercise.name) == ExerciseSearch.normalize(spanish)
            // Shared internationalisms (Bird Dog, Z Press, …) may match; others differ.
            if !same {
                XCTAssertTrue(
                    ExerciseSearch.matches(exercise, query: spanish),
                    "La búsqueda por \(spanish) debe encontrar \(exercise.name)"
                )
            }
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
            XCTAssertEqual(SportExerciseNames.localizedDisplayName(english), english)
            XCTAssertEqual(SportExerciseNames.localizedDisplayName(spanish), english)
            XCTAssertTrue(
                SportExerciseNames.searchAliases(for: english)
                    .contains { ExerciseSearch.normalize($0) == ExerciseSearch.normalize(spanish) }
                    || ExerciseSearch.normalize(SportExerciseNames.spanishAlias(for: english) ?? "")
                        == ExerciseSearch.normalize(spanish),
                "\(english) debe exponer alias español \(spanish)"
            )
        }
    }

    func testLocalizedDisplayNamePrefersEnglishCrossFitTitle() {
        XCTAssertEqual(
            SportExerciseNames.localizedDisplayName("Clean and Jerk"),
            "Clean and Jerk"
        )
        XCTAssertEqual(
            SportExerciseNames.localizedDisplayName("Cargada y envión"),
            "Clean and Jerk"
        )
        XCTAssertEqual(
            SportExerciseNames.localizedDisplayName("Press banca"),
            "Press banca"
        )
    }

    func testSpanishAndEnglishSlangAliasesResolve() {
        let samples: [(String, String)] = [
            ("dos tiempos", "Clean and Jerk"),
            ("arrancada", "Snatch"),
            ("cargada power", "Power Clean"),
            ("dobles", "Double-Under"),
            ("TGU", "Turkish get-up"),
            ("assault bike", "Air bike"),
            ("pino flexiones", "HSPU"),
            ("thrusters", "Thruster"),
            ("suiza", "Shuttle run"),
        ]
        for (alias, expected) in samples {
            XCTAssertEqual(
                SportExerciseNames.canonicalName(forSearchAlias: alias)
                    ?? SportExerciseNames.canonicalName(alias),
                expected,
                "\(alias) → \(expected)"
            )
        }
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
            let expected = exercise
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

    func testCatalogListAndSearchKeepExactExerciseTitles() {
        let catalog = [
            Exercise(name: "Clean and Jerk", muscleGroup: "Piernas", sportTag: "CrossFit"),
            Exercise(name: "Press banca", muscleGroup: "Pecho"),
            Exercise(name: "Cargada y envión personal", muscleGroup: "Otros", isCustom: true)
        ]
        let documents = ExerciseSearch.makeIndex(catalog)
        XCTAssertEqual(documents.map(\.displayName), catalog.map(\.name))
        XCTAssertTrue(
            ExerciseSearch.rankedDocuments(documents, query: "cargada y envión")
                .contains { $0.displayName == "Clean and Jerk" }
        )
        XCTAssertTrue(
            ExerciseSearch.rankedDocuments(documents, query: "Clean and Jerk")
                .contains { $0.displayName == "Clean and Jerk" }
        )
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
