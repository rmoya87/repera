package dev.repera.mobile
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
@RunWith(RobolectricTestRunner::class)
@Config(sdk=[35])
class WodServiceBindingTest {
 private val context:Context get()=ApplicationProvider.getApplicationContext()
 @Test fun tickNeverReadsReplacementBlockClock() {
  org.robolectric.shadows.ShadowSystemClock.advanceBy(java.time.Duration.ofSeconds(2))
  val store=WodTimerStore(context,"service-original")
  val binding=WodServiceBinding("session",0,"service-original","original")
  store.update("session",0,"start","original")
  assertTrue(binding.read(context).running)
  store.update("session",0,"start","replacement")
  assertFalse(binding.read(context).running)
  assertEquals(0,binding.read(context).elapsedSeconds)
 }
 @Test fun tickDoesNotReadOtherOwnerOrSession() {
  WodTimerStore(context,"service-other").update("session",0,"start","original")
  assertFalse(WodServiceBinding("session",0,"service-empty","original").read(context).running)
  assertFalse(WodServiceBinding("another-session",0,"service-other","original").read(context).running)
 }
}
