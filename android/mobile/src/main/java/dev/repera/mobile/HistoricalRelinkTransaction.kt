package dev.repera.mobile

import org.json.JSONObject
import java.security.MessageDigest

/**
 * Inactive transaction policy. No real file/store implementation and no caller.
 * A future caller must bind storage to one verified account and serialize writes.
 * Backup must succeed before CAS; rollback CAS must never overwrite later work.
 */
internal object HistoricalRelinkTransaction {
    interface Store {
        fun read(): ByteArray?
        /** Must durably save the EXACT original bytes or throw; never silently overwrite. */
        fun backup(accountId: String, digest: String, bytes: ByteArray): String
        fun compareAndSwap(expected: ByteArray, replacement: ByteArray): Boolean
    }
    class Plan internal constructor(
        val accountId: String,
        original: ByteArray,
        replacement: ByteArray,
        val changeCount: Int
    ) {
        private val before = original.copyOf()
        private val after = replacement.copyOf()
        fun original(): ByteArray = before.copyOf()
        fun replacement(): ByteArray = after.copyOf()
    }
    data class Applied(val plan: Plan, val backupReference: String)

    fun prepare(accountId: String, bytes: ByteArray): Plan? {
        require(accountId.isNotBlank())
        val state = JSONObject(String(bytes, Charsets.UTF_8))
        // Even though preview never changes activeSession, a future apply may
        // reload UI state. Refuse a live session rather than racing training.
        if (state.has("activeSession") && !state.isNull("activeSession")) return null
        val preview = HistoricalCatalogRelink.preview(state)
        if (preview.changes.isEmpty()) return null
        // Ambiguous paths are untouched by preview; abort the whole proposal so
        // a future caller cannot hide a partial or hard-to-explain repair.
        if (preview.ambiguous.isNotEmpty()) return null
        return Plan(accountId, bytes, preview.state.toString().toByteArray(Charsets.UTF_8), preview.changes.size)
    }

    fun apply(plan: Plan, currentAccountId: String, store: Store): Applied? {
        if (currentAccountId != plan.accountId) return null
        val before = plan.original()
        if (store.read()?.contentEquals(before) != true) return null
        val digest = MessageDigest.getInstance("SHA-256").digest(before).joinToString("") { "%02x".format(it) }
        val backup = store.backup(plan.accountId, digest, before.copyOf())
        check(backup.isNotBlank()) { "Original snapshot backup was not confirmed" }
        // CAS checks again after backup, closing the concurrent-write window.
        if (!store.compareAndSwap(before, plan.replacement())) return null
        return Applied(plan, backup)
    }

    fun rollback(applied: Applied, currentAccountId: String, store: Store): Boolean {
        if (currentAccountId != applied.plan.accountId) return false
        return store.compareAndSwap(applied.plan.replacement(), applied.plan.original())
    }
}
