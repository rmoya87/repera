package dev.repera.mobile
import org.json.JSONArray
import org.json.JSONObject

/** refreshActiveSessionPlan: consume matches once by block+exercise, then by exercise. */
internal object ActiveSessionPlan {
 private fun same(a:JSONObject,b:JSONObject):Boolean {
  val x=a.getJSONObject("exercise");val y=b.getJSONObject("exercise")
  return x.optString("id")==y.optString("id") || x.optString("name").equals(y.optString("name"),ignoreCase=true)
 }
 fun refresh(session:JSONObject,fresh:JSONObject) {
  val old=session.getJSONArray("exercises");val remaining=(0 until old.length()).map {old.getJSONObject(it)}.toMutableList()
  val current=old.optJSONObject(session.optInt("currentIndex"))
  val planned=fresh.getJSONArray("exercises")
  require(planned.length()>0) {"El entreno necesita al menos un ejercicio"}
  for(i in 0 until planned.length()) {
   val next=planned.getJSONObject(i)
   val index=remaining.indexOfFirst {it.optString("blockId")==next.optString("blockId") && same(it,next)}
    .takeIf {it>=0} ?: remaining.indexOfFirst {same(it,next)}
   if(index>=0) {
    val prior=remaining.removeAt(index)
    for(k in listOf("loggedSets","completedReps","isCompleted")) if(prior.has(k)) next.put(k,prior.get(k))
   }
  }
  val items=(0 until planned.length()).map {planned.getJSONObject(it)}
  val selected=current?.let {c ->items.indexOfFirst {it.optString("blockId")==c.optString("blockId") && same(it,c)}
   .takeIf {it>=0} ?: items.indexOfFirst {same(it,c)}}?.takeIf {it>=0}
   ?: session.optInt("currentIndex").coerceIn(0,planned.length()-1)
  session.put("routineBlocks",fresh.getJSONArray("routineBlocks")).put("exercises",planned).put("currentIndex",selected)
 }
}
