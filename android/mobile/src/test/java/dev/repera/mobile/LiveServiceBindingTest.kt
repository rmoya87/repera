package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class LiveServiceBindingTest {
 @Test fun validCurrentActivityMatches() {
  assertTrue(LiveServiceBinding("a","login1","run1").matches("a","login1","run1"))
 }
 @Test fun staleActionCannotTargetNewActivityOrLogin() {
  val original=LiveServiceBinding("a","login1","run1")
  assertFalse(original.matches("a","login1","run2"))
  assertFalse(original.matches("a","login2","run1"))
  assertFalse(original.matches("b","login1","run1"))
 }
 @Test fun missingBindingNeverAuthenticates() {
  assertFalse(LiveServiceBinding("a",null,"run1").matches("a",null,"run1"))
  assertFalse(LiveServiceBinding("a","login1",null).matches("a","login1",null))
  assertFalse(LiveServiceBinding("a","login1","").matches("a","login1",""))
 }
}
