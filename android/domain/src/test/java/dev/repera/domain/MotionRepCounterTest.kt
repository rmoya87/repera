package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

/** Espejo del comportamiento de RepCounter.swift de ReperaDomain. */
class MotionRepCounterTest {

    @Test
    fun unPicoSobreElUmbralCuentaUnaRepeticion() {
        val counter = MotionRepCounter()
        var t = 0.0
        fun feed(m: Double) { t += 0.04; counter.ingest(m, t) }
        feed(1.0); feed(1.6); feed(1.9); feed(1.2); feed(1.0)
        assertEquals(1, counter.count)
    }

    @Test
    fun picosBajoElUmbralNoCuentan() {
        val counter = MotionRepCounter()
        var t = 0.0
        fun feed(m: Double) { t += 0.04; counter.ingest(m, t) }
        feed(1.0); feed(1.2); feed(1.3); feed(1.1)
        assertEquals(0, counter.count)
    }

    @Test
    fun respetaElIntervaloMinimoEntreRepeticiones() {
        val counter = MotionRepCounter()
        // Dos picos separados solo 0.16 s: el segundo no cuenta.
        var t = 0.0
        fun feed(m: Double) { t += 0.04; counter.ingest(m, t) }
        feed(1.6); feed(1.1)
        feed(1.8); feed(1.1)
        assertEquals(1, counter.count)
    }

    @Test
    fun elAjusteManualNuncaBajaDeCero() {
        val counter = MotionRepCounter()
        counter.applyManualDelta(3)
        assertEquals(3, counter.count)
        counter.applyManualDelta(-5)
        assertEquals(0, counter.count)
    }

    @Test
    fun resetVuelveACero() {
        val counter = MotionRepCounter()
        counter.applyManualDelta(4)
        counter.reset()
        assertEquals(0, counter.count)
    }
}
