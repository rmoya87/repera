package dev.repera.wear

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/** Outbox at-least-once del reloj sobre SharedPreferences reales. */
@RunWith(AndroidJUnit4::class)
class WearPendingSetStoreInstrumentedTest {

    private val context
        get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Before
    @After
    fun clean() {
        WearPendingSetStore(context).clear()
    }

    @Test
    fun appendConservaTodosLosCamposDelComando() {
        val store = WearPendingSetStore(context)
        val id = store.append("session-1", 2, 8, 62.5, rir = 2.0,
            durationSeconds = 45, quantityUnit = "calories", deficitCm = 10)
        val all = store.all()
        assertEquals(1, all.size)
        val command = all.first()
        assertEquals(id, command.getString("id"))
        assertEquals("session-1", command.getString("sessionId"))
        assertEquals(2, command.getInt("exerciseIndex"))
        assertEquals(8, command.getInt("quantity"))
        assertEquals(62.5, command.getDouble("weightKg"), 0.001)
        assertEquals(2.0, command.getDouble("rir"), 0.001)
        assertEquals(45, command.getInt("durationSeconds"))
        assertEquals("calories", command.getString("quantityUnit"))
        assertEquals(10, command.getInt("deficitCm"))
    }

    @Test
    fun removeSoloBorraElIdConfirmado() {
        val store = WearPendingSetStore(context)
        val first = store.append("s", 0, 5, null)
        val second = store.append("s", 1, 6, null)
        store.remove(first)
        val all = store.all()
        assertEquals(1, all.size)
        assertEquals(second, all.first().getString("id"))
    }

    @Test
    fun clearVaciaLaCola() {
        val store = WearPendingSetStore(context)
        store.append("s", 0, 5, null)
        store.clear()
        assertEquals(0, store.count())
    }

    @Test
    fun appendRechazaEntradasInvalidas() {
        val store = WearPendingSetStore(context)
        assertThrows(IllegalArgumentException::class.java) {
            store.append("", 0, 5, null)
        }
        assertThrows(IllegalArgumentException::class.java) {
            store.append("s", 0, 0, null)
        }
        assertThrows(IllegalArgumentException::class.java) {
            store.append("s", 0, 5, -1.0)
        }
        assertThrows(IllegalArgumentException::class.java) {
            store.append("s", 0, 5, null, rir = 9.0)
        }
        assertThrows(IllegalArgumentException::class.java) {
            store.append("s", 0, 5, null, quantityUnit = "stones")
        }
        assertThrows(IllegalArgumentException::class.java) {
            store.append("s", 0, 5, null, deficitCm = 400)
        }
        assertTrue(store.count() == 0)
    }
    @Test fun warmupAndFailureAreDurableAndWarmupCannotClaimFailure() {
        val store=WearPendingSetStore(context)
        store.append("s",0,5,20.0,warmup=true,toFailure=true)
        val saved=WearPendingSetStore(context).all().single()
        assertTrue(saved.getBoolean("warmup"));org.junit.Assert.assertFalse(saved.getBoolean("toFailure"))
    }

    @Test fun appendPersistsDropAndRestPauseTechniques() {
        val store = WearPendingSetStore(context)
        store.append("s", 0, 10, 60.0, kind = "dropset",
            drops = listOf(8 to 50.0, 6 to 40.0))
        val drop = store.all().single()
        assertEquals("dropset", drop.getString("kind"))
        assertEquals(2, drop.getJSONArray("drops").length())
        store.clear()
        store.append("s", 0, 13, 80.0, kind = "restpause",
            clusters = listOf(8 to 15, 5 to 15))
        val rp = store.all().single()
        assertEquals("restpause", rp.getString("kind"))
        assertEquals(2, rp.getJSONArray("clusters").length())
        assertEquals(15, rp.getJSONArray("clusters").getJSONObject(0).getInt("restSeconds"))
    }

    @Test fun warmupForcesStraightEvenIfKindDropset() {
        val store = WearPendingSetStore(context)
        store.append("s", 0, 5, 20.0, warmup = true, kind = "dropset",
            drops = listOf(4 to 15.0))
        val saved = store.all().single()
        assertEquals("straight", saved.getString("kind"))
        assertTrue(!saved.has("drops") || saved.optJSONArray("drops") == null)
    }
}
