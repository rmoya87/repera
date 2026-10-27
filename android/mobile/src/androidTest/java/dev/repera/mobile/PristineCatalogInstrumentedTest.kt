package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class PristineCatalogInstrumentedTest {
 @Test fun actualAndroidJsonCanonicalizationRecognizesBootstrapAndRejectsFavoriteEdit() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-pristine-${java.util.UUID.randomUUID()}"
  CatalogBootstrap.initializeEmptyAccount(context,account)
  val state=JSONObject(String(LocalSnapshotStore(context,account).read()!!))
  assertTrue(PristineCatalogState.virgin(state))
  state.getJSONArray("exercises").getJSONObject(0).put("isFavorite",true)
  assertFalse(PristineCatalogState.virgin(state))
 }
 @Test fun concurrentBootstrapHasOneWinnerAndCannotReplaceExistingHistory() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-bootstrap-race-${java.util.UUID.randomUUID()}"
  val start=java.util.concurrent.CountDownLatch(1)
  val results=java.util.concurrent.CopyOnWriteArrayList<Boolean>()
  val threads=(0..1).map {Thread {start.await();results.add(runCatching {CatalogBootstrap.initializeEmptyAccount(context,account)}.isSuccess)}}
  threads.forEach {it.start()};start.countDown();threads.forEach {it.join()}
  assertEquals(1,results.count {it})
  val local=LocalSnapshotStore(context,account)
  val before=local.read()!!
  assertTrue(PristineCatalogState.virgin(JSONObject(String(before))))
  assertTrue(runCatching {CatalogBootstrap.initializeEmptyAccount(context,account)}.isFailure)
  assertArrayEquals(before,local.read())
 }
}
