package dev.repera.mobile

import dev.repera.domain.LiveSport
import org.junit.Assert.assertEquals
import org.junit.Test

class LiveActivityLocationNameTest {
    @Test fun walkingUsesCityWithoutStreet() {
        assertEquals("Caminata por Las Rozas",
            LiveActivityLocationName.format(LiveSport.WALKING,"Las Rozas"))
    }
    @Test fun longRouteShowsBothCities() {
        assertEquals("Carrera de Madrid a Alcobendas",
            LiveActivityLocationName.format(LiveSport.RUNNING,"Madrid","Alcobendas"))
    }
    @Test fun indoorSportsUseSimplePlaceName() {
        assertEquals("Pádel en Pozuelo",
            LiveActivityLocationName.format(LiveSport.PADEL,"Pozuelo"))
    }
    @Test fun missingLocationUsesDefault() {
        assertEquals("Tenis",
            LiveActivityLocationName.format(LiveSport.TENNIS,""))
    }
}
