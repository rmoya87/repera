package dev.repera.mobile
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/** ReperaStore.favoriteTemplate: prescriptions, never completed work, form the new template. */
internal object ActiveSessionFavorite {
 fun save(state:JSONObject):String {
  val session=state.optJSONObject("activeSession") ?: error("No hay sesión activa")
  val routines=state.optJSONArray("routines") ?: JSONArray().also {state.put("routines",it)}
  val existing=(0 until routines.length()).map {routines.getJSONObject(it)}
   .firstOrNull {it.optString("id")==session.optString("routineId")}
  val favorite=existing ?: template(session).also {routines.put(it)}
  favorite.put("isFavorite",true)
  session.put("routineId",favorite.getString("id"))
  return favorite.getString("id")
 }
 fun template(session:JSONObject):JSONObject {
  val entries=session.getJSONArray("exercises")
  val groups=linkedMapOf<String,MutableList<JSONObject>>()
  for(i in 0 until entries.length()) {
   val e=entries.getJSONObject(i)
   groups.getOrPut(e.optString("blockId").ifBlank {e.getString("id")}) {mutableListOf()}.add(e)
  }
  val blocks=JSONArray()
  for((id,items) in groups) {
   val first=items.first();val format=first.optString("wodFormat")
   val kind=first.optString("blockKind").ifBlank {if(format.isBlank() || format=="strength") "strength" else "wod"}
   val b=JSONObject().put("id",id).put("kind",kind).put("title",first.optString("blockHeader").ifBlank {if(kind=="strength") "Bloque" else "WOD"})
   if(kind=="strength") {
    val ex=JSONArray()
    for(e in items) {
     val planned=e.optJSONArray("plannedSets")?.takeIf {it.length()>0}
       ?: JSONArray().put(JSONObject().put("id",UUID.randomUUID().toString()).put("targetReps",8))
     ex.put(JSONObject().put("id",UUID.randomUUID().toString())
       .put("exerciseId",e.getJSONObject("exercise").getString("id"))
       .put("plannedSets",JSONArray(planned.toString())))
    }
    b.put("exercises",ex)
   } else {
    val moves=JSONArray()
    for(e in items) {
     val exercise=e.getJSONObject("exercise")
     val move=JSONObject().put("id",UUID.randomUUID().toString()).put("exerciseId",exercise.getString("id"))
      .put("name",exercise.getString("name"))
     e.optJSONArray("plannedSets")?.optJSONObject(0)?.let {if(it.has("targetReps")) move.put("reps",it.get("targetReps"))}
     moves.put(move)
    }
    b.put("movements",moves)
    for((from,to) in mapOf("wodFormat" to "wodFormat","blockTimeCapMinutes" to "timeCapMinutes",
      "blockIntervalSeconds" to "emomIntervalSeconds","blockRounds" to "rounds",
      "blockWorkSeconds" to "workSeconds","blockRestSeconds" to "restSeconds"))
      if(first.has(from) && !first.isNull(from)) b.put(to,first.get(from))
   }
   blocks.put(b)
  }
  return JSONObject().put("id",UUID.randomUUID().toString())
   .put("title",session.optString("title").ifEmpty {"Favorito"}).put("blocks",blocks)
   .put("progression","off").put("isFavorite",true)
 }
}
