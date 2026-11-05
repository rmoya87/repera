package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class FallbackActivityKindTest {
    @Test fun blankOrGymTitlesResolveToStrength() {
        assertEquals(FallbackActivityKind.STRENGTH, FallbackActivityKind.resolving("Clase de las 18:00"))
        assertEquals(FallbackActivityKind.STRENGTH, FallbackActivityKind.resolving("Gimnasio"))
        assertEquals(FallbackActivityKind.STRENGTH, FallbackActivityKind.resolving(""))
        assertEquals("strength", FallbackActivityKind.resolving("").liveSportId)
    }

    @Test fun intervalTitlesResolveToHiit() {
        assertEquals(FallbackActivityKind.HIIT, FallbackActivityKind.resolving("HIIT 30'"))
        assertEquals(FallbackActivityKind.HIIT, FallbackActivityKind.resolving("Tabata express"))
        assertEquals(FallbackActivityKind.HIIT, FallbackActivityKind.resolving("WOD del día"))
        assertEquals(FallbackActivityKind.HIIT, FallbackActivityKind.resolving("CrossFit Open"))
        assertEquals(FallbackActivityKind.HIIT, FallbackActivityKind.resolving("Circuito funcional"))
        assertEquals(FallbackActivityKind.HIIT, FallbackActivityKind.resolving("Metcon AMRAP"))
    }
}
