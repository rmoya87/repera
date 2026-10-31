package dev.repera.domain
import org.junit.Test
import org.junit.Assert.*
class LiveSportSelectionTest {
    @Test fun legacyIdsStillDecodeAndAreSelectableAsFallback() {
        assertEquals(LiveSport.GRAVEL,LiveSport.byId("gravel"))
        assertEquals(LiveSport.OTHER,LiveSport.byId("other"))
        assertEquals(50, LiveSport.selectableCases.size)
        assertFalse(LiveSport.ELLIPTICAL.isSelectable)
        assertFalse(LiveSport.STAIR_CLIMBING.isSelectable)
        assertFalse(LiveSport.SOFTBALL.isSelectable)
        assertTrue(LiveSport.GRAVEL in LiveSport.selectableCases)
        assertTrue(LiveSport.OTHER in LiveSport.selectableCases)
        assertEquals("Ciclismo de carretera",LiveSport.CYCLING.title)
        assertEquals("Ciclismo de montaña",LiveSport.MOUNTAIN_BIKE.title)
        assertEquals("Entrenamiento",LiveSport.STRENGTH.title)
    }
    @Test fun selectableSportsAreAlphabeticWithinEverySection() {
        val collator=java.text.Collator.getInstance(java.util.Locale("es"))
        for(group in LiveSport.groups) {
            val list=LiveSport.selectableCases.filter {it.group==group}
            val withoutOther = list.filter { it != LiveSport.OTHER }
            assertTrue(withoutOther.zipWithNext().all {(a,b) -> collator.compare(a.title,b.title)<=0})
            if (list.any { it == LiveSport.OTHER }) {
                assertEquals(LiveSport.OTHER, list.last())
            }
        }
    }

    @Test fun racketAndTeamSymbolsMatchApple() {
        assertEquals("figure.indoor.soccer", LiveSport.SOCCER.symbol)
        assertEquals("figure.basketball", LiveSport.BASKETBALL.symbol)
        assertEquals("figure.volleyball", LiveSport.VOLLEYBALL.symbol)
        assertEquals("figure.tennis", LiveSport.TENNIS.symbol)
        assertEquals("figure.tennis", LiveSport.PADEL.symbol)
        assertEquals("figure.squash", LiveSport.SQUASH.symbol)
        assertEquals("figure.pickleball", LiveSport.PICKLEBALL.symbol)
        assertEquals("figure.badminton", LiveSport.BADMINTON.symbol)
        assertEquals("figure.strengthtraining.traditional", LiveSport.STRENGTH.symbol)
    }
}
