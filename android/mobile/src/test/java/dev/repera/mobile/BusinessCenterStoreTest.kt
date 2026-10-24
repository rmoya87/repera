package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

/** Reglas de Center portadas de BusinessDataStore.swift (iOS). */
class BusinessCenterStoreTest {

    private fun pass(id: String, kind: String = "class", credits: Int = 3,
        status: String = "active", from: String = "2026-01-01T00:00:00Z",
        until: String = "2027-01-01T00:00:00Z") = BusinessCenterStore.Pass(
        id = id, orgId = "org1", clientId = "c1", kind = kind,
        totalCredits = 10, remainingCredits = credits,
        validFrom = from, validUntil = until, status = status)

    private fun occurrence(id: String, kind: String = "class") =
        BusinessCenterStore.Occurrence(id = id, orgId = "org1", kind = kind,
            title = "WOD", startsAt = "2026-10-25T18:00:00Z", endsAt = null,
            capacity = 12, status = "active")

    @Test
    fun availablePassesRequiresSameOrgKindActiveCreditsAndValidity() {
        val occ = occurrence("o1")
        val snapshot = BusinessCenterStore.Snapshot(passes = listOf(
            pass("ok"),
            pass("noCredits", credits = 0),
            pass("expired", until = "2026-01-01T00:00:00Z"),
            pass("notYet", from = "2027-01-01T00:00:00Z"),
            pass("otherKind", kind = "appointment"),
            pass("paused", status = "paused")))
        val usable = snapshot.availablePasses(occ).map { it.id }
        assertEquals(listOf("ok"), usable)
    }

    @Test
    fun remainingPlacesNeedsAvailabilityAndNeverNegative() {
        val occ = occurrence("o1")
        val without = BusinessCenterStore.Snapshot()
        assertNull(without.remainingPlaces(occ))
        val full = BusinessCenterStore.Snapshot(availability = mapOf(
            "o1" to BusinessCenterStore.Availability("o1", capacity = 12, reserved = 15)))
        assertEquals(0, full.remainingPlaces(occ))
    }

    @Test
    fun bookingForOnlyMatchesBookedStatus() {
        val occ = occurrence("o1")
        val snapshot = BusinessCenterStore.Snapshot(bookings = listOf(
            BusinessCenterStore.Booking("b1", "org1", "c1", "o1", "cancelled"),
            BusinessCenterStore.Booking("b2", "org1", "c1", "o1", "booked")))
        assertEquals("b2", snapshot.bookingFor(occ.id)?.id)
        assertNull(snapshot.bookingFor("other"))
    }

    @Test
    fun centerTabVisibleOnlyWhenLinkedOrInvited() {
        assertTrue(!BusinessCenterStore.Snapshot().isLinkedOrInvited)
        assertTrue(BusinessCenterStore.Snapshot(
            athleteCenterIds = setOf("org1")).isLinkedOrInvited)
        assertTrue(BusinessCenterStore.Snapshot(invitations = listOf(
            BusinessCenterStore.Invitation("i1", "org1", "athlete",
                null, null, null))).isLinkedOrInvited)
    }
}
