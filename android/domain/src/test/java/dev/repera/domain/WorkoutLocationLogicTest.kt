package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WorkoutLocationLogicTest {

    private fun point(i: Int) = WorkoutRoutePoint(
        id = i, latitude = 40.0 + i * 0.0001, longitude = -3.7, recordedAtEpochMs = 1_000L * i)

    @Test
    fun `heuristica detecta outdoor por titulo con tildes`() {
        assertTrue(WorkoutLocationLogic.shouldTrackRoute("Carrera suave", emptyList()))
        assertTrue(WorkoutLocationLogic.shouldTrackRoute("Sábado de ciclismo", emptyList()))
        assertTrue(WorkoutLocationLogic.shouldTrackRoute("Fuerza", listOf("Caminata inclinada")))
    }

    @Test
    fun `heuristica rechaza sesiones de gym`() {
        assertFalse(WorkoutLocationLogic.shouldTrackRoute("Torso pesado", listOf("Press banca", "Dominadas")))
        assertFalse(WorkoutLocationLogic.shouldTrackRoute("Pierna", listOf("Sentadilla")))
    }

    @Test
    fun `heuristica ignora diacriticos y mayusculas`() {
        assertTrue(WorkoutLocationLogic.shouldTrackRoute("RUNNING", emptyList()))
        assertTrue(WorkoutLocationLogic.shouldTrackRoute("Bicicleta", emptyList())) // "bici" dentro de "bicicleta"
        assertTrue(WorkoutLocationLogic.shouldTrackRoute("Ski de fondo", emptyList()))
    }

    @Test
    fun `downsample no toca rutas cortas`() {
        val puntos = (0 until 10).map(::point)
        assertEquals(puntos, WorkoutLocationLogic.downsample(puntos, 400))
    }

    @Test
    fun `downsample conserva extremos y renumera`() {
        val puntos = (0 until 1000).map(::point)
        val out = WorkoutLocationLogic.downsample(puntos, 400)
        assertEquals(400, out.size)
        assertEquals(puntos.first().latitude, out.first().latitude, 1e-9)
        assertEquals(puntos.last().latitude, out.last().latitude, 1e-9)
        assertEquals(0, out.first().id)
        assertEquals(399, out.last().id)
        // Muestreo equiespaciado: mismo salto entre índices originales.
        assertTrue(out.zipWithNext().all { (a, b) -> b.latitude > a.latitude })
    }
}
