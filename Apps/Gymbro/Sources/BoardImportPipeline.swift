import Foundation
import GymbroDomain

/// OCR → parser lite síncrono. Sin hilos, sin IA, sin BoardImportParser pesado.
enum BoardImportPipeline {
    enum Source: String, Sendable, Hashable {
        case appleIntelligence
        case localRules

        var reviewLabel: String {
            switch self {
            case .appleIntelligence: return "Apple Intelligence"
            case .localRules: return "Análisis local"
            }
        }
    }

    struct Result: Sendable {
        var ocrText: String
        var blocks: [RoutineBlock]
        var lines: [BoardImportLine]
        var source: Source
    }

    /// Síncrono y barato. `async` solo para encajar en callers existentes.
    static func interpret(ocrText: String, catalog: [Exercise]) async -> Result {
        interpretSync(ocrText: ocrText, catalog: catalog)
    }

    static func interpretSync(ocrText: String, catalog: [Exercise]) -> Result {
        BoardScanLog.step("pipeline.start", "lite chars=\(ocrText.count) catalog=\(catalog.count)")
        let t0 = CFAbsoluteTimeGetCurrent()
        let parsed = BoardScanLiteParser.parse(ocrText: ocrText, catalog: catalog)
        let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
        BoardScanLog.step(
            "pipeline.local",
            "lite \(ms)ms blocks=\(parsed.blocks.count) lines=\(parsed.lines.count)"
        )
        for (i, b) in parsed.blocks.enumerated() {
            BoardScanLog.info(
                "    lite[\(i)] \(b.headerLabel) fmt=\(b.wodFormat?.rawValue ?? "—") moves=\(b.movements.count)"
            )
        }
        BoardScanLog.step("pipeline.done", "source=localRules (lite)")
        return Result(
            ocrText: ocrText,
            blocks: parsed.blocks,
            lines: parsed.lines,
            source: .localRules
        )
    }
}
