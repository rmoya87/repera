package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Espejo de Apple (live main, ff94e6ad) WODHistoryPresentationTests. */
class WODHistoryPresentationTest {

    @Test
    fun officialNameResolvesBttAndT2bVariants() {
        assertEquals("Burpee to target", WODHistoryPresentation.officialName("BTт"))
        assertEquals("Toes to bar", WODHistoryPresentation.officialName("Ｔ２Ｂ"))
        assertNull(WODHistoryPresentation.officialName("Wall ball"))
        for (raw in listOf(
            "btt", "BTT", "BTt", "B T t", "ＢＴＴ", "𝐁𝐓𝐭",
            "ВΤt", "ΒТτ", "B​Tt", "Ᏼᴛᴛ"
        )) {
            assertEquals(
                "Fallo al resolver el alias $raw",
                "Burpee to target", WODHistoryPresentation.officialName(raw)
            )
            assertEquals(
                "Fallo en canonicalName de $raw",
                "Burpee to target", CrossFitGlossary.canonicalName(raw)
            )
        }
    }

    @Test
    fun officialNameLeavesSimilarNamesAlone() {
        // Solo abreviaturas inequívocas; nunca nombres parecidos.
        assertNull(WODHistoryPresentation.officialName("Burpee broad jump"))
        assertNull(WODHistoryPresentation.officialName("Toes to bar kipping"))
    }
}
