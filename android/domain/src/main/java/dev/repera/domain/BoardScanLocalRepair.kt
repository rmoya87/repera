package dev.repera.domain

/** Reparación local síncrona: extra OCR + re-parse lite (paridad iOS). */
object BoardScanLocalRepair {
    data class Output(
        val ocrText: String,
        val parsed: BoardScanLiteParser.Output,
        val assessment: BoardScanConfidence.Assessment,
        val didRepair: Boolean
    )

    fun extraNormalize(text: String): String {
        var t = BoardScanLiteParser.normalizeOCRNoise(text)
        t = t
            .replace(Regex("""\b(PUSH|SPLIT|HANG)?\s*JE[CK]K?\b""", RegexOption.IGNORE_CASE), "$1 JERK")
            .replace(Regex("""\bJRK\b""", RegexOption.IGNORE_CASE), "JERK")
            .replace(Regex("""\bG\.?T\.?O\.?H\.?\b""", RegexOption.IGNORE_CASE), "GTOH")
            .replace(Regex("""\bC\s*2\s*B\b""", RegexOption.IGNORE_CASE), "C2B")
            .replace(Regex("""\bB\s*M\s*U\b""", RegexOption.IGNORE_CASE), "BMU")
            .replace(Regex("""\bE\s*(\d+)\s*MOM\b""", RegexOption.IGNORE_CASE), "EVERY $1'")
            .replace(Regex("""\bFORTIME\b""", RegexOption.IGNORE_CASE), "FOR TIME")
            .replace(Regex("""\bFORTlME\b""", RegexOption.IGNORE_CASE), "FOR TIME")
            .replace(Regex("""(\d+)\s*CALS?(?:ORIES)?\b""", RegexOption.IGNORE_CASE), "$1 CAL")
            .replace(Regex("""(\d+)\s*M\s*(RUN|ROW|WALK|BIKE)?\b""", RegexOption.IGNORE_CASE), "$1M $2")
            .replace(Regex(""" {2,}"""), " ")
        return t
    }

    fun repair(
        ocrText: String,
        catalog: List<CatalogExercise>,
        previous: BoardScanLiteParser.Output,
        searchAliases: Map<String, String> = emptyMap()
    ): Output {
        val previousScore = BoardScanConfidence.assess(ocrText, previous)
        val cleaned = extraNormalize(ocrText)
        val reparsed = BoardScanLiteParser.parse(cleaned, catalog, searchAliases)
        val next = BoardScanConfidence.assess(cleaned, reparsed)
        return if (next.score > previousScore.score ||
            (next.score == previousScore.score && reparsed.blocks.size >= previous.blocks.size &&
                cleaned != ocrText)
        ) {
            Output(cleaned, reparsed, next, didRepair = cleaned != ocrText)
        } else {
            Output(ocrText, previous, previousScore, didRepair = false)
        }
    }
}
