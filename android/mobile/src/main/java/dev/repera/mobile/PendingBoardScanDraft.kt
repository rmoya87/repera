package dev.repera.mobile

import dev.repera.domain.RoutineBlock

/**
 * Stash en memoria: tras confirmar el escáner se abre `rutina-nueva` con estos
 * bloques (paridad iOS DayEditor one-off). Se consume al sembrar el editor.
 */
internal object PendingBoardScanDraft {
    @Volatile
    private var heldTitle: String? = null

    @Volatile
    private var heldBlocks: List<RoutineBlock>? = null

    fun hold(title: String, blocks: List<RoutineBlock>) {
        heldTitle = title.trim().ifBlank { null }
        heldBlocks = blocks.takeIf { it.isNotEmpty() }
    }

    fun consume(): Pair<String?, List<RoutineBlock>>? {
        val blocks = heldBlocks ?: return null
        val title = heldTitle
        heldTitle = null
        heldBlocks = null
        return title to blocks
    }

    fun clear() {
        heldTitle = null
        heldBlocks = null
    }
}
