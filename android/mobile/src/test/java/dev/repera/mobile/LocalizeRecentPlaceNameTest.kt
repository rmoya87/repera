package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Test

class LocalizeRecentPlaceNameTest {
    @Test
    fun louvreFrenchToSpanish() {
        assertEquals("Museo del Louvre", localizeRecentPlaceName("Musée du Louvre"))
        assertEquals("Museo d'Orsay", localizeRecentPlaceName("Musée d'Orsay"))
        assertEquals("Box Norte", localizeRecentPlaceName("Box Norte"))
    }
}
