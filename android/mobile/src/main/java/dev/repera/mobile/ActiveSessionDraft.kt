package dev.repera.mobile
import org.json.JSONArray
import org.json.JSONObject

/**
 * Port of Apple SessionController.updateExerciseDraft on the Android session JSON.
 * Persists edited, not-yet-done planned sets of an active session and its routine block item
 * (item-id identity, occurrence fallback for old sessions, WOD explicitPlannedSets).
 * An empty list is kept on purpose. Pure rule; not wired to any Play UI yet.
 */
internal object ActiveSessionDraft {
 private fun same(a:String,b:String)=a.equals(b,ignoreCase=true)
 /** @return true when something changed. */
 fun update(session:JSONObject,id:String,plannedSets:JSONArray,quantityUnit:String?):Boolean {
  val ex=session.optJSONArray("exercises")?:return false
  val index=(0 until ex.length()).firstOrNull {ex.getJSONObject(it).optString("id")==id}?:return false
  val current=ex.getJSONObject(index)
  val oldPlanned=current.optJSONArray("plannedSets")?.toString()?:"[]"
  val oldUnit=if(current.has("quantityUnit")&&!current.isNull("quantityUnit")) current.optString("quantityUnit") else null
  if(oldPlanned==plannedSets.toString()&&oldUnit==quantityUnit) return false
  current.put("plannedSets",plannedSets)
  if(quantityUnit==null) current.remove("quantityUnit") else current.put("quantityUnit",quantityUnit)
  val blockId=current.optString("blockId")
  val blocks=session.optJSONArray("routineBlocks")
  if(blocks!=null&&blockId.isNotBlank()) {
   val block=(0 until blocks.length()).map {blocks.getJSONObject(it)}.firstOrNull {it.optString("id")==blockId}
   if(block!=null) {
    val exId=current.getJSONObject("exercise").optString("id");val exName=current.getJSONObject("exercise").optString("name")
    val prior=(0 until index).map {ex.getJSONObject(it)}.filter {it.optString("blockId")==blockId}
    if(block.optString("kind")=="strength") {
     val items=block.optJSONArray("exercises")?:JSONArray()
     val matches=(0 until items.length()).filter {items.getJSONObject(it).optString("exerciseId")==exId}
     val occurrence=prior.count {it.getJSONObject("exercise").optString("id")==exId}
     val item=(0 until items.length()).firstOrNull {items.getJSONObject(it).optString("id")==id}?:matches.getOrNull(occurrence)
     if(item!=null) {
      items.getJSONObject(item).put("plannedSets",plannedSets)
      if(quantityUnit==null) items.getJSONObject(item).remove("quantityUnit") else items.getJSONObject(item).put("quantityUnit",quantityUnit)
     }
    } else {
     val mv=block.optJSONArray("movements")?:JSONArray()
     val matches=(0 until mv.length()).filter {val m=mv.getJSONObject(it);m.optString("exerciseId")==exId||same(m.optString("name"),exName)}
     val occurrence=prior.count {same(it.getJSONObject("exercise").optString("name"),exName)}
     val item=(0 until mv.length()).firstOrNull {mv.getJSONObject(it).optString("id")==id}?:matches.getOrNull(occurrence)
     if(item!=null) mv.getJSONObject(item).put("explicitPlannedSets",plannedSets)
    }
   }
  }
  return true
 }

 data class Row(val id:String,val reps:Int,val weightKg:Double?=null,val deficitCm:Int?=null,val durationSeconds:Int?=null,val rir:Double?=null,val completed:Boolean=false)

 /**
  * Apple persistActiveLiveDraft (planned part): rows -> planned sets. Pending rows keep their own id; a completed row
  * keeps the id of the planned set at the same position. Writing a different absolute kg drops targetPercent1RM
  * (and its "minimum" flag); otherwise the previous percent survives. Reps are at least 1.
  */
 fun revise(existing:JSONArray,rows:List<Row>,loadField:String):JSONArray {
  val out=JSONArray()
  rows.forEachIndexed {i,row ->
   val prev=existing.optJSONObject(i)
   val kg=if(loadField=="deficitCm") row.deficitCm?.toDouble() else row.weightKg
   val prevKg=if(prev!=null&&prev.has("targetWeightKg")&&!prev.isNull("targetWeightKg")) prev.optDouble("targetWeightKg") else null
   val changedAbsolute=loadField=="weightKg"&&kg!=prevKg
   val o=JSONObject().put("id",if(row.completed) (prev?.optString("id")?.takeIf {it.isNotBlank()}?:row.id) else row.id)
    .put("targetReps",maxOf(1,row.reps))
   kg?.let {o.put("targetWeightKg",it)}
   row.durationSeconds?.let {o.put("targetDurationSeconds",it)}
   row.rir?.let {o.put("targetRir",it)}
   if(!changedAbsolute&&prev!=null&&prev.has("targetPercent1RM")&&!prev.isNull("targetPercent1RM")) {
    o.put("targetPercent1RM",prev.get("targetPercent1RM"))
    if(prev.optBoolean("targetPercent1RMIsMinimum",false)) o.put("targetPercent1RMIsMinimum",true)
   }
   out.put(o)
  }
  return out
 }

