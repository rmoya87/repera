import Foundation
import ReperaDomain

/// OCR → local (lite + score + repair) → Apple Intelligence si FM disponible (timeout).
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

    /// Timeout duro para Foundation Models (evita «Leyendo…» infinito).
    static let aiTimeoutSeconds: TimeInterval = 4

    struct Result: Sendable {
        var ocrText: String
        var blocks: [RoutineBlock]
        var lines: [BoardImportLine]
        var source: Source
        var confidence: Double
    }

    /// Pipeline completo: local + IA on-device cuando hay Foundation Models.
    static func interpret(ocrText: String, catalog: [Exercise]) async -> Result {
        let local = interpretLocal(ocrText: ocrText, catalog: catalog)
        guard BoardAIImporter.isAvailable else {
            BoardScanLog.step("pipeline.ai", "skip unavailable")
            BoardScanLog.step("pipeline.done", "source=localRules score=\(String(format: "%.2f", local.confidence))")
            return local
        }

        BoardScanLog.step("pipeline.ai", "attempt timeout=\(Int(aiTimeoutSeconds))s")
        let t0 = CFAbsoluteTimeGetCurrent()
        let aiBlocks = await withTimeout(seconds: aiTimeoutSeconds) {
            await BoardAIImporter.interpret(ocrText: local.ocrText)
        }
        let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)

        guard let aiBlocks, !aiBlocks.isEmpty else {
            BoardScanLog.step("pipeline.ai", "timeout_or_fail \(ms)ms → local")
            BoardScanLog.step("pipeline.done", "source=localRules score=\(String(format: "%.2f", local.confidence))")
            return local
        }

        var enriched = BoardScanLiteParser.enrichBlocks(aiBlocks, catalog: catalog)
        // The local parse already identified phases/collaboration; AI may
        // refine movement names but must not erase these semantics.
        if enriched.count == local.blocks.count {
            for index in enriched.indices {
                enriched[index].structure = enriched[index].structure ?? local.blocks[index].structure
                enriched[index].timeCapSeconds = enriched[index].timeCapSeconds ?? local.blocks[index].timeCapSeconds
            }
        }
        guard BoardScanAIResultGuard.isConsistent(
            localBlocks: local.blocks, proposedBlocks: enriched
        ) else {
            BoardScanLog.step("pipeline.ai", "rejected structure mismatch → local")
            BoardScanLog.step("pipeline.done", "source=localRules score=\(String(format: "%.2f", local.confidence))")
            return local
        }
        let lines = BoardScanLiteParser.importLines(from: enriched, catalog: catalog)
        BoardScanLog.step("pipeline.ai", "ok \(ms)ms blocks=\(enriched.count)")
        for (i, b) in enriched.enumerated() {
            BoardScanLog.info(
                "    ai[\(i)] \(b.headerLabel) fmt=\(b.wodFormat?.rawValue ?? "—") moves=\(b.movements.count)"
            )
        }
        BoardScanLog.step("pipeline.done", "source=appleIntelligence")
        return Result(
            ocrText: local.ocrText,
            blocks: enriched,
            lines: lines,
            source: .appleIntelligence,
            confidence: local.confidence
        )
    }

    /// Solo local (tests / callers síncronos). Incluye repair si score bajo.
    static func interpretSync(ocrText: String, catalog: [Exercise]) -> Result {
        interpretLocal(ocrText: ocrText, catalog: catalog)
    }

    private static func interpretLocal(ocrText: String, catalog: [Exercise]) -> Result {
        BoardScanLog.step("pipeline.start", "local chars=\(ocrText.count) catalog=\(catalog.count)")
        let t0 = CFAbsoluteTimeGetCurrent()
        let parsed = BoardScanLocalPipeline.interpret(ocrText: ocrText, catalog: catalog)
        let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
        BoardScanLog.step(
            "pipeline.local",
            "\(ms)ms blocks=\(parsed.blocks.count) lines=\(parsed.lines.count) score=\(String(format: "%.2f", parsed.confidence.score)) repair=\(parsed.didRepair) reasons=\(parsed.confidence.reasons.joined(separator: ","))"
        )
        for (i, b) in parsed.blocks.enumerated() {
            BoardScanLog.info(
                "    local[\(i)] \(b.headerLabel) fmt=\(b.wodFormat?.rawValue ?? "—") moves=\(b.movements.count)"
            )
        }
        return Result(
            ocrText: parsed.ocrText,
            blocks: parsed.blocks,
            lines: parsed.lines,
            source: .localRules,
            confidence: parsed.confidence.score
        )
    }

    /// Primer resultado gana; el perdedor se cancela (timeout → nil).
    private static func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async -> T?
    ) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await operation() }
            group.addTask {
                let ns = UInt64(max(seconds, 0.1) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first ?? nil
        }
    }
}
