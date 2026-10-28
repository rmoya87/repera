package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class WatchSessionReconciliationTest {
    @Test fun emptyOrDifferentPhoneSessionCannotEraseWatchStartedWork() {
        assertTrue(WatchSessionReconciliation.preserveLocal(true,"local",null,null))
        assertTrue(WatchSessionReconciliation.preserveLocal(true,"local","other",null))
        assertTrue(WatchSessionReconciliation.preserveLocal(true,"local",null,"other"))
    }
    @Test fun matchingAdoptionOrMatchingFinishedSessionCanReconcile() {
        assertFalse(WatchSessionReconciliation.preserveLocal(true,"local","local",null))
        assertFalse(WatchSessionReconciliation.preserveLocal(true,"local",null,"local"))
        assertFalse(WatchSessionReconciliation.preserveLocal(false,"local",null,null))
        assertFalse(WatchSessionReconciliation.preserveLocal(true,null,null,null))
    }
}
