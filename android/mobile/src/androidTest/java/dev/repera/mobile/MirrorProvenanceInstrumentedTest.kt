package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Procedencia del espejo: persiste por cuenta, se acumula y no se mezcla entre cuentas. Compilada, no ejecutada. */
@RunWith(AndroidJUnit4::class)
class MirrorProvenanceInstrumentedTest {
    @Test fun provenanceIsPerAccountAndAccumulates() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val a = LocalSnapshotStore(ctx, UUID.randomUUID().toString())
        val b = LocalSnapshotStore(ctx, UUID.randomUUID().toString())
        assertEquals(emptyMap<String, String>(), a.readMirrorProvenance())
        a.addMirrorProvenance(mapOf("w1" to "h1"))
        a.addMirrorProvenance(mapOf("w2" to "h2"))
        assertEquals(mapOf("w1" to "h1", "w2" to "h2"), a.readMirrorProvenance())
        assertEquals(emptyMap<String, String>(), b.readMirrorProvenance())
    }
}
