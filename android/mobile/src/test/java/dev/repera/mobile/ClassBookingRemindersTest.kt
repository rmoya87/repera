package dev.repera.mobile

import org.junit.Assert.*
import org.junit.Test
import java.time.Instant

class ClassBookingRemindersTest {
    private val now = Instant.parse("2026-11-04T10:00:00Z").toEpochMilli()
    private fun occurrence(id: String, at: Long, status: String = "active") =
        BusinessCenterStore.Occurrence(
            id = id, orgId = "org", kind = "class", title = "Clase",
            startsAt = Instant.ofEpochMilli(at).toString(), endsAt = null,
            capacity = 10, status = status
        )
    private fun booking(id: String, occurrenceId: String, status: String = "booked") =
        BusinessCenterStore.Booking(
            id = id, orgId = "org", clientId = "client",
            occurrenceId = occurrenceId, status = status
        )

    @Test fun schedulesAtExactlyOneHourBeforeStarts() {
        val start = now + 4L * 3_600_000
        val snapshot = BusinessCenterStore.Snapshot(
            occurrences = listOf(occurrence("class", start)),
            bookings = listOf(booking("booking", "class"))
        )
        assertEquals(listOf("booking" to (start - 3_600_000L)),
            ClassBookingReminders.eligible(snapshot, now))
    }

    @Test fun ignoresWaitlistCancelledAndPastEvents() {
        val snapshot = BusinessCenterStore.Snapshot(
            occurrences = listOf(
                occurrence("old", now - 3_600_000),
                occurrence("future", now + 4L * 3_600_000),
                occurrence("inactive", now + 4L * 3_600_000, "cancelled")
            ),
            bookings = listOf(
                booking("a", "old"), booking("b", "future", "waitlist"),
                booking("c", "future", "cancelled"), booking("d", "inactive")
            )
        )
        assertTrue(ClassBookingReminders.eligible(snapshot, now).isEmpty())
    }

    @Test fun capsReminderCountAndUsesDeterministicOrder() {
        val classes = (1..40).map {
            occurrence(it.toString(), now + (it + 2L) * 3_600_000)
        }
        val bookings = classes.map { booking(it.id, it.id) }
        val due = ClassBookingReminders.eligible(
            BusinessCenterStore.Snapshot(occurrences = classes, bookings = bookings), now
        )
        assertEquals(30, due.size)
        assertEquals("1", due.first().first)
        assertEquals("30", due.last().first)
    }
}
