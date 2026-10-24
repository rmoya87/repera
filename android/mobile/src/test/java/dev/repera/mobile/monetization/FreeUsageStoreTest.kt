package dev.repera.mobile.monetization

import java.io.File
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Persistencia y ciclo de vida de FreeUsageStore (paridad semántica iOS:
 * archivo local por dispositivo, idempotencia por attemptID, mes natural).
 */
class FreeUsageStoreTest {
    private lateinit var dir: File

    @Before fun setUp() {
        dir = java.nio.file.Files.createTempDirectory("freeusage").toFile()
    }

    @After fun tearDown() {
        dir.deleteRecursively()
    }

    @Test fun `primera carga materializa estado vacio normalizado`() {
        val store = FreeUsageStore.forAccount(dir)
        store.load()
        assertEquals(0, store.state.boardScansConsumed)
        assertTrue(File(dir, "free_usage.json").exists())
    }

    @Test fun `consumo persiste tras recargar como en reinstalacion sin borrar datos`() {
        val store = FreeUsageStore.forAccount(dir)
        store.load()
        assertTrue(store.consumeBoardScan("attempt-1", isPro = false))
        assertEquals(1, store.state.boardScansConsumed)

        val reloaded = FreeUsageStore.forAccount(dir)
        reloaded.load()
        assertEquals(1, reloaded.state.boardScansConsumed)
        assertTrue(reloaded.state.consumedAttemptIDs.contains("attempt-1"))
    }

    @Test fun `mismo attemptID no consume dos veces`() {
        val store = FreeUsageStore.forAccount(dir)
        store.load()
        assertTrue(store.consumeBoardScan("attempt-2", isPro = false))
        assertFalse(store.consumeBoardScan("attempt-2", isPro = false))
        assertEquals(1, store.state.boardScansConsumed)
    }

    @Test fun `directorios distintos no comparten consumo (aislamiento por carpeta)`() {
        val other = java.nio.file.Files.createTempDirectory("freeusage2").toFile()
        try {
            val a = FreeUsageStore.forAccount(dir); a.load()
            val b = FreeUsageStore.forAccount(other); b.load()
            a.consumeBoardScan("attempt-3", isPro = false)
            assertEquals(1, a.state.boardScansConsumed)
            assertEquals(0, b.state.boardScansConsumed)
        } finally {
            other.deleteRecursively()
        }
    }

    @Test fun `json corrupto se recupera a estado vacio sin romper`() {
        dir.mkdirs()
        File(dir, "free_usage.json").writeText("{ not json")
        val store = FreeUsageStore.forAccount(dir)
        store.load()
        assertEquals(0, store.state.boardScansConsumed)
    }

    @Test fun `pro no consume cuota`() {
        val store = FreeUsageStore.forAccount(dir)
        store.load()
        assertFalse(store.consumeBoardScan("attempt-4", isPro = true))
        assertEquals(0, store.state.boardScansConsumed)
    }
}
