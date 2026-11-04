package dev.repera.wear

import org.json.JSONObject

/** Data Layer bytes are bounded before decoding; an oversize item keeps the last valid state. */
internal object WearPayload {
    const val MAX_BYTES = 256 * 1024

    fun withinLimit(bytes: ByteArray?): Boolean = bytes == null || bytes.size <= MAX_BYTES

    fun json(bytes: ByteArray?): JSONObject? {
        if (bytes == null || bytes.isEmpty() || !withinLimit(bytes)) return null
        return runCatching { JSONObject(String(bytes, Charsets.UTF_8)) }.getOrNull()
    }
}
