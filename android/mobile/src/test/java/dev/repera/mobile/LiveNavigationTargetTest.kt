package dev.repera.mobile

import org.junit.Assert.*
import org.junit.Test

class LiveNavigationTargetTest {
    @Test fun liveOpensRecorderWithoutStartingOrTargetingAnotherWorkout() {
        assertEquals("en-vivo",LiveNavigationTarget.route("live"))
        assertEquals("en-vivo",LiveNavigationTarget.resolvedRoute("en-vivo",true))
        assertNull(LiveNavigationTarget.route("unknown"));assertNull(LiveNavigationTarget.route(null))
    }
    @Test fun workoutOpensCurrentSessionOnlyWhenItExistsOtherwiseHome() {
        val route=LiveNavigationTarget.route("workout")!!
        assertEquals("entreno-activo",LiveNavigationTarget.resolvedRoute(route,true))
        assertEquals("inicio",LiveNavigationTarget.resolvedRoute(route,false))
    }
}
