package dev.repera.mobile

import org.junit.Assert.*
import org.junit.Test

class FoldForSearchTest {
    @Test fun ignoresCaseAndDiacritics() {
        assertEquals("sentadilla bulgara", foldForSearch("  Sentadilla Búlgara "))
        assertTrue(foldForSearch("Peso muerto rumano").contains(foldForSearch("RUMANO")))
        assertTrue(foldForSearch("Extensión de tríceps").contains(foldForSearch("triceps")))
    }
}
