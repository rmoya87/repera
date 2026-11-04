package dev.repera.domain

/**
 * Paso local compartido: lite → score → repair si score < 0.85.
 * Sin Foundation Models (excepción Apple documentada).
 */
object BoardScanLocalPipeline {
    data class Result(
        val ocrText: String,
        val blocks: List<RoutineBlock>,
        val lines: List<BoardImportLine>,
        val confidence: BoardScanConfidence.Assessment,
        val didRepair: Boolean
    )

    fun interpret(
        ocrText: String,
        catalog: List<CatalogExercise> = emptyList(),
        searchAliases: Map<String, String> = emptyMap()
    ): Result {
        val normalized = BoardScanLocalRepair.extraNormalize(ocrText)
        val lite = BoardScanLiteParser.parse(normalized, catalog, searchAliases)
        var assessment = BoardScanConfidence.assess(normalized, lite)
        var text = normalized
        var parsed = lite
        var didRepair = normalized != ocrText

        if (assessment.score < BoardScanConfidence.Assessment.REPAIR_THRESHOLD) {
            val repaired = BoardScanLocalRepair.repair(normalized, catalog, lite, searchAliases)
            text = repaired.ocrText
            parsed = repaired.parsed
            assessment = repaired.assessment
            didRepair = didRepair || repaired.didRepair
        }

        return Result(
            ocrText = text,
            blocks = parsed.blocks,
            lines = parsed.lines,
            confidence = assessment,
            didRepair = didRepair
        )
    }
}
