package dev.repera.mobile

/** Non-gesture way to move a chart selection (TalkBack custom actions). No geometry involved. */
internal object ChartSelectionStep {
    /** From no selection both directions start at the last point; result stays within 0 until size-1, or null when empty. */
    fun step(current: Int?, delta: Int, size: Int): Int? {
        if (size <= 0) return null
        val base = current?.coerceIn(0, size - 1) ?: (size - 1)
        return (if (current == null) base else base + delta).coerceIn(0, size - 1)
    }
}
