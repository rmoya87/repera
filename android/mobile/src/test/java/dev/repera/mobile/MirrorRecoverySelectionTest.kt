package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test

/** Selección pura de la recuperación remota→local: sin red, sin Drive/Supabase reales. */
class MirrorRecoverySelectionTest {
    private fun row(id: String, deleted: Boolean = false, finished: Boolean = true, payloadId: String = id) =
        JSONObject().put("id", id).apply {
            if (deleted) put("deleted_at", "2026-10-01T00:00:00Z") else put("deleted_at", JSONObject.NULL)
            put("payload", JSONObject().put("id", payloadId).apply {
                if (finished) put("finishedAt", "2026-10-01T10:00:00Z") else put("finishedAt", JSONObject.NULL) })
        }

    @Test fun recoversOnlyNewIntactLiveRows() {
        val remote = listOf(row("new"), row("known"), row("tomb", deleted = true), row("pendingDelete"),
            row("seen"), row("open", finished = false), row("mismatch", payloadId = "other"))
        val got = WorkoutMirrorStore.selectRecoverable(remote, setOf("known"), setOf("pendingDelete"), mapOf("seen" to "x"))
        assertEquals(listOf("new"), got.map { it.getString("id") })
    }

    @Test fun deletedLocallyButNotYetUploadedIsNotResurrected() {
        val got = WorkoutMirrorStore.selectRecoverable(listOf(row("a")), emptySet(), setOf("a"), emptyMap())
        assertEquals(0, got.size)
    }
}
