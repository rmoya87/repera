package dev.repera.mobile

import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test

class HealthRecordPagesTest {
    @Test fun allPagesIncludingEmptyIntermediateAreRead() = runBlocking {
        val calls = mutableListOf<String?>()
        val records = collectHealthPages { token ->
            calls.add(token)
            when (token) {
                null -> HealthRecordPage(listOf(1, 2), "opaque1")
                "opaque1" -> HealthRecordPage(emptyList(), "opaque2")
                else -> HealthRecordPage(listOf(3), null)
            }
        }
        assertEquals(listOf(1, 2, 3), records)
        assertEquals(listOf(null, "opaque1", "opaque2"), calls)
    }
    @Test fun emptyTerminalPageIsComplete() = runBlocking {
        assertTrue(collectHealthPages<Int> { HealthRecordPage(emptyList(), null) }.isEmpty())
    }
    @Test fun providerFailureCannotBecomePartialSuccess() = runBlocking {
        var failed = false
        try {
            collectHealthPages { token ->
                if (token == null) HealthRecordPage(listOf(1), "next") else error("provider unavailable")
            }
        } catch (_: IllegalStateException) { failed = true }
        assertTrue(failed)
    }
    @Test fun repeatedTokenStopsInsteadOfLoopingForever() = runBlocking {
        var failed = false
        try { collectHealthPages { HealthRecordPage(listOf(1), "same") } }
        catch (_: IllegalStateException) { failed = true }
        assertTrue(failed)
    }
}
