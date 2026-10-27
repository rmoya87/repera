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
}
