import XCTest
@testable import ReperaDomain

final class ExerciseEquipmentAuditTests: XCTestCase {
    private var catalog: [Exercise] { Catalog.seed() }

    private func exercise(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Exercise {
        guard let result = catalog.first(where: { $0.name == name }) else {
            XCTFail("No se encuentra el ejercicio \(name)", file: file, line: line)
            return Exercise(name: name, muscleGroup: "Sin clasificar")
        }
        return result
    }

    func testEntireBuiltInCatalogHasExplicitEquipment() {
        let exercises = catalog
        XCTAssertEqual(exercises.count, 288)
        XCTAssertTrue(exercises.allSatisfy {
            $0.equipment?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }, "Todos los ejercicios de fábrica deben indicar su material, incluso Peso corporal")
    }

    func testCardioMachinesAndBandDoNotAskForKilograms() {
        for name in ["Cinta / carrera", "Bici estática", "Remo máquina"] {
            let item = exercise(name)
            XCTAssertNotNil(item.equipment, name)
            XCTAssertEqual(item.loggingStyle, .machineWork, name)
            XCTAssertEqual(item.loadField, .none, name)
        }
        let band = exercise("Paso lateral con banda")
        XCTAssertEqual(band.equipment, "Banda elástica")
        XCTAssertEqual(band.loggingStyle, .repsOnly)
        XCTAssertEqual(band.loadField, .none)
    }

    func testBoxMovementsDeclareAnActualBox() {
        for name in ["Box jump over", "Burpee box jump over", "Burpee Box Jump",
                     "Box Jump", "Box Step-Up"] {
            let item = exercise(name)
            XCTAssertEqual(item.equipment, "Cajón", name)
            XCTAssertEqual(item.loggingStyle, .repsOnly, name)
            XCTAssertEqual(item.loadField, .none, name)
            XCTAssertEqual(ExerciseEquipmentGroup.category(for: item), "Cajones", name)
        }
    }

    func testSimultaneouslyRequiredApparatusIsRetained() {
        let goblet = exercise("Kettlebell Goblet Box Step-Up")
        XCTAssertEqual(goblet.equipment, "Cajón, Kettlebell")
        XCTAssertEqual(goblet.loggingStyle, .loadAndReps)
        XCTAssertEqual(goblet.equipment?.components(separatedBy: ", "), ["Cajón", "Kettlebell"])

        let press = exercise("Press banca")
        XCTAssertEqual(press.equipment, "Barra, Banco")
        XCTAssertEqual(press.loggingStyle, .loadAndReps)
        XCTAssertEqual(press.equipment?.components(separatedBy: ", "), ["Barra", "Banco"])
    }

    func testGymnasticSupportEquipmentIsNotMistakenForExternalWeight() {
        for (name, equipment) in [
            ("Toes to bar", "Barra de dominadas"),
            ("Toes to rings", "Anillas"),
            ("Rope climb", "Cuerda de trepa"),
            ("Pegboard", "Pegboard"),
            ("Fondos", "Paralelas"),
            ("Fondos en banco", "Banco"),
            ("Ab wheel", "Rueda abdominal"),
            ("GHD sit-up", "GHD"),
            ("Remo pliométrico en anillas pies elevados", "Anillas, Plataforma elevada"),
        ] {
            let item = exercise(name)
            XCTAssertEqual(item.equipment, equipment, name)
            XCTAssertEqual(item.loggingStyle, .repsOnly, name)
            XCTAssertEqual(item.loadField, .none, name)
        }
    }

    func testLoadedGymnasticsRemainLoadCapable() {
        let weighted = exercise("Dominadas lastradas")
        XCTAssertEqual(weighted.equipment, "Barra de dominadas, Lastre")
        XCTAssertEqual(weighted.loggingStyle, .loadAndReps)
        XCTAssertEqual(weighted.loadField, .weightKg)
        let deficit = exercise("HSPU deficit")
        XCTAssertEqual(deficit.loggingStyle, .loadAndReps)
        XCTAssertEqual(deficit.loadField, .deficitCm)
    }

    func testSnatchByImplementUsesThreeDistinctExercises() {
        let variants = [
            exercise("Snatch"),
            exercise("Dumbbell Snatch"),
            exercise("Kettlebell Snatch")
        ]
        XCTAssertEqual(variants.map(\.equipment), ["Barra", "Mancuernas", "Kettlebell"])
        XCTAssertEqual(Set(variants.map(\.name)).count, 3)
        XCTAssertEqual(Set(variants.map(\.id)).count, 3)
        XCTAssertEqual(variants.map(\.loggingStyle), [.loadAndReps, .loadAndReps, .loadAndReps])
    }

    func testUnloadedMovementsStillUseBodyweight() {
        for name in ["Broad jump", "Air squat", "Burpee", "Gato-vaca"] {
            let item = exercise(name)
            XCTAssertEqual(item.equipment, "Peso corporal", name)
        }
    }

    func testEquipmentSortingRecognizesSpecificTools() {
        XCTAssertEqual(ExerciseEquipmentGroup.category(name: "Remo invertido", equipment: "Barra fija"), "Barras de dominadas")
        XCTAssertEqual(ExerciseEquipmentGroup.category(name: "Ab wheel", equipment: "Rueda abdominal"), "Ruedas abdominales")
        XCTAssertEqual(ExerciseEquipmentGroup.category(name: "SkiErg", equipment: "SkiErg"), "SkiErg / esquí de aire")
        XCTAssertEqual(ExerciseEquipmentGroup.category(name: "Toes to rings", equipment: "Anillas"), "Anillas")
    }
}
