import XCTest
@testable import GymbroDomain

final class BoardScanFullCatalogTests: XCTestCase {
    func testFullDeviceCatalogDoesNotHang() throws {
        let url = URL(fileURLWithPath: "/tmp/gymbro-parser-bench/exercises.json")
        let data = try Data(contentsOf: url)
        struct E: Decodable {
            let id: UUID; let name: String; let muscleGroup: String; let isCustom: Bool
            let equipment: String?; let catalogId: String?; let targetMuscle: String?
            let secondaryMuscles: [String]?; let bodyPart: String?; let detailDescription: String?
            let instructions: [String]?; let primaryRegions: [String]?; let secondaryRegions: [String]?
            let isFavorite: Bool?
        }
        let decoded = try JSONDecoder().decode([E].self, from: data)
        let catalog = decoded.map {
            Exercise(id: $0.id, name: $0.name, muscleGroup: $0.muscleGroup, equipment: $0.equipment,
                     isCustom: $0.isCustom, catalogId: $0.catalogId, targetMuscle: $0.targetMuscle,
                     secondaryMuscles: $0.secondaryMuscles ?? [], bodyPart: $0.bodyPart,
                     detailDescription: $0.detailDescription, instructions: $0.instructions ?? [],
                     primaryRegions: $0.primaryRegions ?? [], secondaryRegions: $0.secondaryRegions ?? [],
                     isFavorite: $0.isFavorite ?? false)
        }
        XCTAssertEqual(catalog.count, 188)
        let ocr = """
        EMOM 12.
        4-3-3-2 W.S. PULL UPS @RIR 2-1
        5-10 KIPPING HSPU @FQ
        1, REST
        EMOM 8.
        ODD: 6-8 DB ALT HANG SNATCH @HEAVY
        EVEN: 45 MAX DU
        AMRAP12'
        5 DDB DEVIL PRESS 20/12,5
        10 T2B
        200M RUN
        """
        let exp = expectation(description: "parse")
        DispatchQueue.global().async {
            let t0 = CFAbsoluteTimeGetCurrent()
            let blocks = BoardImportParser.parseBlocks(ocrText: ocr, catalog: catalog)
            _ = BoardImportParser.parse(ocrText: ocr, catalog: catalog)
            print("FULLCAT \(Int((CFAbsoluteTimeGetCurrent()-t0)*1000))ms blocks=\(blocks.count)")
            XCTAssertEqual(blocks.count, 3)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
}
