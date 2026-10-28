package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class ExternalHealthReadGateTest {
 @Test fun acceptsOnlySameOwnerRecordAndRevision() {
  val gate=ExternalHealthReadGate("a","r","rev1")
  assertTrue(gate.accepts("a","r","rev1"))
  assertFalse(gate.accepts("b","r","rev1"))
  assertFalse(gate.accepts("a","other","rev1"))
  assertFalse(gate.accepts("a","r","rev2"))
 }
 @Test fun closedSheetRejectsLateAsyncAndContractResults() {
  val gate=ExternalHealthReadGate("a","r","rev1")
  gate.invalidate()
  assertFalse(gate.accepts("a","r","rev1"))
 }
 @Test fun reloginSameAccountRejectsOriginalRevision() {
  val gate=ExternalHealthReadGate("a","r","first-login")
  assertFalse(gate.accepts("a","r","second-login"))
 }
}
