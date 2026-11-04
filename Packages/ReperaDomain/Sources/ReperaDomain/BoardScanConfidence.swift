import Foundation

/// Score 0…1 de fiabilidad del parseo local de pizarra (1 = muy fiable).
public enum BoardScanConfidence {
    public struct Assessment: Sendable, Equatable {
        public var score: Double
        public var reasons: [String]

        public init(score: Double, reasons: [String]) {
            self.score = min(1, max(0, score))
            self.reasons = reasons
        }

        /// Por debajo: LocalRepair.
        public static let repairThreshold: Double = 0.85
    }

    public static func assess(ocrText: String, output: BoardScanLiteParser.Output) -> Assessment {
        var score = 1.0
        var reasons: [String] = []

        let ocrLines = ocrText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let blocks = output.blocks

        if blocks.isEmpty {
            score -= 0.55
            reasons.append("no_blocks")
            return Assessment(score: score, reasons: reasons)
        }

        // Un solo cajón catch-all con muchas líneas OCR → estructura débil.
        if blocks.count == 1 {
            let title = blocks[0].title.uppercased()
            if title.contains("AÑADIR ENTRENO") || title == "CHIPPER" || blocks[0].wodFormat == .chipper {
                if ocrLines.count >= 4 {
                    score -= 0.28
                    reasons.append("catch_all_block")
                }
            }
        }

        // Muchas líneas OCR y pocos bloques.
        if ocrLines.count >= 8, blocks.count == 1 {
            score -= 0.18
            reasons.append("few_blocks_vs_lines")
        }

        let movements = blocks.flatMap { block -> [WODMovement] in
            if block.kind == .strength { return [] }
            return block.movements.filter { !$0.isRest }
        }
        let strengthExercises = blocks.filter { $0.kind == .strength }.flatMap(\.exercises)
        let workCount = movements.count + strengthExercises.count

        if workCount == 0, !ocrLines.isEmpty {
            score -= 0.35
            reasons.append("no_movements")
        }

        if !movements.isEmpty {
            let unmatched = movements.filter { $0.exerciseId == nil }.count
            let ratio = Double(unmatched) / Double(movements.count)
            if ratio >= 0.5 {
                score -= 0.30
                reasons.append("catalog_match_low")
            } else if ratio >= 0.25 {
                score -= 0.15
                reasons.append("catalog_match_mid")
            }

            let untyped = movements.filter {
                $0.reps == nil && $0.repScheme == nil
                    && $0.distanceMeters == nil && $0.calories == nil
            }.count
            let untypedRatio = Double(untyped) / Double(movements.count)
            if untypedRatio >= 0.4 {
                score -= 0.12
                reasons.append("untyped_movements")
            }
        }

        // Cabeceras / formatos ambiguos frecuentes en pizarra versátil.
        for block in blocks {
            let header = (block.wodNotes ?? block.title).uppercased()
            if header.contains("EVERY") || header.contains("CADA ") {
                if block.kind != .strength, block.wodFormat == .emom, block.movements.count == 1 {
                    score -= 0.08
                    reasons.append("ambiguous_every")
                    break
                }
            }
        }

        // Ruido OCR residual típico sin normalizar.
        let joined = ocrText.uppercased()
        if joined.range(of: #"\dRF[TF]\b"#, options: .regularExpression) != nil
            || joined.range(of: #"\dBOB\b"#, options: .regularExpression) != nil {
            score -= 0.10
            reasons.append("ocr_noise")
        }

        return Assessment(score: score, reasons: Array(Set(reasons)).sorted())
    }
}
