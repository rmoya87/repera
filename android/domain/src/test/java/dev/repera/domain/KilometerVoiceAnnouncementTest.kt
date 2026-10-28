package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class KilometerVoiceAnnouncementTest {
    @Test
    fun firstKilometerIncludesSegmentOnly() {
        val spoken = KilometerVoiceAnnouncement.message(1, 320.0, 320.0)
        assertEquals(
            "Kilómetro 1 completado. Tiempo del tramo: 5 minutos y 20 segundos. " +
                "Velocidad media del tramo: 11,3 kilómetros por hora.",
            spoken
        )
    }

    @Test
    fun laterKilometerAddsOverallAverage() {
        val spoken = KilometerVoiceAnnouncement.message(2, 300.0, 620.0)
        assertEquals(
            "Kilómetro 2 completado. Tiempo del tramo: 5 minutos. " +
                "Velocidad media del tramo: 12,0 kilómetros por hora. " +
                "Velocidad media desde el inicio: 11,6 kilómetros por hora.",
            spoken
        )
    }

    @Test
    fun rejectsInvalidSplits() {
        assertNull(KilometerVoiceAnnouncement.message(0, 60.0, 60.0))
        assertNull(KilometerVoiceAnnouncement.message(1, 0.0, 60.0))
        assertNull(KilometerVoiceAnnouncement.message(1, 60.0, 30.0))
        assertNull(KilometerVoiceAnnouncement.message(1, Double.NaN, 60.0))
    }
}
