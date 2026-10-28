package dev.repera.domain

import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

class CenterCancellationPolicyTest {
    @Test fun moreThan12HoursRecoversCreditCopy() {
        val now = Instant.parse("2026-10-28T10:00:00Z")
        val starts = "2026-10-29T10:00:01Z"
        val text = CenterCancellationPolicy.notice(starts, now)
        assertTrue(text.contains("más de 12 horas"))
        assertTrue(text.contains("recuperarás"))
    }

    @Test fun within12HoursWarnsNoCredit() {
        val now = Instant.parse("2026-10-28T10:00:00Z")
        val starts = "2026-10-28T20:00:00Z"
        val text = CenterCancellationPolicy.notice(starts, now)
        assertTrue(text.contains("últimas 12 horas"))
        assertTrue(text.contains("NO devuelve"))
    }

    @Test fun missingStartUsesGenericFallback() {
        val text = CenterCancellationPolicy.notice(null)
        assertTrue(text.contains("política de cancelación"))
    }
}
