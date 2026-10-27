package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.Assert.*
import java.util.UUID
class MirrorDeletionDurabilityInstrumentedTest {
 @Test fun uploadAckDoesNotEraseConcurrentDeleteAndKeepsPermanentRefusal() {
  val c=InstrumentationRegistry.getInstrumentation().targetContext
  val user="test-delete-ledger-${UUID.randomUUID()}"
  val store=WorkoutMirrorStore(c,user)
  store.noteDeleted("first")
  val uploaded=store.pendingDeletes()
  WorkoutMirrorStore(c,user).noteDeleted("later")
  store.acknowledgeDeletes(uploaded)
  val restored=WorkoutMirrorStore(c,user)
  assertEquals(setOf("later"),restored.pendingDeletes())
  assertEquals(setOf("first","later"),restored.deletedIds())
  restored.acknowledgeDeletes(setOf("later"))
  assertTrue(restored.pendingDeletes().isEmpty())
  assertEquals(setOf("first","later"),restored.deletedIds())
 }
}
