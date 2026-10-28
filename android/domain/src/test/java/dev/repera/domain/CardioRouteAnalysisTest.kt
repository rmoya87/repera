package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CardioRouteAnalysisTest {

    private fun pt(t: Double, lat: Double, lon: Double, alt: Double? = null) =
        CardioRouteAnalysis.Sample(t, lat, lon, alt)

    @Test
    fun `distancia se acumula con haversine y el perfil usa altitudes validas`() {
        // ~111 m por cada 0.001° de latitud.
        val route = (0..10).map { pt(it * 10.0, 40.0 + it * 0.001, -3.7, 100.0 + it * 4) }
        val r = CardioRouteAnalysis.analyze(route)
        assertEquals(1112.0, r.distanceMeters, 20.0)
        assertTrue(r.ascentMeters >= 36.0)   // 10 subidas de 4 m (alguna puede quedar fuera por pendiente)
        assertTrue(r.descentMeters < 1.0)
        assertEquals(11, r.profile.size)
        assertEquals(0.0, r.profile.first().distanceKm, 1e-9)
    }

    @Test
    fun `puntos invalidos y saltos imposibles se descartan`() {
        val route = listOf(
            pt(0.0, 40.0, -3.7),
            pt(10.0, 91.0, -3.7),              // latitud inválida
            pt(10.0, 40.001, -3.7),            // dt = 0 → duplicado
            pt(12.0, 41.0, -3.7),              // ~111 km en 2 s → imposible
            pt(22.0, 40.001, -3.7)             // vuelve: ~111 m en 20 s → válido
        )
        val r = CardioRouteAnalysis.analyze(route)
        assertEquals(111.0, r.distanceMeters, 15.0)
    }

    @Test
    fun `splits por kilometro con bpm medio solo con dos muestras`() {
        // ~1 km recto en 300 s ≈ 12 km/h.
        val route = (0..30).map { pt(it * 10.0, 40.0 + it * 0.0003, -3.7) }
        val heart = listOf(
            CardioRouteAnalysis.HeartSample(10.0, 130.0),
            CardioRouteAnalysis.HeartSample(150.0, 150.0),
            CardioRouteAnalysis.HeartSample(280.0, 170.0)
        )
        val r = CardioRouteAnalysis.analyze(route, heart)
        assertTrue(r.splits.isNotEmpty())
        val s = r.splits.first()
        assertEquals(1, s.kilometer)
        assertEquals(s.seconds, s.paceSecondsPerKm, 1e-9)
        assertEquals(3600 / s.seconds, s.speedKmh, 1e-6)
        assertEquals(150.0, s.averageBpm ?: 0.0, 0.1)
        // bpm fuera de 30-240 se filtran
        val r2 = CardioRouteAnalysis.analyze(route, listOf(
            CardioRouteAnalysis.HeartSample(10.0, 10.0),
            CardioRouteAnalysis.HeartSample(150.0, 300.0)
        ))
        assertTrue(r2.splits.first().averageBpm == null)
    }

    @Test
    fun `oscilaciones de altitud pequenas no cuentan como desnivel`() {
        // Subida gradual de 2 m por punto (cada punto cuenta al acumular con
        // referencia estable) pero zig-zag de ±1 m no.
        val zigzag = (0..20).map { pt(it * 10.0, 40.0 + it * 0.0001, -3.7,
            100.0 + (if (it % 2 == 0) 0.0 else 1.0)) }
        val rz = CardioRouteAnalysis.analyze(zigzag)
        assertTrue(rz.ascentMeters < 3.0)
        assertTrue(rz.descentMeters < 3.0)
    }

    @Test
    fun `altura fuera de rango no entra en el perfil`() {
        val route = listOf(
            pt(0.0, 40.0, -3.7, 100.0),
            pt(10.0, 40.001, -3.7, 10000.0),   // fuera de -500..9000
            pt(20.0, 40.002, -3.7, 106.0)
        )
        val r = CardioRouteAnalysis.analyze(route)
        assertTrue(r.profile.all { it.altitudeMeters in -500.0..9000.0 })
    }
}
