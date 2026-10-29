package dev.repera.mobile

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Reproduce el bug R4 P0: capturar centerGate.revision ANTES de
 * verifiedSupabase=session (null→userId) invalida current() y deja
 * prepareAccountDataAfterAuth en no-op.
 */
class AccountRevisionGateRestoreTest {
    @Test
    fun capturingRevisionBeforeSessionAssignmentInvalidatesCurrent() {
        val gate = AccountRevisionGate()
        val before = gate.revision
        gate.update("user-1")
        assertFalse(
            "revision capturada antes de update(userId) no debe aceptar current()",
            gate.revision == before
        )
    }

    @Test
    fun capturingRevisionAfterSessionAssignmentKeepsCurrent() {
        val gate = AccountRevisionGate()
        gate.update("user-1")
        val after = gate.revision
        assertTrue(gate.revision == after)
        assertFalse(gate.update("user-1"))
        assertTrue(
            "mismo userId no debe subir revision; current() sigue válido",
            gate.revision == after
        )
    }
}
