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
  val freshIds=(0 until planned.length()).map {planned.getJSONObject(it).optString("id")}.filter {it.isNotBlank()}.toSet()
  for(i in 0 until planned.length()) {
   val next=planned.getJSONObject(i)
   val nextId=next.optString("id")
   // Apple: la identidad estable del ítem manda; el emparejamiento por ejercicio solo sirve a sesiones antiguas
   // (ids que ya no existen en el plan nuevo), nunca reasigna resultados de otro ítem repetido.
   val index=(if(nextId.isNotBlank()) remaining.indexOfFirst {it.optString("id")==nextId}.takeIf {it>=0} else null)
    ?: remaining.indexOfFirst {it.optString("id") !in freshIds && it.optString("blockId")==next.optString("blockId") && same(it,next)}
     .takeIf {it>=0} ?: remaining.indexOfFirst {it.optString("id") !in freshIds && same(it,next)}
   if(index>=0) {
    val prior=remaining.removeAt(index)
    for(k in listOf("loggedSets","completedReps","isCompleted")) if(prior.has(k)) next.put(k,prior.get(k))
   }
  }
  val items=(0 until planned.length()).map {planned.getJSONObject(it)}
  val selected=current?.let {c ->items.indexOfFirst {c.optString("id").isNotBlank() && it.optString("id")==c.optString("id")}
   .takeIf {it>=0} ?: items.indexOfFirst {it.optString("blockId")==c.optString("blockId") && same(it,c)}
   .takeIf {it>=0} ?: items.indexOfFirst {same(it,c)}}?.takeIf {it>=0}
   ?: session.optInt("currentIndex").coerceIn(0,planned.length()-1)
  session.put("routineBlocks",fresh.getJSONArray("routineBlocks")).put("exercises",planned).put("currentIndex",selected)
 }
}
