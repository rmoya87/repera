import XCTest
@testable import ReperaDomain

/// OCR real capturado en rPhone (BoardScan.log 2026-10-18) — no debe colgar ni devolver vacío.
final class BoardScanHangReproTests: XCTestCase {
    func testDeviceLogOCRParsesThreeBlocksQuickly() {
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
        let catalog = [
            "Pull-Up", "Handstand Push-Up", "Dumbbell Snatch",
            "Double Under", "Devil Press", "Toes-to-Bar", "Run",
        ].map { Exercise(name: $0, muscleGroup: "WOD", isCustom: false) }

        let t0 = CFAbsoluteTimeGetCurrent()
        let blocks = BoardImportParser.parseBlocks(ocrText: ocr, catalog: catalog)
        let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)

        XCTAssertLessThan(ms, 2_000, "parseBlocks tardó \(ms)ms")
        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0].wodFormat, .emom)
        XCTAssertEqual(blocks[1].wodFormat, .emom)
        XCTAssertEqual(blocks[2].wodFormat, .amrap)
        let strong = blocks.filter {
            $0.movements.contains { !$0.isRest } || !$0.exercises.isEmpty
        }.count
        XCTAssertGreaterThanOrEqual(strong, 2, "debe ser strong-local (≥2) para skip IA")
    }
}