 /**
  * Apple SessionController.replaceRecordedSets: replaces loggedSets of the exercise with that id and recomputes
  * completedReps from work-phase sets only (dropset drops included). false when nothing changes or the id is unknown.
  * Pure rule; not wired to Play UI.
  */
 fun replaceRecordedSets(session:JSONObject,id:String,sets:JSONArray):Boolean {
  val ex=session.optJSONArray("exercises")?:return false
  val item=(0 until ex.length()).map {ex.getJSONObject(it)}.firstOrNull {it.optString("id")==id}?:return false
  if((item.optJSONArray("loggedSets")?.toString()?:"[]")==sets.toString()) return false
  item.put("loggedSets",sets)
  var reps=0
  for(i in 0 until sets.length()) {
   val set=sets.getJSONObject(i)
   if(set.optString("phase","work")!="work") continue
   reps+=set.optInt("reps")
   if(set.optString("kind")=="dropset") {val d=set.optJSONArray("drops");if(d!=null) for(k in 0 until d.length()) reps+=d.getJSONObject(k).optInt("reps")}
  }
  item.put("completedReps",reps)
  return true
 }

 /**
  * Apple removeLiveSet for a PENDING row: drops the planned set with that id, only when it is not yet covered by a recorded
  * work set (index >= count of work-phase logged sets). The last one may be removed (empty list is kept on purpose).
  * Recorded results are never touched here.
  */
 fun removePending(session:JSONObject,exerciseId:String,setId:String):Boolean {
  val ex=session.optJSONArray("exercises")?:return false
  val item=(0 until ex.length()).map {ex.getJSONObject(it)}.firstOrNull {it.optString("id")==exerciseId}?:return false
  val planned=item.optJSONArray("plannedSets")?:return false
  val logged=item.optJSONArray("loggedSets")
  val workDone=(0 until (logged?.length()?:0)).count {logged!!.getJSONObject(it).optString("phase","work")=="work"}
  val at=(0 until planned.length()).firstOrNull {planned.getJSONObject(it).optString("id")==setId}?:return false
  if(at<workDone) return false
  val kept=JSONArray();for(i in 0 until planned.length()) if(i!=at) kept.put(planned.get(i))
  val unit=if(item.has("quantityUnit")&&!item.isNull("quantityUnit")) item.optString("quantityUnit") else null
  return update(session,exerciseId,kept,unit)
 }

 /**
  * Apple persistActiveLiveDraft for ONE pending row edit: same coverage rule as removePending. Reps are at least 1.
  * A different absolute kg (when the exercise loads by weight) drops targetPercent1RM and its minimum flag.
  */
 fun editPending(session:JSONObject,exerciseId:String,setId:String,reps:Int,weightKg:Double?,loadsByWeight:Boolean):Boolean {
  val ex=session.optJSONArray("exercises")?:return false
  val item=(0 until ex.length()).map {ex.getJSONObject(it)}.firstOrNull {it.optString("id")==exerciseId}?:return false
  val planned=item.optJSONArray("plannedSets")?:return false
  val logged=item.optJSONArray("loggedSets")
  val workDone=(0 until (logged?.length()?:0)).count {logged!!.getJSONObject(it).optString("phase","work")=="work"}
  val at=(0 until planned.length()).firstOrNull {planned.getJSONObject(it).optString("id")==setId}?:return false
  if(at<workDone) return false
  val copy=JSONArray(planned.toString())
  val o=copy.getJSONObject(at)
  val prevKg=if(o.has("targetWeightKg")&&!o.isNull("targetWeightKg")) o.optDouble("targetWeightKg") else null
  o.put("targetReps",maxOf(1,reps))
  if(loadsByWeight) {
   if(weightKg==null) o.remove("targetWeightKg") else o.put("targetWeightKg",weightKg)
   if(weightKg!=prevKg) {o.remove("targetPercent1RM");o.remove("targetPercent1RMIsMinimum")}
  }
  val unit=if(item.has("quantityUnit")&&!item.isNull("quantityUnit")) item.optString("quantityUnit") else null
  return update(session,exerciseId,copy,unit)
 }

