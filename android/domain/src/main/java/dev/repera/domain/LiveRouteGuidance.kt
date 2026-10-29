package dev.repera.domain

import kotlin.math.max
import kotlin.math.roundToInt

/** Guía orientativa derivada SOLO de GPX, no calles ni navegación vial.
 * Port updateUpcomingTurn de LiveActivityRecorder Apple 5890215d.
 * Paridad 29/10: el letrero se mantiene hasta 12 m DESPUES de rebasar el giro
 * (antes se ocultaba en los ultimos 8 m) y announce=false permite la vista
 * previa en preparacion sin consumir avisos hablados, como iOS en idle. */
class LiveRouteGuidance(private val points: List<WorkoutRoutePoint>, private val sport: LiveSport) {
    data class Cue(val display: String, val speech: String? = null,
        val instruction: String? = null, val distanceMeters: Int? = null,
        val offRoute: Boolean = false)
    private val along=LiveGPXTurnDetection.cumulative(points)
    private val turns=LiveGPXTurnDetection.detect(points,along)
    private val announcedNear=mutableSetOf<Int>()
    private val announcedApproach=mutableSetOf<Int>()
    fun update(position: WorkoutRoutePoint, announce: Boolean = true): Cue? {
        if(points.size<3) return null
        val step=max(1,points.size/1200)
        var best=0;var nearest=Double.POSITIVE_INFINITY
        for(index in points.indices step step) {
            val distance=LiveGPXTurnDetection.distance(position,points[index])
            if(distance<nearest) {nearest=distance;best=index}
        }
        if(nearest>=55) return Cue("Fuera de ruta · revisa el mapa",instruction="Fuera de ruta · revisa el mapa",offRoute=true)
        val distance=along[best]
        // Apple: mantener el letrero hasta rebasar el giro (12 m de holgura);
        // antes se ocultaba en los ultimos 8 m, justo cuando mas se necesitaba.
        val next=turns.firstOrNull {it.metersAlongRoute>=distance-12}
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
        val shouldSpeakNear=announce && remaining<=nearDistance && announcedNear.add(next.routeIndex)
        val shouldSpeakApproach=if(shouldSpeakNear) {
            announcedApproach.add(next.routeIndex)
            false
        } else announce && remaining>nearDistance && announcedApproach.add(next.routeIndex)
        val speech=if(shouldSpeakNear || shouldSpeakApproach)
            LiveSpokenPhrases.turn(meters,next.spokenDirection) else null
        return Cue(display,speech,instruction=next.instruction,distanceMeters=meters)
    }
}
