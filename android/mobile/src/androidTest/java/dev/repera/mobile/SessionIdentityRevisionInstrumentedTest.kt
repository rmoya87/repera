package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
/** Run only in isolated test app: synthetic identities, no OAuth or network. */
class SessionIdentityRevisionInstrumentedTest {
 @Test fun tokenRefreshPreservesRevisionButSignoutLoginAndAccountSwitchInvalidate() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val store=SessionStore(context)
  assertNull("Fresh isolated test app required",store.load())
  val a=SessionStore.StoredSession("fixture-a","a@example.invalid","A","fixture-user-a","not-a-token","not-a-refresh",1)
  try {
   store.save(a);val first=store.identityRevision();assertNotNull(first)
   store.save(a.copy(accessToken="refreshed-fixture"));assertEquals(first,store.identityRevision())
   store.clear();store.save(a);assertNotEquals(first,store.identityRevision())
   val second=store.identityRevision()
   store.save(a.copy(uniqueId="fixture-b",userId="fixture-user-b"));store.save(a)
   assertNotEquals(second,store.identityRevision())
  } finally {store.clear()}
 }
 @Test fun refreshCannotRestoreClearedOrDifferentIdentity() {
  val store=SessionStore(InstrumentationRegistry.getInstrumentation().targetContext)
  assertNull("Fresh isolated test app required",store.load())
  val a=SessionStore.StoredSession("fixture-a","a@example.invalid","A","fixture-user-a","fixture-token","fixture-refresh",1)
  try {
   store.save(a);val revision=store.identityRevision()
   assertTrue(store.saveIfCurrent(revision,a.uniqueId,a.userId,a.copy(accessToken="new-fixture")))
   store.clear()
   assertFalse(store.saveIfCurrent(revision,a.uniqueId,a.userId,a))
   assertNull(store.load())
   store.save(a);val next=store.identityRevision()
   store.save(a.copy(uniqueId="b",userId="b"))
   assertFalse(store.saveIfCurrent(next,a.uniqueId,a.userId,a))
   assertEquals("b",store.load()?.uniqueId)
   assertFalse(store.clearIfCurrent(next,a.uniqueId,a.userId))
   assertEquals("b",store.load()?.uniqueId)
   assertTrue(store.clearIfCurrent(store.identityRevision(),"b","b"))
   assertNull(store.load())
  } finally {store.clear()}
 }
}
