package dev.repera.wear

/**
 * Per-item exponential backoff for durable outbox resends. An item is sent again
 * only when it is due; the ACK (or removal from the outbox) forgets it.
 */
internal class WearRetrySchedule(
    private val baseMs: Long = 5_000L,
    private val maxMs: Long = 5 * 60_000L
) {
    private class Entry(var attempts: Int, var nextAtMs: Long)
    private val entries = HashMap<String, Entry>()

    @Synchronized fun due(ids: Collection<String>, nowMs: Long): List<String> {
        entries.keys.retainAll(ids.toSet())
        return ids.filter { id -> (entries[id]?.nextAtMs ?: Long.MIN_VALUE) <= nowMs }
    }

    @Synchronized fun markSent(id: String, nowMs: Long) {
        val entry = entries.getOrPut(id) { Entry(0, nowMs) }
        entry.nextAtMs = nowMs + (baseMs shl entry.attempts.coerceAtMost(16)).coerceAtMost(maxMs)
        entry.attempts++
    }

    @Synchronized fun remove(id: String) { entries.remove(id) }

    @Synchronized fun reset() { entries.clear() }

    @Synchronized fun nextDueAt(): Long? = entries.values.minOfOrNull { it.nextAtMs }
}
