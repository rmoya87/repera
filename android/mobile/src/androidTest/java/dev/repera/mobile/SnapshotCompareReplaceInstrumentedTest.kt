package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class SnapshotCompareReplaceInstrumentedTest {
 private fun doc(id:String)=JSONObject().put("exercises",JSONArray()).put("routines",JSONArray()).put("workouts",JSONArray())
  .put("syncRevision",0).put("marker",id).toString().toByteArray()
 @Test fun twoInstancesCannotReplaceAnInterveningWrite() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-snapshot-cas-${java.util.UUID.randomUUID()}"
  val a=LocalSnapshotStore(context,account);val b=LocalSnapshotStore(context,account)
  a.write(doc("start"));val expected=a.read()
  b.write(doc("new"))
  assertFalse(a.replaceIfUnchanged(expected,doc("remote")))
  assertArrayEquals(doc("new"),b.read())
  assertTrue(a.replaceIfUnchanged(doc("new"),doc("accepted")))
  assertArrayEquals(doc("accepted"),b.read())
 }
 @Test fun provenanceConcurrentInstancesKeepEveryEntry() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-provenance-${java.util.UUID.randomUUID()}"
  val a=LocalSnapshotStore(context,account);val b=LocalSnapshotStore(context,account)
  val start=java.util.concurrent.CountDownLatch(1)
  val x=Thread {start.await();repeat(30) {a.addMirrorProvenance(mapOf("a$it" to "hash-a$it"))}}
  val y=Thread {start.await();repeat(30) {b.addMirrorProvenance(mapOf("b$it" to "hash-b$it"))}}
  x.start();y.start();start.countDown();x.join();y.join()
  val actual=a.readMirrorProvenance();assertEquals(60,actual.size)
  repeat(30) {assertEquals("hash-a$it",actual["a$it"]);assertEquals("hash-b$it",actual["b$it"])}
 }
}
