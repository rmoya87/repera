package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class ActiveSessionFavoriteTest {
 private fun entry(id:String,block:String,kind:String="strength")=JSONObject().put("id",id).put("blockId",block)
  .put("blockKind",kind).put("exercise",JSONObject().put("id","ex-$id").put("name","Ejercicio $id"))
  .put("plannedSets",JSONArray().put(JSONObject().put("id","planned-$id").put("targetReps",8)))
  .put("loggedSets",JSONArray().put(JSONObject().put("id","logged-$id").put("reps",99)))
 @Test fun existingScheduledRoutineIsMarkedInPlaceWithoutCloningOrChangingPlan() {
  val routine=JSONObject().put("id","r").put("weekday",2).put("progression","linear").put("isFavorite",false)
  val session=JSONObject().put("routineId","r").put("exercises",JSONArray())
  val state=JSONObject().put("routines",JSONArray().put(routine)).put("activeSession",session)
  assertEquals("r",ActiveSessionFavorite.save(state));assertEquals("r",ActiveSessionFavorite.save(state))
  assertEquals(1,state.getJSONArray("routines").length());assertTrue(routine.getBoolean("isFavorite"))
  assertEquals(2,routine.getInt("weekday"));assertEquals("linear",routine.getString("progression"))
 }
 @Test fun standaloneBuildsOrderedMixedBlocksFromPrescriptionsNotLoggedResultsAndIsIdempotent() {
  val a=entry("a","strength");val b=entry("b","strength").put("plannedSets",JSONArray())
  val c=entry("c","wod","wod").put("wodFormat","amrap").put("blockTimeCapMinutes",12)
   .put("blockRounds",4).put("blockIntervalSeconds",60).put("blockWorkSeconds",40).put("blockRestSeconds",20)
  val session=JSONObject().put("id","s").put("title","").put("exercises",JSONArray().put(a).put(b).put(c))
  val before=session.getJSONArray("exercises").toString()
  val state=JSONObject().put("activeSession",session).put("routines",JSONArray())
  val id=ActiveSessionFavorite.save(state);assertEquals(id,session.getString("routineId"))
  assertEquals(id,ActiveSessionFavorite.save(state));assertEquals(1,state.getJSONArray("routines").length())
  val favorite=state.getJSONArray("routines").getJSONObject(0)
  assertEquals("Favorito",favorite.getString("title"));assertFalse(favorite.has("weekday"))
  val blocks=favorite.getJSONArray("blocks");assertEquals(2,blocks.length())
  val strength=blocks.getJSONObject(0).getJSONArray("exercises")
  assertEquals(8,strength.getJSONObject(0).getJSONArray("plannedSets").getJSONObject(0).getInt("targetReps"))
  assertEquals(8,strength.getJSONObject(1).getJSONArray("plannedSets").getJSONObject(0).getInt("targetReps"))
  val wod=blocks.getJSONObject(1);assertEquals("amrap",wod.getString("wodFormat"))
  assertEquals(12,wod.getInt("timeCapMinutes"));assertEquals(60,wod.getInt("emomIntervalSeconds"))
  assertEquals(8,wod.getJSONArray("movements").getJSONObject(0).getInt("reps"))
  assertEquals(before,session.getJSONArray("exercises").toString())
 }
 @Test fun deniedNewTemplateLeavesSessionAndRoutinesUntouched() {
  val state=JSONObject().put("routines",JSONArray().put(JSONObject().put("id","weekly").put("weekday",1)))
   .put("activeSession",JSONObject().put("id","active").put("exercises",JSONArray().put(entry("a","b"))))
  val before=state.toString();var count:Int?=null
  assertThrows(IllegalStateException::class.java) {ActiveSessionFavorite.save(state) {count=it;false}}
  assertEquals(1,count);assertEquals(before,state.toString())
 }
 @Test fun markingExistingRoutineNeedsNoNewSlot() {
  val state=JSONObject().put("routines",JSONArray().put(JSONObject().put("id","existing").put("scheduledDate","2026-10-26")))
   .put("activeSession",JSONObject().put("routineId","existing"))
  assertEquals("existing",ActiveSessionFavorite.save(state) {error("No new template")})
 }
}
