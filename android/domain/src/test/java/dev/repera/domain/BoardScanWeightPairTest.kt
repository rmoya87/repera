package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Apple 3432a1a9 (BoardScanLiteParser.weightPair): «100 / 70 KG» y «24 / 16»
 *  son cargas H/M, no alternativas de escala. */
class BoardScanWeightPairTest {

    private fun moves(text: String) =
        BoardScanLiteParser.parse(ocrText = text).blocks
            .flatMap { it.movements }

    @Test fun slashSeparatedKgPairIsLoadNotScale() {
        val m = moves("20m SLED PUSH 100 / 70 KG").single()
        assertNull(m.scaleAlternative)
        assertEquals("SLED PUSH", m.name)
        assertEquals(20, m.distanceMeters)
        assertEquals(100.0, m.weightMaleKg!!, 1e-9)
    }

    @Test fun bareNumberPairIsLoadNotScale() {
        val m = moves("FARMER CARRY 24 / 16").single()
        assertNull(m.scaleAlternative)
        assertEquals(24.0, m.weightMaleKg!!, 1e-9)
    }

    @Test fun realScaleAlternativesStillSplit() {
        // «3 BMU / 6 C2B» sigue siendo alternativa de escala (sin kg/cal).
        val m = moves("3 BMU / 6 C2B").single()
        assertNotNull(m.scaleAlternative)
    }
}
