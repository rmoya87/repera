package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ClassCapacityLabelTest {
    @Test fun showsOccupiedSeatsFromConfirmedReservationCount() {
        assertEquals("1/12", aforoLabel(capacity = 12, remaining = null, reserved = 1))
        assertEquals("0/12", aforoLabel(capacity = 12, remaining = null, reserved = 0))
        assertEquals("12/12", aforoLabel(capacity = 12, remaining = 0, reserved = 12))
    }

    @Test fun computesOccupiedSeatsFromAvailablePlaces() {
        assertEquals("1/12", aforoLabel(capacity = 12, remaining = 11, reserved = null))
    }

    @Test fun neverTreatsCapacityAloneAsOccupiedSeats() {
        assertEquals("—/12", aforoLabel(capacity = 12, remaining = null, reserved = null))
        assertNull(aforoLabel(capacity = null, remaining = null, reserved = null))
    }
}
