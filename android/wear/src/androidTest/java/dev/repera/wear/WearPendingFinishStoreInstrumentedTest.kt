package dev.repera.wear
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.Assert.*
class WearPendingFinishStoreInstrumentedTest {
 private val c get()=InstrumentationRegistry.getInstrumentation().targetContext
 @Before @After fun clear() {WearPendingFinishStore(c).clear()}
 @Test fun finishSurvivesRecreationAndOnlyMatchingAckClears() {
  WearPendingFinishStore(c).queue("s1");WearPendingFinishStore(c).queue("s1")
  assertEquals("s1",WearPendingFinishStore(c).sessionId())
  assertTrue(runCatching {WearPendingFinishStore(c).queue("s2")}.isFailure)
  WearPendingFinishStore(c).acknowledge("other")
  assertEquals("s1",WearPendingFinishStore(c).sessionId())
  WearPendingFinishStore(c).acknowledge("s1")
  assertNull(WearPendingFinishStore(c).sessionId())
 }
}
