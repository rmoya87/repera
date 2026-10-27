package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class LiveSpokenPhrasesTest {
    @Test fun paceWordingSingularPluralAndExactMinutes() {
        assertEquals("Kilómetro 3 completado. Tu tiempo ha sido de 5 minutos y 20 segundos.", LiveSpokenPhrases.kilometer(3, 320.0, false))
        assertEquals("Kilómetro 1 completado. Tu tiempo ha sido de 1 minuto.", LiveSpokenPhrases.kilometer(1, 60.0, false))
        assertEquals("Kilómetro 2 completado. Tu tiempo ha sido de 2 minutos.", LiveSpokenPhrases.kilometer(2, 120.0, false))
        assertEquals("Kilómetro 2 completado. Tu tiempo ha sido de 1 segundo.", LiveSpokenPhrases.kilometer(2, 0.2, false))
        assertEquals("Kilómetro 4 completado. Tu tiempo ha sido de 1 minuto y 5 segundos.", LiveSpokenPhrases.kilometer(4, 65.0, false))
    }
    @Test fun speedWordingUsesCommaDecimal() {
        assertEquals("Kilómetro 5 completado. Has ido a 25,7 kilómetros por hora, de media.", LiveSpokenPhrases.kilometer(5, 140.0, true))
    }
    @Test fun turnPhrasesFollowApple() {
        assertEquals("Ahora, gira a la derecha.", LiveSpokenPhrases.turn(20, "gira a la derecha"))
        assertEquals("Ahora, gira a la izquierda.", LiveSpokenPhrases.turn(10, "gira a la izquierda"))
        assertEquals("En unos 30 metros, cambia de sentido.", LiveSpokenPhrases.turn(30, "cambia de sentido"))
        assertEquals("cambia de sentido", LiveGPXTurnDetection.Turn(1, 10.0, 150.0).spokenDirection)
        assertEquals("cambia de sentido", LiveGPXTurnDetection.Turn(1, 10.0, -150.0).spokenDirection)
        assertEquals("gira a la derecha", LiveGPXTurnDetection.Turn(1, 10.0, 90.0).spokenDirection)
        assertEquals("gira a la izquierda", LiveGPXTurnDetection.Turn(1, 10.0, -90.0).spokenDirection)
    }
    @Test fun waterSportsMatchAppleList() {
        val water = LiveSport.entries.filter { it.isWaterSport }.map { it.id }.toSet()
        assertEquals(setOf("surfing", "swimming", "windsurfing", "kitesurfing", "kayaking", "rowing", "canoeing", "sailing"), water)
    }
}
