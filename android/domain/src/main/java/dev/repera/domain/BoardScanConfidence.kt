package dev.repera.domain

import java.util.Locale

/** Score 0…1 de fiabilidad del parseo local de pizarra (paridad iOS). */
object BoardScanConfidence {
    data class Assessment(
        val score: Double,
        val reasons: List<String>
    ) {
        companion object {
            const val REPAIR_THRESHOLD = 0.85
        }
    }

    fun assess(ocrText: String, output: BoardScanLiteParser.Output): Assessment {
        var score = 1.0
        val reasons = mutableSetOf<String>()

        val ocrLines = ocrText.lines().map { it.trim() }.filter { it.isNotEmpty() }
        val blocks = output.blocks

        if (blocks.isEmpty()) {
            return Assessment((score - 0.55).coerceIn(0.0, 1.0), listOf("no_blocks"))
        }

        if (blocks.size == 1) {
            val title = blocks[0].title.uppercase(Locale.ROOT)
            if (title.contains("AÑADIR ENTRENO") || title == "CHIPPER" ||
                blocks[0].wodFormat == WODFormat.CHIPPER
            ) {
                if (ocrLines.size >= 4) {
                    score -= 0.28
                    reasons += "catch_all_block"
                }
            }
        }

        if (ocrLines.size >= 8 && blocks.size == 1) {
            score -= 0.18
            reasons += "few_blocks_vs_lines"
        }

        val movements = blocks.flatMap { block ->
            if (block.kind == RoutineBlockKind.STRENGTH) emptyList()
            else block.movements.filter { !it.isRest }
        }
        val strengthCount = blocks.filter { it.kind == RoutineBlockKind.STRENGTH }
            .sumOf { it.exercises.size }
        val workCount = movements.size + strengthCount

        if (workCount == 0 && ocrLines.isNotEmpty()) {
            score -= 0.35
            reasons += "no_movements"
        }

        if (movements.isNotEmpty()) {
            val unmatched = movements.count { it.exerciseId == null }
            val ratio = unmatched.toDouble() / movements.size
            when {
                ratio >= 0.5 -> {
                    score -= 0.30
                    reasons += "catalog_match_low"
                }
                ratio >= 0.25 -> {
                    score -= 0.15
                    reasons += "catalog_match_mid"
                }
            }
            val untyped = movements.count {
                it.reps == null && it.repScheme == null &&
                    it.distanceMeters == null && it.calories == null
            }
            if (untyped.toDouble() / movements.size >= 0.4) {
                score -= 0.12
                reasons += "untyped_movements"
            }
        }

        for (block in blocks) {
            val header = (block.wodNotes ?: block.title).uppercase(Locale.ROOT)
            if ((header.contains("EVERY") || header.contains("CADA ")) &&
                block.kind != RoutineBlockKind.STRENGTH &&
                block.wodFormat == WODFormat.EMOM &&
                block.movements.size == 1
            ) {
                score -= 0.08
                reasons += "ambiguous_every"
                break
            }
        }

        val joined = ocrText.uppercase(Locale.ROOT)
        if (Regex("""\dRF[TF]\b""").containsMatchIn(joined) ||
            Regex("""\dBOB\b""").containsMatchIn(joined)
        ) {
            score -= 0.10
            reasons += "ocr_noise"
        }

        return Assessment(score.coerceIn(0.0, 1.0), reasons.sorted())
    }
}
