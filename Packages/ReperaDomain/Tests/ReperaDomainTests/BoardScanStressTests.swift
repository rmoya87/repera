import XCTest
@testable import ReperaDomain

final class BoardScanStressTests: XCTestCase {
    func testEachOCRLineAlone() throws {
        let lines = [
            "EMOM 12.",
            "4-3-3-2 W.S. PULL UPS @RIR 2-1",
            "5-10 KIPPING HSPU @FQ",
            "1, REST",
            "EMOM 8.",
            "ODD: 6-8 DB ALT HANG SNATCH @HEAVY",
            "EVEN: 45 MAX DU",
            "AMRAP12'",
            "5 DDB DEVIL PRESS 20/12,5",
            "10 T2B",
            "200M RUN",
        ]
        let data = try Data(contentsOf: URL(fileURLWithPath: "/tmp/repera-parser-bench/exercises.json"))
        struct E: Decodable {
            let id: UUID; let name: String; let muscleGroup: String; let isCustom: Bool
            let equipment: String?; let catalogId: String?; let targetMuscle: String?
            let secondaryMuscles: [String]?; let bodyPart: String?; let detailDescription: String?
            let instructions: [String]?; let primaryRegions: [String]?; let secondaryRegions: [String]?
            let isFavorite: Bool?
        }
        let catalog = try JSONDecoder().decode([E].self, from: data).map {
            Exercise(id: $0.id, name: $0.name, muscleGroup: $0.muscleGroup, equipment: $0.equipment,
                     isCustom: $0.isCustom, catalogId: $0.catalogId, targetMuscle: $0.targetMuscle,
                     secondaryMuscles: $0.secondaryMuscles ?? [], bodyPart: $0.bodyPart,
                     detailDescription: $0.detailDescription, instructions: $0.instructions ?? [],
                     primaryRegions: $0.primaryRegions ?? [], secondaryRegions: $0.secondaryRegions ?? [],
                     isFavorite: $0.isFavorite ?? false)
        }
        for (i, line) in lines.enumerated() {
            let t0 = CFAbsoluteTimeGetCurrent()
            let blocks = BoardImportParser.parseBlocks(ocrText: line, catalog: catalog)
            let ms = Int((CFAbsoluteTimeGetCurrent()-t0)*1000)
            print("LINE[\(i)] \(ms)ms blocks=\(blocks.count) «\(line)»")
            XCTAssertLessThan(ms, 3000, "line \(i) hung: \(line)")
        }
        let t0 = CFAbsoluteTimeGetCurrent()
        let all = BoardImportParser.parseBlocks(ocrText: lines.joined(separator: "\n"), catalog: catalog)
        print("ALL \(Int((CFAbsoluteTimeGetCurrent()-t0)*1000))ms blocks=\(all.count)")
    }
}
