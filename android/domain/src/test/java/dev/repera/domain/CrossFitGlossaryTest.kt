package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Port de los casos de CrossFitGlossary cubiertos por BoardImportParserTests /
 * BoardScanLiteParserTests (ReperaDomain, Swift), sobre la unidad parseMovementLine.
 */
class CrossFitGlossaryTest {

    @Test
    fun restLineBecomesRestMarker() {
        val r = CrossFitGlossary.parseMovementLine("1' REST")
        assertTrue(r.isRest)
        assertEquals(60, r.restSeconds)
        val r2 = CrossFitGlossary.parseMovementLine("REST 2'")
        assertTrue(r2.isRest)
        assertEquals(120, r2.restSeconds)
    }

    @Test
    fun descendingWaveBecomesRepScheme() {
        val r = CrossFitGlossary.parseMovementLine("3-3-2-2 SNATCH BALANCE @6-8")
        assertEquals(listOf(3, 3, 2, 2), r.repScheme)
        assertNull(r.reps)
        assertEquals("Balance de arrancada", r.name)
    }

    @Test
    fun ascendingRangeBecomesRangeNoteNotScheme() {
        assertTrue(CrossFitGlossary.isAscendingRepRange(listOf(10, 12)))
        val r = CrossFitGlossary.parseMovementLine("10-12 T2B")
        assertNull(r.repScheme)
        assertEquals(12, r.reps)
        assertEquals("Toes to bar", r.name)
        assertTrue(r.equipmentNote!!.contains("10-12"))
    }

    @Test
    fun sexSpecificCaloriesBecomeAirBike() {
        val r = CrossFitGlossary.parseMovementLine("20/16 CAL*")
        assertEquals("Air bike", r.name)
        assertEquals(20, r.calories)
        assertNull(r.weightMaleKg)
        assertTrue(r.equipmentNote!!.contains("16"))
    }

    @Test
    fun metersAreDistanceNotReps() {
        val r = CrossFitGlossary.parseMovementLine("100M RUN")
        assertEquals(100, r.distanceMeters)
        assertNull(r.reps)
        assertEquals("Carrera", r.name)
    }

    @Test
    fun maleFemaleWeightsAndLeadingReps() {
        val r = CrossFitGlossary.parseMovementLine("5 POWER CLEAN 50/35")
        assertEquals(5, r.reps)
        assertEquals(50.0, r.weightMaleKg!!, 0.001)
        assertEquals(35.0, r.weightFemaleKg!!, 0.001)
        assertEquals("Cargada de potencia", r.name)
    }

    @Test
    fun dumbbellEquipmentRedirectsSnatchVariant() {
        val r = CrossFitGlossary.parseMovementLine("8 DB SNATCH ALT")
        assertEquals(8, r.reps)
        assertEquals("Snatch mancuerna", r.name)
        assertTrue(r.equipmentNote!!.contains("Mancuerna"))
        assertTrue(r.equipmentNote!!.contains("Alternando"))
    }

    @Test
    fun kettlebellAbbrevExpandsWithWeights() {
        val r = CrossFitGlossary.parseMovementLine("15 AKBS 24/16")
        assertEquals(15, r.reps)
        assertEquals("Swing americano", r.name)
        assertEquals(24.0, r.weightMaleKg!!, 0.001)
        assertEquals(16.0, r.weightFemaleKg!!, 0.001)
    }

    @Test
    fun touchAndGoIsTechniqueNote() {
        val r = CrossFitGlossary.parseMovementLine("1 T&G SQUAT CLEAN")
        assertEquals(1, r.reps)
        assertEquals("Cargada", r.name)
        assertTrue(r.equipmentNote!!.contains("Touch & go"))
    }

    @Test
    fun normalizeFoldsDiacriticsAndPunctuation() {
        assertEquals("arrancada colgante", CrossFitGlossary.normalize("Arrancada_colgante"))
        assertEquals("dominadas estrictas", CrossFitGlossary.normalize("  Dominadas: Estrictas "))
    }
}
