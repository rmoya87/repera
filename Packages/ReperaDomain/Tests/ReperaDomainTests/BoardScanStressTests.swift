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
        // Test autosuficiente: el catálogo completo de producción sustituye a /tmp.
        let catalog = Catalog.seed()
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
