package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
class ReviewAccountIsolationInstrumentedTest {
 @Test fun consumingOtherAccountCannotRemovePendingReview() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val a="test-review-a-${java.util.UUID.randomUUID()}";val b="test-review-b-${java.util.UUID.randomUUID()}"
  CatalogBootstrap.initializeEmptyAccount(context,a);CatalogBootstrap.initializeEmptyAccount(context,b)
  val state=org.json.JSONObject(String(LocalSnapshotStore(context,a).read()!!))
  val id=state.getJSONArray("exercises").getJSONObject(0).getString("id")
  val repo=WorkoutRepository(context,a)
  val session=java.util.UUID.randomUUID().toString()
  repo.logQuickSets(id,listOf(QuickLogRow(8,40.0),QuickLogRow(8,40.0)),null,session)
  assertNull(WorkoutRepository(context,b).consumePendingReview())
  assertEquals(session,repo.consumePendingReview()?.first)
  assertNull(repo.consumePendingReview())
 }
}
