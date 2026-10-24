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
}
