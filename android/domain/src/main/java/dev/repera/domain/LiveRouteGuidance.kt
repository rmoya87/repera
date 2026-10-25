package dev.repera.domain

import kotlin.math.max
import kotlin.math.roundToInt

/** Guía orientativa derivada SOLO de GPX, no calles ni navegación vial.
 * Port updateUpcomingTurn de LiveActivityRecorder Apple 5890215d. */
class LiveRouteGuidance(private val points: List<WorkoutRoutePoint>, private val sport: LiveSport) {
    data class Cue(val display: String, val speech: String? = null)
    private val along=LiveGPXTurnDetection.cumulative(points)
    private val turns=LiveGPXTurnDetection.detect(points,along)
    private val announced=mutableSetOf<Int>()
    fun update(position: WorkoutRoutePoint): Cue? {
        if(points.size<3) return null
        val step=max(1,points.size/1200)
        var best=0;var nearest=Double.POSITIVE_INFINITY
        for(index in points.indices step step) {
            val distance=LiveGPXTurnDetection.distance(position,points[index])
            if(distance<nearest) {nearest=distance;best=index}
        }
        if(nearest>=55) return Cue("Fuera de ruta · revisa el mapa")
        val distance=along[best]
        val next=turns.firstOrNull {it.routeIndex>best && it.metersAlongRoute>distance+8}
            ?: return Cue("Sigue el recorrido")
        val remaining=max(0.0,next.metersAlongRoute-distance)
        if(remaining>250) return Cue("Sigue el recorrido")
        val meters=(remaining/10).roundToInt()*10
        val display="${next.instruction} aprox. en $meters m"
        val speech=if(remaining<=(if(sport.isCycling)120 else 70) && announced.add(next.routeIndex))
            "Dentro de $meters metros, ${next.instruction.lowercase()}." else null
        return Cue(display,speech)
    }
}
