import XCTest
@testable import ReperaDomain

final class ExerciseEquipmentGroupTests: XCTestCase {
    func testSpecificEquipmentOverridesGenericMachineOrBodyweight() {
        let samples: [(String, String?, String)] = [
            ("Wall ball", "Balón medicinal", "Wall Balls"),
            ("Ball slam", "Balón medicinal", "Slam Balls"),
            ("Medball clean", "Balón medicinal", "Balones medicinales"),
            ("Lanzamiento genérico", "Wall Balls", "Wall Balls"),
            ("Trabajo con balón", "Slam Balls", "Slam Balls"),
            ("Burpee al cajón", "Peso corporal", "Cajones"),
            ("Box jump over", "Peso corporal", "Cajones"),
            ("Subida", "Box", "Cajones"),
            ("Step-up al cajón con kettlebell goblet", "Cajón, Kettlebell", "Cajones"),
            ("Box Squat", "Barra", "Barras"),
            ("Dumbbell Box Step Up", "Cajón, Mancuernas", "Cajones"),
            ("Tire Flip", "Neumático", "Neumáticos"),
            ("Back lever tuck", "Anillas", "Anillas"),
            ("Front lever tuck", "Barra de dominadas", "Barras de dominadas"),
            ("Couch stretch", "Pared", "Paredes"),
            ("Couch stretch", "Peso corporal", "Paredes"),
            ("Double-Under", "Comba", "Combas"),
            ("Simples de comba", "Comba", "Combas"),
            ("Remo máquina", "Máquina", "Remoergómetros"),
            ("RowErg", nil, "Remoergómetros"),
            ("Remar", "RowErg", "Remoergómetros"),
            ("SkiErg", "Máquina", "SkiErg / esquí de aire"),
            ("Movilidad", "Esquís de aire", "SkiErg / esquí de aire"),
            ("Esquí de aire", nil, "SkiErg / esquí de aire"),
            ("GHD sit-up", "Máquina", "GHD"),
            ("GHD back extension", "Máquina", "GHD"),
            ("Extensión", "GHD", "GHD"),
            ("Sled push", "Trineo", "Trineos"),
            ("Sled pull", "Trineo", "Trineos"),
            ("Sandbag Lunges", "Saco", "Sacos de arena"),
            ("Sandbag over shoulder", "Saco", "Sacos de arena"),
            ("Yoke carry", "Yoke", "Yugos"),
            ("Air bike", nil, "Bicicletas y Air Bikes"),
            ("Echo bike", nil, "Bicicletas y Air Bikes"),
            ("Rope climb", "Peso corporal", "Cuerdas de trepa"),
            ("Muscle-up anillas", "Peso corporal", "Anillas"),
            ("Toes to bar", "Peso corporal", "Barras de dominadas"),
            ("Pull-over barra", "Peso corporal", "Barras de dominadas"),
            ("Pegboard", "Peso corporal", "Pegboards"),
        ]
        for (name, equipment, expected) in samples {
            XCTAssertEqual(
                ExerciseEquipmentGroup.category(name: name, equipment: equipment),
                expected, "Grupo de material incorrecto para \(name)"
            )
        }
    }

    func testAccessoryEquipmentAndUnspecifiedNames() {
        let samples: [(String, String?, String)] = [
            ("Curl mancuernas", "Mancuernas", "Mancuernas"),
            ("Goblet squat", "Kettlebell", "Kettlebells"),
            ("Paso lateral con banda", "Banda elástica", "Bandas y gomas"),
            ("Sentadilla con barra", "Barra", "Barras"),
            ("Plate ground to overhead", "Disco", "Discos"),
            ("Extensión tríceps polea", "Polea", "Poleas"),
            ("Pasadas de hombros con pica", "Pica", "Picas"),
            ("Extensión torácica con rodillo", "Rodillo", "Rodillos"),
            ("Estiramiento de dorsal en banco", "Banco", "Bancos"),
            ("Rodilla a pared para tobillo", "Pared", "Paredes"),
            ("Estiramiento de hombro en marco", "Marco de puerta", "Marcos de puerta"),
            ("Sentadilla aire", "Peso corporal", "Peso corporal"),
            ("Movimiento especial", nil, "Sin material"),
            ("Movimiento especial", "TRX", "TRX"),
        ]
        for (name, equipment, expected) in samples {
            XCTAssertEqual(
                ExerciseEquipmentGroup.category(name: name, equipment: equipment),
                expected, "Grupo incorrecto para \(name)"
            )
        }
    }

    func testRealCatalogAlwaysHasAGroupWithoutChangingIdentity() {
        let originals = Catalog.seed()
        let ids = originals.map(\.id)
        XCTAssertEqual(originals.count, 476)
        for exercise in originals {
            XCTAssertFalse(ExerciseEquipmentGroup.category(for: exercise).isEmpty)
        }
        XCTAssertEqual(ids, originals.map(\.id))
    }

    func testRemoConBarraMustNotBeTreatedAsRower() {
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(name: "Remo con barra", equipment: "Barra"),
            "Barras"
        )
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(name: "Remo sentado", equipment: "Polea"),
            "Poleas"
        )
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(name: "Remo en anillas", equipment: "Peso corporal"),
            "Anillas"
        )
    }

    func testDeclaredEquipmentWinsOverNameHeuristics() {
        // El nombre menciona «box» pero el material principal es la barra.
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(name: "Box Squat", equipment: "Barra"),
            "Barras"
        )
        // «neumatico» contiene «mat»; no debe agruparse como colchoneta.
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(name: "Tire Flip", equipment: "Neumático"),
            "Neumáticos"
        )
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(name: "Ab Mat Sit-Up", equipment: "AbMat"),
            "AbMats"
        )
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(name: "Hollow hold", equipment: "Colchoneta"),
            "Colchonetas"
        )
    }

    func testCatalogPullUpBarAndBackLeverEquipment() {
        let catalog = Catalog.seed()
        let byName = Dictionary(uniqueKeysWithValues: catalog.map { ($0.name, $0) })
        XCTAssertEqual(byName["Back lever tuck"]?.equipment, "Anillas")
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(for: byName["Back lever tuck"]),
            "Anillas"
        )
        XCTAssertEqual(byName["Couch stretch"]?.equipment, "Pared")
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(for: byName["Couch stretch"]),
            "Paredes"
        )
        for name in ["Jumping Pull-Up", "L Pull Up", "Negative Pull Up",
                     "Dead Hang", "Hanging Knee Raise", "Strict Knees To Chest"] {
            XCTAssertEqual(byName[name]?.equipment, "Barra de dominadas", name)
            XCTAssertEqual(
                ExerciseEquipmentGroup.category(for: byName[name]),
                "Barras de dominadas",
                name
            )
        }
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(for: byName["Tire Flip"]),
            "Neumáticos"
        )
        XCTAssertEqual(
            ExerciseEquipmentGroup.category(for: byName["Box Squat"]),
            "Barras"
        )
    }
}
