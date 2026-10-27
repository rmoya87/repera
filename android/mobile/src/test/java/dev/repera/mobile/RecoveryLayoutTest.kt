package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
class RecoveryLayoutTest {
 @Test fun twoColumnsStartAtApple620Threshold() {
  assertEquals(1,recoveryColumns(360f));assertEquals(1,recoveryColumns(619f))
  assertEquals(2,recoveryColumns(620f));assertEquals(2,recoveryColumns(840f))
 }
 @org.junit.Test fun readinessHeightUsesActualColumnAndClamps() {
  org.junit.Assert.assertEquals(220f,readinessChartHeightDp(900f,false),0.01f)
  org.junit.Assert.assertEquals(205f,readinessChartHeightDp(300f,true),0.01f)
  org.junit.Assert.assertEquals(232f,readinessChartHeightDp(380f,true),0.01f)
  org.junit.Assert.assertEquals(270f,readinessChartHeightDp(600f,true),0.01f)
 }
 @Test fun sleepHeightUsesColumnWithoutAddingFiller() {
  assertEquals(220f,sleepChartHeightDp(600f,false),0.001f)
  assertEquals(220f,sleepChartHeightDp(300f,true),0.001f)
  assertEquals(342f,sleepChartHeightDp(492f,true),0.001f)
 }
 @Test fun sleepDomainKeepsUnusualObservedNightsVisible() {
  val day=java.time.LocalDate.of(2026,10,27)
  val regular=listOf(dev.repera.domain.RecoverySleepNight(day,7.0,1.0,1.0))
  assertEquals(6.4,sleepChartBounds(regular).first,0.001)
  assertEquals(7.7,sleepChartBounds(regular).second,0.001)
  val unusual=listOf(dev.repera.domain.RecoverySleepNight(day,2.0,0.0,0.0))
  assertTrue(2.0 in sleepChartBounds(unusual).first..sleepChartBounds(unusual).second)
 }
}
