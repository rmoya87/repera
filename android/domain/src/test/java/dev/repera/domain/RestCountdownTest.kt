package dev.repera.domain
import org.junit.Test
import org.junit.Assert.*
class RestCountdownTest {
 @Test fun delayedTicksDoNotExtendRest() {
  val clock=RestCountdown();clock.start(60,1000)
  assertEquals(60,clock.remainingSeconds(1000));assertEquals(59,clock.remainingSeconds(2001))
  assertEquals(10,clock.remainingSeconds(51000));assertEquals(0,clock.remainingSeconds(99999))
 }
 @Test fun pauseKeepsFractionAndResumeDoesNotResetDuration() {
  val clock=RestCountdown();clock.start(10,0);clock.pause(2500)
  assertEquals(8,clock.remainingSeconds(300000))
  clock.resume(300000);assertEquals(8,clock.remainingSeconds(300000))
  assertEquals(1,clock.remainingSeconds(306501));assertEquals(0,clock.remainingSeconds(307500))
  clock.clear();assertEquals(0,clock.remainingSeconds(999999))
 }
 @Test fun repeatedPauseResumeAndNewStartAreIdempotent() {
  val clock=RestCountdown();clock.start(5,0);clock.pause(1000);clock.pause(2000)
  clock.resume(10000);clock.resume(11000);assertEquals(3,clock.remainingSeconds(11000))
  clock.start(2,12000);assertEquals(2,clock.remainingSeconds(12000))
 }
 @Test fun restoredFractionDoesNotGainASecondAndPauseRemainsFrozen() {
  val clock=RestCountdown();clock.restore(7501,false,10000)
  assertEquals(7501L,clock.remainingMillis(10000));assertEquals(8,clock.remainingSeconds(10000))
  assertEquals(1L,clock.remainingMillis(17500));assertEquals(0,clock.remainingSeconds(17501))
  clock.restore(7501,true,20000);assertEquals(7501L,clock.remainingMillis(50000))
  clock.resume(50000);assertEquals(1L,clock.remainingMillis(57500))
 }
}
