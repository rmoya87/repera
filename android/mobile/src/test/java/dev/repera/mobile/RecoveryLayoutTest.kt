package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
class RecoveryLayoutTest {
 @Test fun twoColumnsStartAtApple620Threshold() {
  assertEquals(1,recoveryColumns(360f));assertEquals(1,recoveryColumns(619f))
  assertEquals(2,recoveryColumns(620f));assertEquals(2,recoveryColumns(840f))
 }
}
