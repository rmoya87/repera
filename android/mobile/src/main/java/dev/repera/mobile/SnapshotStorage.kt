package dev.repera.mobile

/** Almacenamiento local que necesita DriveSnapshotService (permite un doble en memoria en tests JVM). */
interface SnapshotStorage {
    fun read(): ByteArray?
    fun write(bytes: ByteArray)
    fun preserveRemoteBackup(bytes: ByteArray)
    fun readMirrorProvenance(): Map<String, String>
}
