package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class LiveRouteGuidanceTest {
    private fun p(lat: Double,lon: Double)=WorkoutRoutePoint(0,lat,lon,0)
    private val route=listOf(p(40.0,-3.0),p(40.0004,-3.0),p(40.0008,-3.0),p(40.0012,-3.0),p(40.0012,-2.999))
    @Test fun warnsOnceNearTurnAndNeverFabricatesStreetNames() {
        val guide=LiveRouteGuidance(route,LiveSport.RUNNING)
        val cue=guide.update(route[2])!!
        assertTrue(cue.display.contains("derecha"));assertNotNull(cue.speech)
        assertNull(guide.update(route[2])!!.speech)
    }
    @Test fun offRouteProducesVisualWarningNotFalseTurnAndFinishedRouteContinues() {
        val guide=LiveRouteGuidance(route,LiveSport.RUNNING)
        val far=guide.update(p(41.0,-3.0))!!
        assertEquals("Fuera de ruta · revisa el mapa",far.display);assertNull(far.speech)
        assertEquals("Sigue el recorrido",guide.update(route.last())!!.display)
        assertNull(LiveRouteGuidance(route.take(2),LiveSport.RUNNING).update(route.first()))
    }
}
