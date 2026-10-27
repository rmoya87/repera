package dev.repera.mobile
import org.json.JSONObject

/** Only the exact bundled catalog is disposable. Unknown legacy/content stays a conflict. */
internal object PristineCatalogState {
 private const val SEED_DIGEST="32b128f8b0c3c9754b4a15ec5ab5f5f131fc1afdb7113022b47175fc0c088e50"
 private val keys=setOf("exercises","routines","workouts","bodyWeights","favoriteTimers",
  "settings","exerciseLoadPrefs","activeSession","syncRevision","updatedAt","lastWriterDeviceId")
 fun matchesCatalog(state:JSONObject):Boolean {
  val exercises=state.optJSONArray("exercises") ?: return false
  return WorkoutMirrorStore.canonicalDigest(JSONObject().put("exercises",exercises))==SEED_DIGEST
 }
 fun exceptWorkouts(state:JSONObject):Boolean {
  if(state.keys().asSequence().any {it !in keys}) return false
  return matchesCatalog(state) && listOf("routines","bodyWeights","favoriteTimers").all {state.optJSONArray(it)?.length()==0} &&
   listOf("settings","exerciseLoadPrefs").all {state.optJSONObject(it)?.length()==0} &&
   (!state.has("activeSession") || state.isNull("activeSession"))
 }
 fun virgin(state:JSONObject):Boolean=exceptWorkouts(state) && state.optJSONArray("workouts")?.length()==0 &&
  state.optInt("syncRevision",-1)==0 && state.optString("updatedAt")=="1970-01-01T00:00:00Z" &&
  state.optString("lastWriterDeviceId")==""
}
