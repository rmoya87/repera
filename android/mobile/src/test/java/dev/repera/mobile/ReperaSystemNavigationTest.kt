package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ReperaSystemNavigationTest {
    @Test fun externalEntriesOnlyResolveToAllowlistedScreens() {
        assertEquals("en-vivo", LiveNavigationTarget.route("live"))
        assertEquals("inicio", LiveNavigationTarget.route("today"))
        assertEquals("temporizador", LiveNavigationTarget.route("timer"))
        assertEquals("ejercicios", LiveNavigationTarget.route("exercises"))
        assertNull(LiveNavigationTarget.route("delete-workouts"))
        assertEquals("inicio", LiveNavigationTarget.resolvedRoute("entreno-activo", false))
    }
}
