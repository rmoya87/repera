import Foundation

/// Paso local compartido: lite → score → repair si score &lt; 0,85.
/// Usado por iOS (antes de IA) y Android (único camino inteligente).
public enum BoardScanLocalPipeline {
    public struct Result: Sendable {
        public var ocrText: String
        public var blocks: [RoutineBlock]
        public var lines: [BoardImportLine]
        public var confidence: BoardScanConfidence.Assessment
        public var didRepair: Bool
    }

    public static func interpret(ocrText: String, catalog: [Exercise] = []) -> Result {
        // Normalizar siempre: el lite ya limpia al parsear, pero el texto
        // conservado / score / IA deben ver la misma forma.
        let normalized = BoardScanLocalRepair.extraNormalize(ocrText)
        let lite = BoardScanLiteParser.parse(ocrText: normalized, catalog: catalog)
        var assessment = BoardScanConfidence.assess(ocrText: normalized, output: lite)
        var text = normalized
        var parsed = lite
        var didRepair = normalized != ocrText

        if assessment.score < BoardScanConfidence.Assessment.repairThreshold {
            let repaired = BoardScanLocalRepair.repair(
                ocrText: normalized, catalog: catalog, previous: lite
            )
            text = repaired.ocrText
            parsed = repaired.parsed
            assessment = repaired.assessment
            didRepair = didRepair || repaired.didRepair
        }

        return Result(
            ocrText: text,
            blocks: parsed.blocks,
            lines: parsed.lines,
            confidence: assessment,
            didRepair: didRepair
        )
    }
}
