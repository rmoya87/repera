package dev.repera.wear
import org.json.JSONObject
import org.junit.Test
import org.junit.Assert.*
class WearWodTimerScopeInstrumentedTest {
 @Test fun timerOnlyAppliesToExactSessionAndZeroBasedBlock() {
  val timer=JSONObject().put("sessionId","a").put("blockIndex",1)
  assertTrue(wearTimerMatches(timer,"a",2))
  assertFalse(wearTimerMatches(timer,"b",2))
  assertFalse(wearTimerMatches(timer,"a",1))
  assertFalse(wearTimerMatches(JSONObject().put("sessionId","a"),"a",1))
  assertFalse(wearTimerMatches(null,"a",1))
 }
 @Test fun transientPauseAndRestOnlySurviveSameSessionIdentity() {
  assertFalse(wearSessionChanged("a","a"))
  assertTrue(wearSessionChanged("a","b"))
  assertTrue(wearSessionChanged(null,"a"))
 }
}
