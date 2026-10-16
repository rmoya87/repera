import Foundation
import GymbroDomain

/// OCR → Apple Intelligence (si hay) → si no, parser local gratis.
enum BoardImportPipeline {
    enum Source: String, Sendable {
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

    static func interpret(ocrText: String, catalog: [Exercise]) async -> Result {
        // 1) Parser local primero: si ya hay ≥2 bloques con movimientos, no llamar a la IA.
        let localBlocks = BoardImportParser.parseBlocks(ocrText: ocrText, catalog: catalog)
        let localMovements = localBlocks.reduce(0) { $0 + $1.movements.filter { !$0.isRest }.count }
        if localBlocks.count >= 2, localMovements >= 2 {
            var lines = BoardImportParser.parse(ocrText: ocrText, catalog: catalog)
            if lines.isEmpty {
                lines = linesFrom(blocks: localBlocks, catalog: catalog, ocrText: ocrText)
            }
            BoardScanLog.parse(
                blocks: localBlocks.count,
                lines: lines.count,
                movements: localMovements
            )
            BoardScanLog.info("Pipeline: fuente=localRules (skip IA · ≥2 bloques)")
            return Result(ocrText: ocrText, blocks: localBlocks, lines: lines, source: .localRules)
        }

        // 2) Mini-IA on-device si el dispositivo lo permite (gratis con Apple Intelligence).
        if let aiBlocks = await BoardAIImporter.interpret(ocrText: ocrText), !aiBlocks.isEmpty {
            let enriched = enrich(blocks: aiBlocks, catalog: catalog)
            let lines = linesFrom(blocks: enriched, catalog: catalog, ocrText: ocrText)
            BoardScanLog.parse(
                blocks: enriched.count,
                lines: lines.count,
                movements: enriched.reduce(0) { $0 + $1.movements.filter { !$0.isRest }.count }
            )
            BoardScanLog.info("Pipeline: fuente=appleIntelligence")
            return Result(ocrText: ocrText, blocks: enriched, lines: lines, source: .appleIntelligence)
        }

        // 3) Fallback gratis: reglas / regex (siempre disponible).
        var lines = BoardImportParser.parse(ocrText: ocrText, catalog: catalog)
        if lines.isEmpty, !localBlocks.isEmpty {
            lines = linesFrom(blocks: localBlocks, catalog: catalog, ocrText: ocrText)
        }
        BoardScanLog.parse(
            blocks: localBlocks.count,
            lines: lines.count,
            movements: localMovements
        )
        BoardScanLog.info("Pipeline: fuente=localRules")
        return Result(ocrText: ocrText, blocks: localBlocks, lines: lines, source: .localRules)
    }

    private static func linesFrom(
        blocks: [RoutineBlock],
        catalog: [Exercise],
        ocrText: String
    ) -> [BoardImportLine] {
        let fromBlocks = blocks.flatMap(\.movements).filter { !$0.isRest }.map { move in
            BoardImportLine(
                raw: move.summaryLine,
                matchedExerciseId: move.exerciseId,
                matchedName: move.name,
                sets: 1,
                reps: move.reps ?? 1
            )
        }
        if !fromBlocks.isEmpty { return fromBlocks }
        return BoardImportParser.parse(ocrText: ocrText, catalog: catalog)
    }

    /// Empareja movimientos AI con el catálogo local.
    private static func enrich(blocks: [RoutineBlock], catalog: [Exercise]) -> [RoutineBlock] {
        blocks.map { block in
            var b = block
            b.movements = block.movements.map { move in
                guard !move.isRest else { return move }
                var m = move
                if m.exerciseId == nil {
                    let match = catalog.first {
                        CrossFitGlossary.normalize($0.name) == CrossFitGlossary.normalize(m.name)
                    } ?? catalog.first {
                        let hay = CrossFitGlossary.normalize($0.name)
                        let needle = CrossFitGlossary.normalize(m.name)
                        return hay.contains(needle) || needle.contains(hay)
                    }
                    m.exerciseId = match?.id
                    if let match { m.name = match.name }
                }
                return m
            }
            return b
        }
    }
}
