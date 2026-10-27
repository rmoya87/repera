package dev.repera.domain

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

/** A prescription is not an execution. Start time and identity belong to the watch tap. */
object WatchPlanExecution {
    /** Apple SessionController.selectExercise(at:): jump without completing skipped work or creating sets.
     *  Null when out of range or already the current exercise in `ready` (Apple WatchSessionHub no-op). */
    fun select(session:JSONObject,index:Int):JSONObject? {
        val count=session.optJSONArray("exercises")?.length() ?: return null
        if(index !in 0 until count) return null
        if(session.optInt("currentIndex",-1)==index && session.optString("phase")=="ready") return null
        return JSONObject(session.toString()).put("currentIndex",index).put("phase","ready")
    }

    fun begin(plan:JSONObject,id:String=UUID.randomUUID().toString(),at:Instant=Instant.now()):JSONObject {
        require(id.isNotBlank() && id!=plan.optString("id"))
        val copy=JSONObject(plan.toString())
        val exercises=copy.getJSONArray("exercises")
        require(exercises.length()>0)
        for(i in 0 until exercises.length()) {
            val exercise=exercises.getJSONObject(i)
            require((exercise.optJSONArray("loggedSets")?.length() ?: 0)==0) {"El plan contiene trabajo ya registrado"}
            exercise.put("loggedSets",JSONArray()).put("isCompleted",false).put("completedReps",0)
        }
        copy.put("id",id).put("startedAt",at.toString()).put("phase","counting")
            .put("currentIndex",0).put("wodResults",JSONArray()).put("routePoints",JSONArray())
        copy.remove("finishedAt");copy.remove("draftRequestId")
        return copy
    }
}
