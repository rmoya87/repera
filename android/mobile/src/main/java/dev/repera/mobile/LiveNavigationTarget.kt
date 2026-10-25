package dev.repera.mobile

/** Exact Apple5890215d contract: live opens recorder, workout opens current
 * session or home. No UUID lookup and no fabricated finished-workout target. */
internal object LiveNavigationTarget {
    fun route(host:String?):String? = when(host) {
        "live" -> "en-vivo"
        "workout" -> "entreno-activo"
        else -> null
    }
    fun resolvedRoute(route:String,hasActiveWorkout:Boolean):String =
        if(route=="entreno-activo" && !hasActiveWorkout) "inicio" else route
}