 /**
  * Apple persistActiveLiveDraft (recorded part): editable rows -> logged sets. Rows with reps > 0 become results (typing is
  * saving, no per-set check); rows with reps 0 are dropped. A row whose id matches an existing straight work set keeps that
  * set (completedAt, id) and gets the row values; a new row gets a fresh straight work set. Existing straight work sets that
  * no row represents any more were deleted by the user and are dropped. Warmup sets and non-straight sets (dropset, rest-pause,
  * clusters) are not shown as rows, so they are kept untouched in place (Android-specific safeguard: Apple rows do not hold them).
  * loadField: "weightKg", "deficitCm" or "none"; weight/deficit are stored only when > 0.
  */
 fun recorded(existing:JSONArray,rows:List<Row>,loadField:String,usesDuration:Boolean,usesRir:Boolean,unit:String,nowIso:String):JSONArray {
  fun isRowSet(o:JSONObject)=o.optString("phase","work")=="work"&&o.optString("kind","straight")=="straight"
  val byId=rows.associateBy {it.id}
  fun apply(o:JSONObject,row:Row) {
   o.put("reps",row.reps)
   o.remove("weightKg");o.remove("deficitCm");o.remove("durationSeconds");o.remove("rir")
   if(loadField=="weightKg") row.weightKg?.takeIf {it>0}?.let {o.put("weightKg",it)}
   if(loadField=="deficitCm") row.deficitCm?.takeIf {it>0}?.let {o.put("deficitCm",it)}
   if(usesDuration) row.durationSeconds?.let {o.put("durationSeconds",it)}
   o.put("toFailure",usesRir&&row.rir==0.0)
   if(usesRir) row.rir?.let {o.put("rir",it)}
   o.put("quantityUnit",unit)
  }
  val out=JSONArray();val seen=HashSet<String>()
  for(i in 0 until existing.length()) {
   val o=JSONObject(existing.getJSONObject(i).toString())
   if(!isRowSet(o)) {out.put(o);continue}
   val row=byId[o.optString("id")]?:continue
   seen.add(row.id)
   if(row.reps<=0) continue
   apply(o,row);out.put(o)
  }
  rows.filter {it.id !in seen&&it.reps>0}.forEach {row ->
   val o=JSONObject().put("id",row.id).put("completedAt",nowIso).put("phase","work").put("kind","straight")
    .put("drops",JSONArray()).put("clusters",JSONArray())
   apply(o,row);out.put(o)
  }
  return out
 }

 /**
  * Apple persistActiveLiveDraft on the state JSON: planned + recorded sets of ONE exercise of ONE session. The target is the
  * session id and exercise index the rows were edited on, never "the current exercise": after navigation or when the session
  * ended or changed it returns null and touches nothing. true = something changed (caller saves).
  */
 fun applyRows(state:JSONObject,sessionId:String,exerciseIndex:Int,rows:List<Row>,quantityUnit:String?,nowIso:String,
  modeOf:(JSONObject)->dev.repera.domain.ExerciseInputMode):Boolean? {
  val session=state.optJSONObject("activeSession")?.takeIf {it.optString("id")==sessionId}?:return null
  val ex=session.optJSONArray("exercises")?:return null
  if(exerciseIndex !in 0 until ex.length()) return null
  val exercise=ex.getJSONObject(exerciseIndex)
  // R5 P1-4: iOS PlayEditableSetsView también persiste series en bloques WOD.
  val mode=modeOf(exercise.getJSONObject("exercise"))
  val loadField=when {mode==dev.repera.domain.ExerciseInputMode.HSPU_DEFICIT->"deficitCm";mode.showsWeight->"weightKg";else->"none"}
  val usesDuration=mode in setOf(dev.repera.domain.ExerciseInputMode.MACHINE_WORK,dev.repera.domain.ExerciseInputMode.REPS_AND_TIME,dev.repera.domain.ExerciseInputMode.LOAD_DISTANCE)
  val usesRir=mode !in setOf(dev.repera.domain.ExerciseInputMode.MACHINE_WORK,dev.repera.domain.ExerciseInputMode.REPS_AND_TIME)
  val unit=quantityUnit?.takeIf {it in setOf("reps","calories","meters")}
   ?:exercise.optString("quantityUnit").takeIf {it in setOf("reps","calories","meters")}?:"reps"
  val planned=revise(exercise.optJSONArray("plannedSets")?:JSONArray(),rows,loadField)
  val recorded=recorded(exercise.optJSONArray("loggedSets")?:JSONArray(),rows,loadField,usesDuration,usesRir,unit,nowIso)
  val id=exercise.getString("id")
  val a=update(session,id,planned,if(mode==dev.repera.domain.ExerciseInputMode.MACHINE_WORK) unit else quantityUnit)
  val b=replaceRecordedSets(session,id,recorded)
  return a||b
 }
}
