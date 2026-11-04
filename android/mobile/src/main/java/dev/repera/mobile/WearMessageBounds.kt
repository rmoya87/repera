package dev.repera.mobile

/**
 * Tope de mensajes Wear Data Layer en el teléfono (paridad con
 * `WearPayload.MAX_BYTES` del módulo wear). Se aplica antes de parsear JSON.
 */
internal object WearMessageBounds {
    const val MAX_BYTES = 256 * 1024

    fun withinLimit(bytes: ByteArray?): Boolean =
        bytes == null || bytes.size <= MAX_BYTES
}
