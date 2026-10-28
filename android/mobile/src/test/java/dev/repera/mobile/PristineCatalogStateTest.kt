package dev.repera.mobile
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class PristineCatalogStateTest {
 private fun seed()=JSONObject().put("exercises",JSONArray(java.io.File("src/main/assets/catalog_seed.json").readText()))
  .put("routines",JSONArray()).put("workouts",JSONArray()).put("bodyWeights",JSONArray()).put("favoriteTimers",JSONArray())
  .put("settings",JSONObject()).put("exerciseLoadPrefs",JSONObject()).put("syncRevision",0)
  .put("updatedAt","1970-01-01T00:00:00Z").put("lastWriterDeviceId","")
 @Test fun currentBundledBootstrapIsRecognizedExactly() {assertTrue(WorkoutMirrorStore.canonicalDigest(JSONObject().put("exercises",seed().getJSONArray("exercises"))),PristineCatalogState.virgin(seed()))}
 @Test fun editedCatalogCannotBeDiscardedJustBecauseCountAndCustomFlagMatch() {
  val s=seed();s.getJSONArray("exercises").getJSONObject(0).put("isFavorite",true)
  assertFalse(PristineCatalogState.virgin(s));assertFalse(PristineCatalogState.exceptWorkouts(s))
 }
 @Test fun unknownStateAndLegacyCatalogAreNotDisposable() {
  assertFalse(PristineCatalogState.virgin(seed().put("profile",JSONObject().put("name","Private"))))
  val s=seed();s.getJSONArray("exercises").remove(0);assertFalse(PristineCatalogState.virgin(s))
 }
}
