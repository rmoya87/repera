package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

class SyncVersionTest {
    @Test fun revisionWinsBeforeTimestamp() {
        val newer = SyncVersion(5, 0, "a")
        val older = SyncVersion(4, Long.MAX_VALUE, "z")
        assertTrue(newer > older)
    }

    @Test fun timestampBreaksRevisionTie() {
        assertTrue(SyncVersion(2, 22, "a") > SyncVersion(2, 21, "z"))
    }

    @Test fun deviceIdBreaksEqualRevisionAndTimestamp() {
        assertTrue(SyncVersion(2, 22, "watch") > SyncVersion(2, 22, "phone"))
    }
}
