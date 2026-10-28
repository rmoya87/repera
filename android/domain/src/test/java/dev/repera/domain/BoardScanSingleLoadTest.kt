package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Apple 3432a1a9 (CrossFitGlossary): carga unica explicita en lineas de
 *  pizarra — «2x24kg», «16 kg», «100kg», lbs — sin romper el nombre. */
class BoardScanSingleLoadTest {

    private fun moves(text: String) =
        BoardScanLiteParser.parse(ocrText = text).blocks
            .flatMap { it.movements }

    @Test fun walkingLungesWithSingleKg() {
        val m = moves("14m WALKING LUNGES 16kg").single()
        assertEquals(14, m.distanceMeters)
        assertEquals(16.0, m.weightMaleKg!!, 1e-9)
        assertFalse(m.name.contains("16"))
        assertNull(m.scaleAlternative)
    }

    @Test fun implementCountIsNotReps() {
        // «2x24kg»: 2 implementos de 24 kg -> carga 24, NUNCA reps=2 ni 2 kg.
        val m = moves("20m FARMER CARRY 2x24kg").single()
        assertEquals(20, m.distanceMeters)
        assertEquals(24.0, m.weightMaleKg!!, 1e-9)
        assertNull(m.reps)
    }

    @Test fun bareKgAndPounds() {
        val sled = moves("Sled push 100kg").single()
        assertEquals(100.0, sled.weightMaleKg!!, 1e-9)
        assertFalse(sled.name.contains("100"))
        val lbs = moves("Sled push 225 lbs").single()
        assertEquals(102.1, lbs.weightMaleKg!!, 0.05)
    }

    @Test fun pairStillWinsOverSingleLoad() {
        // Los pares H/M se consumen antes: «24/16 kg» no cae en la carga unica.
        val m = moves("FARMER CARRY 24 / 16 kg").single()
        assertEquals(24.0, m.weightMaleKg!!, 1e-9)
        assertEquals(16.0, m.weightFemaleKg!!, 1e-9)
    }

    @Test fun fullScannerKeepsDistanceAndSingleLoad() {
        // Equivalente Android de testFullBoardParserAlsoKeepsDistanceAndSingleLoad
        // (Apple 4c9a5d10): BoardScanLiteParser es la superficie de escaneo
        // Android; el BoardImportParser completo sigue ausente (gap 88db5bb7).
        val ms = moves("""AMRAP 10'
            |20 m SLED PUSH 100kg
            |15 m FARMER CARRY 2x24kg""".trimMargin())
        assertEquals(2, ms.size)
        assertEquals(20, ms[0].distanceMeters)
        assertEquals(100.0, ms[0].weightMaleKg!!, 1e-9)
        assertEquals(15, ms[1].distanceMeters)
        assertEquals(24.0, ms[1].weightMaleKg!!, 1e-9)
    }

    @Test fun movementSummaryShowsKgSuffix() {
        // Apple 4c9a5d10 WODMovement.summaryLine: carga con sufijo kg siempre.
        val pair = WODMovement(name = "FARMER CARRY", distanceMeters = 20,
            weightMaleKg = 24.0, weightFemaleKg = 16.0)
        assertTrue(pair.summaryLine.contains("24/16 kg"))
        val single = WODMovement(name = "SLED PUSH", distanceMeters = 15,
            weightMaleKg = 100.0)
        assertTrue(single.summaryLine.contains("100 kg"))
        assertFalse(single.summaryLine.contains("/"))
    }
}
