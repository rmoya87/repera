package dev.repera.mobile

import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

/** Parsed app_state.json shared by the detail providers (exercise history,
 *  series, appearances, load guide). Parsing happens once per snapshot content
 *  and per account, off the main thread; derived values are memoized for that
 *  exact content. The parsed root is never mutated after publication. */
internal class SnapshotDerivedCache {
    private class Entry(val owner: String, val bytes: ByteArray, val root: JSONObject) {
        val memo = ConcurrentHashMap<Any, Any>()
    }

    @Volatile private var entry: Entry? = null

    /** Call from a background thread with the bytes just read from disk. */
    fun publish(owner: String, bytes: ByteArray?) {
        if (bytes == null) {
            if (entry?.owner == owner) entry = null
            return
        }
        val current = entry
        if (current != null && current.owner == owner && current.bytes.contentEquals(bytes)) return
        entry = runCatching { Entry(owner, bytes, JSONObject(String(bytes, Charsets.UTF_8))) }.getOrNull()
    }

    fun clear() { entry = null }

    fun hasSnapshot(owner: String): Boolean = entry?.owner == owner

    /** Memoized derivation for [owner]'s current snapshot; null when there is no
     *  parsed snapshot for that account or [compute] yields null (not memoized). */
    fun <T : Any> derive(owner: String, key: Any, compute: (JSONObject) -> T?): T? {
        val current = entry?.takeIf { it.owner == owner } ?: return null
        @Suppress("UNCHECKED_CAST")
        (current.memo[key] as T?)?.let { return it }
        val value = compute(current.root) ?: return null
        current.memo.putIfAbsent(key, value)
        return value
    }
}
