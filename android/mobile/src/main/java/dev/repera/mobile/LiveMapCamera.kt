package dev.repera.mobile

import dev.repera.domain.WorkoutRoutePoint
import kotlin.math.*

/** Heading from measured geometry only. No heading or current position invented. */
internal object LiveMapCamera {
    const val FOLLOW_RESUME_DELAY_MS = 5_000L

    /** Reanudar únicamente después de cinco segundos SIN nuevas interacciones. */
    fun shouldResumeFollowing(
        following: Boolean,
        lastUserMoveMs: Long,
        nowMs: Long
    ): Boolean = !following && lastUserMoveMs > 0 &&
        nowMs >= lastUserMoveMs &&
        nowMs - lastUserMoveMs >= FOLLOW_RESUME_DELAY_MS

    data class Target(val latitude:Double,val longitude:Double,val bearing:Double,val pitch:Double,val zoom:Double)
    /** Solo cuando hay desplazamiento medido; nunca inferir rumbo de puntos casi inmóviles. */
    fun measuredHeading(trace: List<WorkoutRoutePoint>): Double? {
        if (trace.size < 2) return null
        val b=trace.last();val a=trace[trace.lastIndex-1]
        val seconds=(b.recordedAtEpochMs-a.recordedAtEpochMs)/1000.0
        if (seconds <= 0 || seconds > 30) return null
        val lat=Math.toRadians(b.latitude-a.latitude)
        val lon=Math.toRadians(b.longitude-a.longitude)
        val x=lon*cos(Math.toRadians(b.latitude))
        val y=lat
        val distance=6371000.0*hypot(x,y)
        if (distance < 6 || distance/seconds < 0.8) return null
        return (Math.toDegrees(atan2(x,y))+360)%360
    }

    /** 2D y 3D comparten el mismo rumbo medido; la vista 2D no fuerza norte.
     *  Un rumbo fiable anterior puede conservarse al detenerse o pausar. */
    fun target(
        center:WorkoutRoutePoint,
        trace:List<WorkoutRoutePoint>,
        navigation:Boolean,
        lastReliableHeading:Double? = null
    ):Target {
        val heading = measuredHeading(trace)
            ?: lastReliableHeading?.takeIf { it.isFinite() && it >= 0.0 && it < 360.0 }
            ?: 0.0
        if(!navigation) return Target(center.latitude,center.longitude,heading,0.0,16.5)
        val ahead=if(trace.isEmpty()) 0.0 else 35.0
        val r=Math.toRadians(heading)
        return Target((center.latitude+cos(r)*ahead/111_320).coerceIn(-85.0,85.0),
            (center.longitude+sin(r)*ahead/(111_320*max(0.1,abs(cos(Math.toRadians(center.latitude)))))).coerceIn(-180.0,180.0),
            heading,60.0,17.0)
    }
}
