package dev.repera.domain

import kotlin.math.max
import kotlin.math.roundToInt

/** Guía orientativa derivada SOLO de GPX, no calles ni navegación vial.
 * Port updateUpcomingTurn de LiveActivityRecorder Apple 5890215d. */
class LiveRouteGuidance(private val points: List<WorkoutRoutePoint>, private val sport: LiveSport) {
    data class Cue(val display: String, val speech: String? = null,
        val instruction: String? = null, val distanceMeters: Int? = null,
        val offRoute: Boolean = false)
    private val along=LiveGPXTurnDetection.cumulative(points)
    private val turns=LiveGPXTurnDetection.detect(points,along)
    private val announcedNear=mutableSetOf<Int>()
    private val announcedApproach=mutableSetOf<Int>()
    fun update(position: WorkoutRoutePoint): Cue? {
        if(points.size<3) return null
        val step=max(1,points.size/1200)
        var best=0;var nearest=Double.POSITIVE_INFINITY
        for(index in points.indices step step) {
            val distance=LiveGPXTurnDetection.distance(position,points[index])
            if(distance<nearest) {nearest=distance;best=index}
        }
        if(nearest>=55) return Cue("Fuera de ruta · revisa el mapa",instruction="Fuera de ruta · revisa el mapa",offRoute=true)
        val distance=along[best]
        val next=turns.firstOrNull {it.routeIndex>best && it.metersAlongRoute>distance+8}
            ?: return Cue("Sigue el recorrido")
        val remaining=max(0.0,next.metersAlongRoute-distance)
        val approachDistance=if(sport.isCycling)450.0 else 250.0
        val nearDistance=if(sport.isCycling)120.0 else 70.0
        if(remaining>approachDistance) return Cue("Sigue el recorrido")
        val meters=(remaining/10).roundToInt()*10
        val display="${next.instruction} aprox. en $meters m"
        // El mensaje visual y el primer aviso de aproximación se sincronizan.
        // Un segundo aviso se reproduce al acercarse al giro. No repetir fixes
        // ni decir ambos a la vez si la ruta empieza cerca del giro.
        val shouldSpeakNear=remaining<=nearDistance && announcedNear.add(next.routeIndex)
        val shouldSpeakApproach=if(shouldSpeakNear) {
            announcedApproach.add(next.routeIndex)
            false
        } else remaining>nearDistance && announcedApproach.add(next.routeIndex)
        val speech=if(shouldSpeakNear || shouldSpeakApproach)
            LiveSpokenPhrases.turn(meters,next.spokenDirection) else null
        return Cue(display,speech,instruction=next.instruction,distanceMeters=meters)
    }
}
