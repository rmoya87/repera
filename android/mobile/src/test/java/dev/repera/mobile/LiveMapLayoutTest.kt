package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class LiveMapLayoutTest {
 @Test fun windowDimensionsNotDeviceOrientationDriveLandscape() {
  assertFalse(liveMapLandscape(600f,400f))
  assertFalse(liveMapLandscape(700f,900f))
  assertTrue(liveMapLandscape(620f,400f))
  assertTrue(liveMapLandscape(1000f,600f))
 }
 @Test fun statusAndMetricsColumnStaysBoundedLikeApple() {
  assertEquals(260.4f,liveMapOverlayWidth(620f),0.01f)
  assertEquals(390f,liveMapOverlayWidth(1000f),0.01f)
 }
}
