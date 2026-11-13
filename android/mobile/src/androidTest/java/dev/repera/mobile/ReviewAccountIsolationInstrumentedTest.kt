package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.security.MessageDigest

class ReviewAccountIsolationInstrumentedTest {
 @Test fun consumingOtherAccountCannotRemovePendingReview() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val a="test-review-a-${java.util.UUID.randomUUID()}"
  val b="test-review-b-${java.util.UUID.randomUUID()}"
  CatalogBootstrap.initializeEmptyAccount(context,a)
  CatalogBootstrap.initializeEmptyAccount(context,b)
  val session=java.util.UUID.randomUUID().toString()
  // Valoración sintética: el motor real exige ≥2 días previos y no aplica
  // a un quick-log virgen. Este test aisla solo la clave pending por cuenta.
  val review=JSONObject()
   .put("overallScore",7)
   .put("headline","OK")
   .put("keepTips",JSONArray())
   .put("improveTips",JSONArray())
   .put("movements",JSONArray())
   .put("indicators",JSONArray())
  val store=LocalSnapshotStore(context,a)
  val state=JSONObject(String(store.read()!!))
  state.getJSONArray("workouts").put(JSONObject()
   .put("id",session)
   .put("title","Sesión")
   .put("phase","finished")
   .put("exercises",JSONArray())
   .put("sessionReview",review))
  store.write(state.toString().toByteArray())
  val digest=MessageDigest.getInstance("SHA-256")
   .digest(a.toByteArray(Charsets.UTF_8)).joinToString(""){"%02x".format(it)}
  context.getSharedPreferences("repera.review.$digest", android.content.Context.MODE_PRIVATE)
   .edit().putString(SessionReviewSupport.PREFS_PENDING_KEY,session).commit()
  assertNull(WorkoutRepository(context,b).consumePendingReview())
  assertEquals(session,WorkoutRepository(context,a).consumePendingReview()?.first)
  assertNull(WorkoutRepository(context,a).consumePendingReview())
 }
}
