package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
class AccountRevisionGateTest {
    @Test fun oldAccountAndOldLoginCannotPublishIntoNewSession() {
        val gate=AccountRevisionGate()
        assertTrue(gate.update("a"));val original=gate.revision
        assertTrue(gate.accepts("a",original))
        assertFalse(gate.update("a")) // token refresh stays same owner
        assertTrue(gate.accepts("a",original))
        gate.update("b");assertFalse(gate.accepts("a",original))
        gate.update("a");assertFalse(gate.accepts("a",original))
        assertTrue(gate.accepts("a",gate.revision))
        gate.update(null);assertFalse(gate.accepts("a",gate.revision))
    }
}
