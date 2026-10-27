package dev.repera.wear

import androidx.test.core.app.ApplicationProvider
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Apple 44713457: derivacion del intervalo de una serie WOD confirmada en el
 *  reloj y su transporte dedup en la cola pendiente. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class WearWodSeriesTest {

    private fun timer(format: String, sessionId: String = "s1", blockIndex: Int = 0) =
        JSONObject()
            .put("sessionId", sessionId)
            .put("blockIndex", blockIndex)
            .put("format", format)
            .put("intervalSeconds", 60)
            .put("rounds", 10)
            .put("workSeconds", 20)
            .put("restSeconds", 10)
            .put("running", true)
            .put("elapsedSeconds", 0)

    @Test fun emomIntervalFromElapsed() {
        // elapsed 125s con intervalos de 60s -> intervalo 2 (0-based).
        assertEquals(2, wearWodIntervalIndex(timer("emom"), "s1", 1, 125))
        assertEquals(0, wearWodIntervalIndex(timer("emom"), "s1", 1, 59))
    }

    @Test fun tabataIntervalFromElapsed() {
        // 20+10 por ronda: elapsed 45 -> ronda 1 (0-based).
        assertEquals(1, wearWodIntervalIndex(timer("tabata"), "s1", 1, 45))
        assertEquals(0, wearWodIntervalIndex(timer("tabata"), "s1", 1, 19))
    }

    @Test fun noIntervalForForeignTimer() {
        assertNull(wearWodIntervalIndex(timer("emom", sessionId = "otra"), "s1", 1, 125))
        assertNull(wearWodIntervalIndex(timer("emom", blockIndex = 3), "s1", 1, 125))
        assertNull(wearWodIntervalIndex(null, "s1", 1, 125))
    }

    @Test fun noIntervalForGlobalScoreFormat() {
        // AMRAP registra resultado global: el reloj no captura series.
        assertNull(wearWodIntervalIndex(timer("amrap"), "s1", 1, 125))
    }

    @Test fun pendingStoreCarriesInterval() {
        val store = WearPendingSetStore(ApplicationProvider.getApplicationContext())
        val id = store.append("s1", 0, 12, 24.0, intervalIndex = 2)
        val command = store.all().single { it.optString("id") == id }
        assertEquals(2, command.getInt("intervalIndex"))
        store.remove(id)
        assertNull(store.all().firstOrNull { it.optString("id") == id })
    }

    @Test(expected = IllegalArgumentException::class)
    fun pendingStoreRejectsAbsurdInterval() {
        WearPendingSetStore(ApplicationProvider.getApplicationContext())
            .append("s1", 0, 12, null, intervalIndex = 100001)
    }
}
