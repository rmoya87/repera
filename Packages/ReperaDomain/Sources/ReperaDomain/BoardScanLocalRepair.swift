import Foundation

/// Reparación local síncrona antes de IA: extra OCR + re-parse lite; conserva el mejor score.
public enum BoardScanLocalRepair {
    public struct Output: Sendable {
        public var ocrText: String
        public var parsed: BoardScanLiteParser.Output
        public var assessment: BoardScanConfidence.Assessment
        public var didRepair: Bool
    }

    /// Extra normalizaciones baratas encima de `BoardScanLiteParser.normalizeOCRNoise`.
    public static func extraNormalize(_ text: String) -> String {
        var t = BoardScanLiteParser.normalizeOCRNoise(text)
        t = t
            // Push Jek / Jrk → Jerk
            .replacingOccurrences(
                of: #"(?i)\b(PUSH|SPLIT|HANG)?\s*JE[CK]K?\b"#,
                with: "$1 JERK",
                options: .regularExpression
            )
            .replacingOccurrences(of: #"(?i)\bJRK\b"#, with: "JERK", options: .regularExpression)
            // GTOH / G.T.O.H
            .replacingOccurrences(of: #"(?i)\bG\.?T\.?O\.?H\.?\b"#, with: "GTOH", options: .regularExpression)
            // C2B / C 2 B
            .replacingOccurrences(of: #"(?i)\bC\s*2\s*B\b"#, with: "C2B", options: .regularExpression)
            // BMU / B M U
            .replacingOccurrences(of: #"(?i)\bB\s*M\s*U\b"#, with: "BMU", options: .regularExpression)
            // E2MOM / E 2 MOM → EVERY 2'
            .replacingOccurrences(
                of: #"(?i)\bE\s*(\d+)\s*MOM\b"#,
                with: "EVERY $1'",
                options: .regularExpression
            )
            // FORTlME / FORTIME pegado
            .replacingOccurrences(of: #"(?i)\bFORTIME\b"#, with: "FOR TIME", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)\bFORTlME\b"#, with: "FOR TIME", options: .regularExpression)
            // Calorías pegadas 20CAL / 16CALS
            .replacingOccurrences(
                of: #"(?i)(\d+)\s*CALS?(?:ORIES)?\b"#,
                with: "$1 CAL",
                options: .regularExpression
            )
            // Metros pegados 200M / 400mRUN
            .replacingOccurrences(
                of: #"(?i)(\d+)\s*M\s*(RUN|ROW|WALK|BIKE)?\b"#,
                with: "$1M $2",
                options: .regularExpression
            )
            // Espacios múltiples
            .replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        return t
    }

    public static func repair(
        ocrText: String,
        catalog: [Exercise],
        previous: BoardScanLiteParser.Output
    ) -> Output {
        let previousScore = BoardScanConfidence.assess(ocrText: ocrText, output: previous)
        let cleaned = extraNormalize(ocrText)
        let reparsed = BoardScanLiteParser.parse(ocrText: cleaned, catalog: catalog)
        let next = BoardScanConfidence.assess(ocrText: cleaned, output: reparsed)
        if next.score > previousScore.score
            || (next.score == previousScore.score && reparsed.blocks.count >= previous.blocks.count
                && cleaned != ocrText) {
            return Output(ocrText: cleaned, parsed: reparsed, assessment: next, didRepair: cleaned != ocrText)
        }
        return Output(ocrText: ocrText, parsed: previous, assessment: previousScore, didRepair: false)
    }
}
