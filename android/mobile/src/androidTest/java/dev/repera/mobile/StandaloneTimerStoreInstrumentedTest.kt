package dev.repera.mobile

import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Persistencia de temporizadores favoritos (hub «＋» → abrir/editar/eliminar,
 *  paridad FavoriteTimerStore de iOS). */
class StandaloneTimerStoreInstrumentedTest {

    @Test fun favoritesRoundTripUpdateAndDelete() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        ctx.getSharedPreferences("repera.standalone.timer", 0).edit().clear().commit()
        val store = StandaloneTimerStore(ctx)
        assertTrue(store.favorites().isEmpty())

        val a = store.save(FavoriteTimer(title = "EMOM 10",
            config = StandaloneTimerConfig(mode = StandaloneTimerMode.INTERVALS,
                rounds = 10, workMinutes = 1, workSeconds = 0)))
        val b = store.save(FavoriteTimer(title = "Cuenta atrás 20:00",
            config = StandaloneTimerConfig(mode = StandaloneTimerMode.DOWN,
                durationMinutes = 20, durationSeconds = 0)))
        // Nueva instancia = recreación de Activity/proceso: los favoritos siguen.
        val reopened = StandaloneTimerStore(ctx)
        assertEquals(listOf("EMOM 10", "Cuenta atrás 20:00"),
            reopened.favorites().map { it.title })
        assertEquals(StandaloneTimerMode.DOWN,
            reopened.favorites().first { it.id == b.id }.config.mode)

        // Actualizar por id no duplica (edición anclada al favorito abierto).
        reopened.save(a.copy(title = "EMOM 10 RX"))
        assertEquals(2, reopened.favorites().size)
        assertEquals("EMOM 10 RX",
            reopened.favorites().first { it.id == a.id }.title)

        reopened.delete(a.id)
        assertEquals(listOf(b.id), reopened.favorites().map { it.id })
        reopened.delete(b.id)
        assertTrue(reopened.favorites().isEmpty())
    }
}
