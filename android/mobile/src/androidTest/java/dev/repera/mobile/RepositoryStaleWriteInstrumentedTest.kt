package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class RepositoryStaleWriteInstrumentedTest {
 @Test fun staleRepositoryStateCannotOverwriteAnotherInstanceEdit() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val account="test-repo-cas-${java.util.UUID.randomUUID()}"
  CatalogBootstrap.initializeEmptyAccount(context,account)
  val first=WorkoutRepository(context,account);val second=WorkoutRepository(context,account)
  val load=WorkoutRepository::class.java.getDeclaredMethod("requireState").apply {isAccessible=true}
  val save=WorkoutRepository::class.java.getDeclaredMethod("save",JSONObject::class.java).apply {isAccessible=true}
  val stale=load.invoke(first) as JSONObject
  val exerciseId=stale.getJSONArray("exercises").getJSONObject(0).getString("id")
  second.createRoutine("Saved by second","strength",listOf(RoutineDraftEntry(exerciseId,8)))
  val local=LocalSnapshotStore(context,account);val saved=local.read()!!
  stale.put("settings",JSONObject().put("weightIncrementKg",5))
  assertTrue(runCatching {save.invoke(first,stale)}.isFailure)
  assertArrayEquals(saved,local.read())
  // A fresh normal action can still save after the rejected stale proposal.
  val id=JSONObject(String(saved)).getJSONArray("exercises").getJSONObject(0).getString("id")
  first.setExerciseFavorite(id,true)
  assertTrue(JSONObject(String(local.read()!!)).getJSONArray("exercises").getJSONObject(0).getBoolean("isFavorite"))
 }
}
