package dev.repera.mobile

/** Almacenamiento local que necesita DriveSnapshotService (permite un doble en memoria en tests JVM). */
interface SnapshotStorage {
    fun read(): ByteArray?
    fun write(bytes: ByteArray)
    /** Compare and replace: a download may not discard a local write made during network IO. */
    fun replaceIfUnchanged(expected:ByteArray?,replacement:ByteArray):Boolean {
        val current=read()
        if(!(current==null && expected==null || current!=null && expected!=null && current.contentEquals(expected))) return false
        write(replacement)
        return true
    }
    fun preserveRemoteBackup(bytes: ByteArray)
    fun readMirrorProvenance(): Map<String, String>
}
