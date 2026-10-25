package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.security.MessageDigest
import java.util.UUID

/** LocalSnapshotStore REAL (AtomicFile): rutas de escritura/lectura y copias de
 *  seguridad que la cobertura JVM no ejercita (usa almacenamiento simulado).
 *  Cierra el abierto de la reconciliación sync 5h-5i sin tocar backend. */
@RunWith(AndroidJUnit4::class)
class LocalSnapshotStoreInstrumentedTest {

    private fun stateJson(revision: Int, marker: String): ByteArray =
        JSONObject()
            .put("syncRevision", revision)
            .put("marker", marker)
            .put("workouts", org.json.JSONArray())
            .put("routines", org.json.JSONArray())
            .put("exercises", org.json.JSONArray())
            .toString().toByteArray(Charsets.UTF_8)

    private fun folderFor(account: String): File {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val sha = MessageDigest.getInstance("SHA-256")
            .digest(account.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
        return File(ctx.filesDir, "users/$sha")
    }

    @Test fun writeReadRoundtripAndBackupOnOverwrite() {
        val account = UUID.randomUUID().toString()
        val store = LocalSnapshotStore(
            InstrumentationRegistry.getInstrumentation().targetContext, account)
        assertNull(store.read())

        val v1 = stateJson(1, "primero")
        store.write(v1)
        assertArrayEquals(v1, store.read())

        // Sobrescribir con contenido distinto conserva la versión previa.
        val v2 = stateJson(2, "segundo")
        store.write(v2)
        assertArrayEquals(v2, store.read())
        val backup = File(folderFor(account), "previous_app_state.json")
        assertTrue(backup.exists())
        assertArrayEquals(v1, backup.readBytes())

        // Reescribir el MISMO contenido no toca la copia.
        store.write(v2)
        assertArrayEquals(v1, backup.readBytes())
    }

    @Test fun preserveRemoteBackupWritesGuardCopy() {
        val account = UUID.randomUUID().toString()
        val store = LocalSnapshotStore(
            InstrumentationRegistry.getInstrumentation().targetContext, account)
        val remote = stateJson(7, "remoto")
        store.preserveRemoteBackup(remote)
        val guard = File(folderFor(account), "remote_before_upload.json")
        assertTrue(guard.exists())
        assertArrayEquals(remote, guard.readBytes())
    }

    @Test fun validateRejectsCorruptDocuments() {
        val store = LocalSnapshotStore(
            InstrumentationRegistry.getInstrumentation().targetContext,
            UUID.randomUUID().toString())
        val bad = "{ \"syncRevision\": 1 }".toByteArray(Charsets.UTF_8)
        try {
            store.write(bad)
            throw AssertionError("un documento sin workouts/routines/exercises no debe aceptarse")
        } catch (_: IllegalArgumentException) { }
        assertNull(store.read())
    }

    @Test fun snapshotRevisionReflectsStoredRevision() {
        val store = LocalSnapshotStore(
            InstrumentationRegistry.getInstrumentation().targetContext,
            UUID.randomUUID().toString())
        assertNull(store.snapshotRevision())
        store.write(stateJson(9, "rev"))
        assertEquals(9, store.snapshotRevision())
        assertNotNull(store.read())
    }
}
