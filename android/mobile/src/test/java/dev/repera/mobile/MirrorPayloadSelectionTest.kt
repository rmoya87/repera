package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test

/** Sync incremental del espejo: sólo se descarga el payload de filas que lo necesitan. */
class MirrorPayloadSelectionTest {
    private fun index(id: String, deleted: Boolean = false) = id to JSONObject().put("id", id)
        .put("deleted_at", if (deleted) "2026-10-01T00:00:00Z" else JSONObject.NULL)

    @Test fun downloadsOnlyUnseenRemoteAndLocallyDivergentRows() {
        val existing = mapOf(
            index("unseen-remote"), index("seen-remote-only"), index("local-same"),
            index("local-edited"), index("local-first-sync"), index("pending-delete"), index("tomb", deleted = true))
        val local = mapOf("local-same" to "d1", "local-edited" to "d2-new", "local-first-sync" to "d3")
        val seen = mapOf("seen-remote-only" to "x", "local-same" to "d1", "local-edited" to "d2-old")
        val got = WorkoutMirrorStore.payloadIdsNeeded(existing, local, seen, setOf("pending-delete")).sorted()
        assertEquals(listOf("local-edited", "local-first-sync", "unseen-remote"), got)
    }

    @Test fun steadyStateDownloadsNothing() {
        val existing = (1..2000).associate { index("w$it") }
        val local = existing.keys.associateWith { "d-$it" }
        assertEquals(0, WorkoutMirrorStore.payloadIdsNeeded(existing, local, local, emptySet()).size)
    }
}
