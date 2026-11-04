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
    @Test fun invitationOpensOnlyCanonicalUuidAndIgnoresAnythingElse() {
        val id="3F2504E0-4F89-11D3-9A0C-0305E82C3301"
        assertEquals("center/invitacion/"+id.lowercase(),LiveNavigationTarget.route("invitation",listOf(id)))
        assertEquals(id.lowercase(),LiveNavigationTarget.invitationIdFromRoute("center/invitacion/$id"))
        assertEquals("center",LiveNavigationTarget.route("invitation"))
        listOf(listOf("1-1-1-1-1"),listOf("not-a-uuid"),listOf(id,"extra"),listOf("$id;drop"),listOf("../$id"),listOf(" $id"))
            .forEach { assertNull(it.toString(),LiveNavigationTarget.route("invitation",it)) }
        assertNull(LiveNavigationTarget.invitationIdFromRoute("center/invitacion/../x"))
        assertNull(LiveNavigationTarget.invitationIdFromRoute("inicio"))
    }
}
