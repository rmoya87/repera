package dev.repera.domain

/**
 * Immutable, platform-independent progression for per-movement WOD recording.
 * A movement is recorded only on explicit athlete confirmation. Timer ticks
 * never create performed sets or fabricate repetitions.
 */
data class WodMovementEntry(
    val id: String,
    val blockId: String,
    val movementId: String,
    val intervalIndex: Int,
    val quantity: Int,
    val weightKg: Double? = null,
    val recordedAtEpochMs: Long
) {
    init {
        require(id.isNotBlank() && blockId.isNotBlank() && movementId.isNotBlank())
        require(intervalIndex >= 0)
        require(quantity >= 0)
        require(weightKg == null || (weightKg.isFinite() && weightKg >= 0))
        require(recordedAtEpochMs >= 0)
    }
}

data class WodMovementProgress(
    val blockId: String,
    val format: WodFormat,
    val entries: List<WodMovementEntry> = emptyList()
) {
    init {
        require(blockId.isNotBlank())
        require(format.capture == ResultCapture.PER_MOVEMENT_SETS) {
            "This format stores a global score, not movement sets"
        }
        require(entries.all { it.blockId == blockId })
        require(entries.map { it.id }.distinct().size == entries.size) {
            "Duplicate entry IDs would double-count work"
        }
    }

    /** Idempotent upsert supports recovery and correction without duplicating work. */
    fun record(entry: WodMovementEntry): WodMovementProgress {
        require(entry.blockId == blockId)
        return copy(entries = entries.filterNot { it.id == entry.id } + entry)
    }

    fun remove(entryId: String): WodMovementProgress =
        copy(entries = entries.filterNot { it.id == entryId })

    fun forInterval(index: Int): List<WodMovementEntry> {
        require(index >= 0)
        return entries.filter { it.intervalIndex == index }
    }

    fun confirmedQuantity(movementId: String): Int =
        entries.filter { it.movementId == movementId }.sumOf { it.quantity }
}
