package dev.repera.mobile
import org.json.*
import dev.repera.domain.RotationPlan

internal object RotationSettings {
    fun read(state:JSONObject):RotationPlan? = state.optJSONObject("rotation")?.let { r ->
        val ids=r.optJSONArray("routineIds") ?: JSONArray()
        RotationPlan(r.optString("id"),r.optString("label","Mi rotación"),
            (0 until ids.length()).map { ids.getString(it) },r.optInt("nextIndex",0))
    }
    fun write(state:JSONObject,plan:RotationPlan?) {
        if(plan==null) {state.remove("rotation");return}
        val r=state.optJSONObject("rotation") ?: JSONObject()
        r.put("id",plan.id).put("label",plan.label).put("routineIds",JSONArray(plan.routineIds)).put("nextIndex",plan.nextIndex)
        state.put("rotation",r)
    }
    fun nextRoutineId(state:JSONObject):String? =
        if(state.optJSONObject("settings")?.optString("scheduleMode")=="rotation") read(state)?.nextRoutineId else null
    fun advanceIfNeeded(state:JSONObject,finishedRoutineId:String?) {
        if(state.optJSONObject("settings")?.optString("scheduleMode")!="rotation" || finishedRoutineId==null) return
        val plan=read(state) ?: return
        if(plan.nextRoutineId==finishedRoutineId) write(state,plan.advanced())
    }
}
