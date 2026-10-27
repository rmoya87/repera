package dev.repera.mobile

import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Persistencia del reloj WOD (Apple 48060202/07d9f19a/00fee1b4):
 *  sobrevive a muerte de proceso y solo restaura en su bloque original. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class WodTimerStoreTest {

    private var uptime = 1_000L
    private fun store() = WodTimerStore(
        ApplicationProvider.getApplicationContext(), "user-test") { uptime }

    @Test
    fun survivesProcessDeath() {
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 65_000
        // Nueva instancia = proceso nuevo: elapsed y running se conservan.
        val restored = store().read("s1", 0, blockId = "b1")
        assertTrue(restored.running)
        assertEquals(65, restored.elapsedSeconds)
    }

    @Test
    fun pauseCheckpointSurvives() {
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 10_000
        store().update("s1", 0, "pause", blockId = "b1")
        uptime += 999_000
        val restored = store().read("s1", 0, blockId = "b1")
        assertFalse(restored.running)
        assertEquals(10, restored.elapsedSeconds)
    }

    @Test
    fun doesNotRestoreOnOtherBlock() {
        // 00fee1b4: cambio de bloque antes de morir — el reloj no se aplica
        // a un bloque distinto aunque el indice posicional coincida.
        store().update("s1", 0, "start", blockId = "b1")
        val other = store().read("s1", 0, blockId = "b2")
        assertFalse(other.running)
        assertEquals(0, other.elapsedSeconds)
    }

    @Test
    fun legacyEntryWithoutBlockIdStillRestores() {
        // Entradas escritas antes del binding no llevan blockId: se mantienen.
        store().update("s1", 0, "start")
        uptime += 5_000
        val restored = store().read("s1", 0, blockId = "b1")
        assertTrue(restored.running)
        assertEquals(5, restored.elapsedSeconds)
    }

    @Test
    fun finishFreezesRealElapsedAndPersistsPendingEnd() {
        // Apple 39a3f7f2 finishByUser: "Terminar" congela el elapsed REAL del
        // instante y lo guarda como pendingEnd userFinished.
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 65_000
        val finished = store().update("s1", 0, "finish", blockId = "b1")
        assertFalse(finished.running)
        assertEquals(65, finished.elapsedSeconds)
        assertEquals("userFinished", finished.pendingEndReason)
        assertEquals(65, finished.pendingElapsedSeconds)
    }

    @Test
    fun pendingEndSurvivesProcessDeath() {
        // El pendingEnd viaja en el checkpoint: proceso nuevo, mismo bloque.
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 42_000
        store().update("s1", 0, "finish", blockId = "b1")
        uptime += 999_000
        val restored = store().read("s1", 0, blockId = "b1")
        assertEquals("userFinished", restored.pendingEndReason)
        assertEquals(42, restored.pendingElapsedSeconds)
    }

    @Test
    fun consumePendingEndReturnsOnceAndClears() {
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 30_000
        store().update("s1", 0, "finish", blockId = "b1")
        val consumed = store().consumePendingEnd("s1", 0, blockId = "b1")
        assertEquals("userFinished", consumed?.first)
        assertEquals(30, consumed?.second)
        // Segunda lectura: consumido, no vuelve a aparecer.
        assertEquals(null, store().read("s1", 0, blockId = "b1").pendingEndReason)
        assertEquals(null, store().consumePendingEnd("s1", 0, blockId = "b1"))
    }

    @Test
    fun startAbandonsPendingEnd() {
        // Reanudar el reloj tras "Terminar" abandona el fin pendiente.
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 10_000
        store().update("s1", 0, "finish", blockId = "b1")
        val resumed = store().update("s1", 0, "start", blockId = "b1")
        assertTrue(resumed.running)
        assertEquals(null, resumed.pendingEndReason)
    }

    @Test
    fun resetClearsPendingEnd() {
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 10_000
        store().update("s1", 0, "finish", blockId = "b1")
        val reset = store().update("s1", 0, "reset", blockId = "b1")
        assertEquals(null, reset.pendingEndReason)
        assertEquals(0, reset.pendingElapsedSeconds)
    }

    @Test
    fun pauseDoesNotCreatePendingEnd() {
        // Pausar no es terminar: no siembra resultado alguno.
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 10_000
        val paused = store().update("s1", 0, "pause", blockId = "b1")
        assertEquals(null, paused.pendingEndReason)
    }

    @Test
    fun pendingEndHiddenOnOtherBlock() {
        // La guarda de bloque tambien cubre el pendingEnd (00fee1b4).
        store().update("s1", 0, "start", blockId = "b1")
        uptime += 10_000
        store().update("s1", 0, "finish", blockId = "b1")
        val other = store().read("s1", 0, blockId = "b2")
        assertEquals(null, other.pendingEndReason)
        assertEquals(0, other.pendingElapsedSeconds)
    }
}
