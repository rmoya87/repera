package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RecentPlacesTest {
    private fun pin(lat: Double, lon: Double, name: String? = null, id: String? = null) =
        WorkoutLocationPin(lat, lon, 0L, name = name, mapItemIdentifier = id)

    @Test fun `inserta al frente`() {
        val r = RecentPlaces.remember(listOf(pin(40.0, -3.0, "A")), pin(41.0, -3.0, "B"))
        assertEquals("B", r[0].name); assertEquals(2, r.size)
    }

    @Test fun `deduplica por mapItemIdentifier aunque cambien coordenadas`() {
        val r = RecentPlaces.remember(listOf(pin(40.0, -3.0, "A", "x1")), pin(41.5, -3.5, "A2", "x1"))
        assertEquals(1, r.size); assertEquals("A2", r[0].name)
    }

    @Test fun `deduplica por proximidad de coordenadas sin identificador`() {
        val r = RecentPlaces.remember(
            listOf(pin(40.00001, -3.00001, "A")), pin(40.00002, -3.00002, "B"))
        assertEquals(1, r.size); assertEquals("B", r[0].name)
    }

    @Test fun `coordenadas lejanas con identificadores distintos conviven`() {
        val r = RecentPlaces.remember(listOf(pin(40.0, -3.0, "A", "a")), pin(41.0, -3.1, "B", "b"))
        assertEquals(2, r.size)
    }

    @Test fun `un identificador solo en un lado no impide dedupe por coordenadas`() {
        // iOS: si AMBOS tienen id y difieren, no son el mismo por id; si no,
        // decide la proximidad. Aquí solo uno tiene id: aplica coordenadas.
        val r = RecentPlaces.remember(listOf(pin(40.0, -3.0, "A", "a")), pin(40.0, -3.0, "B", null))
        assertEquals(1, r.size); assertEquals("B", r[0].name)
    }

    @Test fun `recorta al limite de 5 conservando los mas recientes`() {
        var r = listOf<WorkoutLocationPin>()
        for (i in 1..7) r = RecentPlaces.remember(r, pin(40.0 + i, -3.0, "P$i"))
        assertEquals(5, r.size)
        assertEquals("P7", r[0].name); assertEquals("P3", r[4].name)
    }
}
