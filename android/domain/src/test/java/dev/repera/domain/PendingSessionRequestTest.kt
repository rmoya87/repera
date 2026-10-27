package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class PendingSessionRequestTest {
    @Test fun secondLaunchCannotRelabelOldPermissionResult() {
        val p=PendingSessionRequest();assertTrue(p.begin("a",1));assertFalse(p.begin("b",2))
        assertFalse(p.consume("b",2));assertFalse(p.consume("a",1))
        assertTrue(p.begin("b",2));assertTrue(p.consume("b",2))
    }
    @Test fun sessionABAAndLogoutInvalidateOriginalResult() {
        val p=PendingSessionRequest();assertTrue(p.begin("a",1));assertFalse(p.consume("a",3))
        assertTrue(p.begin("a",3));assertFalse(p.consume(null,4))
    }
}
