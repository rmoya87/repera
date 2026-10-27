package dev.repera.mobile
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class CatalogActiveReferenceTest {
 @Test fun dedupePreservesEmbeddedAndActiveExerciseReferences() {
  val seed=JSONArray(java.io.File("src/main/assets/catalog_seed.json").readText())
  val original=seed.getJSONObject(0)
  val seedId=original.getString("id")
  val imported=JSONObject(original.toString()).put("id","imported-fixture")
  val state=JSONObject().put("exercises",JSONArray(seed.toString()).put(imported))
   .put("routines",JSONArray()).put("workouts",JSONArray())
   .put("activeSession",JSONObject().put("exercises",JSONArray().put(JSONObject().put("exercise",JSONObject().put("id",seedId)))))
   .put("syncRevision",3)
  CatalogRefreshMigration.mergeSeedIntoState(seed,state)
  val ids=state.getJSONArray("exercises").let {a ->(0 until a.length()).map {a.getJSONObject(it).getString("id")}}
  assertTrue(ids.contains(seedId));assertFalse(ids.contains("imported-fixture"))
 }
 @Test fun dedupeDoesNotDeleteEitherIdWhenBothAreReferencedInNestedHistory() {
  val seed=JSONArray(java.io.File("src/main/assets/catalog_seed.json").readText())
  val seedId=seed.getJSONObject(0).getString("id")
  val state=JSONObject().put("exercises",JSONArray(seed.toString()).put(JSONObject(seed.getJSONObject(0).toString()).put("id","other")))
   .put("routines",JSONArray()).put("workouts",JSONArray().put(JSONObject().put("exercises",JSONArray()
    .put(JSONObject().put("exercise",JSONObject().put("id",seedId)))
    .put(JSONObject().put("exercise",JSONObject().put("id","other")))))).put("syncRevision",2)
  CatalogRefreshMigration.mergeSeedIntoState(seed,state)
  assertEquals(seed.length()+1,state.getJSONArray("exercises").length())
 }
}
