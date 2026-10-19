import XCTest
@testable import ReperaDomain

final class BoardScanFullCatalogTests: XCTestCase {
    func testFullDeviceCatalogDoesNotHang() throws {
        // Reproduce la importación con el catálogo embarcado, no un JSON temporal local.
        let catalog = Catalog.seed()
        XCTAssertGreaterThanOrEqual(catalog.count, 188)
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
