package dev.repera.mobile

import dev.repera.domain.WorkoutRoutePoint
import kotlin.math.*

/** Heading from measured geometry only. No heading or current position invented. */
internal object LiveMapCamera {
    data class Target(val latitude:Double,val longitude:Double,val bearing:Double,val pitch:Double,val zoom:Double)
    fun target(center:WorkoutRoutePoint,trace:List<WorkoutRoutePoint>,navigation:Boolean):Target {
        if(!navigation) return Target(center.latitude,center.longitude,0.0,0.0,16.5)
        val pair=trace.takeLast(2)
        val heading=if(pair.size<2) 0.0 else {
            val a=pair[0];val b=pair[1]
            val d=Math.toRadians(b.longitude-a.longitude)
            val x=sin(d)*cos(Math.toRadians(b.latitude))
            val y=cos(Math.toRadians(a.latitude))*sin(Math.toRadians(b.latitude))-
                sin(Math.toRadians(a.latitude))*cos(Math.toRadians(b.latitude))*cos(d)
            (Math.toDegrees(atan2(x,y))+360)%360
        }
        val ahead=if(trace.isEmpty()) 0.0 else 35.0
        val r=Math.toRadians(heading)
        return Target((center.latitude+cos(r)*ahead/111_320).coerceIn(-85.0,85.0),
            (center.longitude+sin(r)*ahead/(111_320*max(0.1,abs(cos(Math.toRadians(center.latitude)))))).coerceIn(-180.0,180.0),
            heading,60.0,17.0)
    }
}
