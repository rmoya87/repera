import XCTest
@testable import ReperaDomain

/// La ficha no debe mostrar una leyenda que pertenezca a otra fase.
final class ExerciseArtCaptionTests: XCTestCase {
    func testCarouselCaptionCountsMatchExportedSequences() {
        let expected: [String: Int] = [
            "Press banca": 2,
            "Press banca inclinada": 2,
            "Aperturas": 2,
            "Dominadas": 2,
            "Peso muerto": 2,
            "Peso muerto rumano": 2,
            "Sentadilla": 2,
            "Sentadilla frontal": 2,
            "Zancadas": 3,
            "Sentadilla búlgara": 3,
            "Press militar": 2,
            "Hip thrust": 2,
            "Cargada": 3,
            "Cargada colgante": 3,
            "Arrancada": 3,
            "Cargada y envión": 3,
            "Split jerk": 3,
            "Overhead squat": 3,
            "Thruster": 3,
            "Cluster": 3,
            "Burpee": 3,
            "Salto al cajón": 3,
            "Muscle-up barra": 3,
            "Muscle-up anillas": 3,
            "Toes to bar": 3,
            "Chest to bar": 3,
            "HSPU": 3,
            "Wall walk": 3,
            "Fondos en anillas": 3,
            "Rope climb": 3,
            "GHD sit-up": 3,
            "Snatch kettlebell": 3,
            "Turkish get-up": 3,
            "Wall ball": 3,
            "Devil press": 3,
            "Fondos en paralelas": 2,
            "Burpee pull-up": 3,
            "Air squat": 3,
            "Swing kettlebell": 3,
            "Goblet squat": 3,
            "Thruster mancuernas": 3,
            "Thruster kettlebell": 3,
            "Man maker": 6,
            "Pistol squat": 3,
            "Ball slam": 3,
            "Broad jump": 3,
            "Jumping lunge": 3,
            "Burpee al cajón": 3,
            "Jumping squat": 3,
            "Snatch mancuerna": 3,
            "Clean kettlebell": 3,
            "Box jump over": 3,
        ]
        for (name, count) in expected {
            let captions = CatalogSpanish.instructions(forName: name)
            XCTAssertGreaterThanOrEqual(
                captions?.count ?? 0,
                count,
                "Faltan captions de fase (mín. \(count)): \(name)"
            )
            XCTAssertGreaterThanOrEqual(
                (captions?.count ?? 0) - count,
                4,
                "Faltan pasos de coaching tras las fases: \(name)"
            )
        }
    }

    func testCarouselCaptionsContainNoImageEditorialNotes() {
        let names = [
            "Peso muerto rumano", "Fondos en paralelas", "Thruster",
            "Turkish get-up", "Wall ball", "Muscle-up barra",
            "Muscle-up anillas", "GHD sit-up",
        ]
        for name in names {
            guard let captions = CatalogSpanish.instructions(forName: name) else {
                XCTFail("Faltan instructions para \(name)")
                continue
            }
            for caption in captions {
                XCTAssertFalse(caption.contains("imagen:"), "Nota editorial en \(name)")
                XCTAssertFalse(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    /// La compuerta del carrusel consulta `CatalogSpanish.instructions(forName:)`
    /// con el nombre SEMBRADO (CrossFit/Halterofilia siembran el canonico ingles
    /// via `SportExerciseNames.displayName`; Gimnasia conserva el nombre tal cual).
    /// Este test parte de las filas reales del catalogo para que ningun carrusel
    /// dependa de una clave que la UI no puede alcanzar (p. ej. probar
    /// "Snatch mancuerna" cuando la ficha recibe "Dumbbell Snatch" y confia en
    /// el puente `SportExerciseNames.spanishAlias`).
    func testCarouselCaptionsResolveFromSeededExerciseNames() {
        let expected: [(catalog: String, sport: String, frames: Int)] = [
            ("Snatch mancuerna", "CrossFit", 3),
            ("Swing kettlebell", "CrossFit", 3),
            ("Thruster mancuernas", "CrossFit", 3),
            ("Thruster kettlebell", "CrossFit", 3),
            ("Clean kettlebell", "CrossFit", 3),
            ("Burpee al cajón", "CrossFit", 3),
            ("Man maker", "CrossFit", 6),
            ("Ball slam", "CrossFit", 3),
            ("Broad jump", "CrossFit", 3),
            ("Goblet squat", "CrossFit", 3),
            ("Pistol squat", "Gimnasia", 3),
            ("Air squat", "Gimnasia", 3),
            ("Jumping squat", "Gimnasia", 3),
            ("Jumping lunge", "Gimnasia", 3),
        ]
        let rows = CatalogCrossFit.rows + CatalogGimnasia.rows
        for (catalogName, sport, frames) in expected {
            let seededName = SportExerciseNames.displayName(catalogName, sport: sport)
            guard let row = rows.first(where: { $0.name == seededName }) else {
                XCTFail("Falta la fila sembrada en el catalogo: \(catalogName) -> \(seededName)")
                continue
            }
            let captions = CatalogSpanish.instructions(forName: row.name)
            XCTAssertGreaterThanOrEqual(
                captions?.count ?? 0,
                frames,
                "La UI no alcanza las captions de fase desde el nombre sembrado \(row.name) (catalogo: \(catalogName))"
            )
            XCTAssertGreaterThanOrEqual(
                (captions?.count ?? 0) - frames,
                4,
                "Faltan pasos de coaching tras las fases: \(row.name)"
            )
        }
    }

}
