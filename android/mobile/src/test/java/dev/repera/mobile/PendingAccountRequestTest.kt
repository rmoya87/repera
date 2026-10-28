package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class PendingAccountRequestTest {
 @Test fun callbackCannotBeRelabeledBySecondLaunchAfterAccountChange() {
  val request=PendingAccountRequest()
  assertTrue(request.begin("a",1));assertFalse(request.begin("b",2))
  assertFalse(request.consume("b",2))
  assertTrue(request.begin("b",2));assertTrue(request.consume("b",2))
 }
 @Test fun recreationAndRepeatedCallbackHaveNoBinding() {
  val request=PendingAccountRequest();assertFalse(request.consume("a",1))
  request.begin("a",1);assertTrue(request.consume("a",1));assertFalse(request.consume("a",1))
 }
 @Test fun sameOwnerNewLoginAndLogoutRejectOldCallback() {
  val request=PendingAccountRequest();request.begin("a",1)
  assertFalse(request.consume("a",3));request.begin("a",3)
  assertFalse(request.consume(null,4));request.begin("a",5);request.clear()
  assertFalse(request.consume("a",5))
 }
}
