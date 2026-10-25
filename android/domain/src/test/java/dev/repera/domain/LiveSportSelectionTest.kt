package dev.repera.domain
import org.junit.Test
import org.junit.Assert.*
class LiveSportSelectionTest {
    @Test fun legacyIdsStillDecodeButAreNotSelectable() {
        assertEquals(LiveSport.GRAVEL,LiveSport.byId("gravel"))
        assertEquals(LiveSport.OTHER,LiveSport.byId("other"))
        assertEquals(34,LiveSport.selectableCases.size)
        assertFalse(LiveSport.GRAVEL in LiveSport.selectableCases)
        assertFalse(LiveSport.OTHER in LiveSport.selectableCases)
        assertEquals("Ciclismo de carretera",LiveSport.CYCLING.title)
        assertEquals("Ciclismo de montaña",LiveSport.MOUNTAIN_BIKE.title)
        assertEquals("Entrenamiento",LiveSport.STRENGTH.title)
    }
    @Test fun selectableSportsAreAlphabeticWithinEverySection() {
        val collator=java.text.Collator.getInstance(java.util.Locale("es"))
        for(group in LiveSport.groups) {
            val list=LiveSport.selectableCases.filter {it.group==group}
            assertTrue(list.zipWithNext().all {(a,b) -> collator.compare(a.title,b.title)<=0})
        }
    }
}
