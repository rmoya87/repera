package dev.repera.mobile

import org.json.JSONObject
import java.time.Instant

/** Lock-screen presentation from persisted active session, never guessed metrics. */
internal data class PlannedWorkoutStatus(
    val sessionId:String,val title:String,val exercise:String,val startedEpochMillis:Long,
    val exerciseProgress:String,val completedSets:Int
) {
    companion object {
        fun fromState(state:JSONObject):PlannedWorkoutStatus? {
            val session=state.optJSONObject("activeSession") ?: return null
            if(session.has("finishedAt") && !session.isNull("finishedAt")) return null
            val id=session.optString("id").takeIf {it.isNotBlank()} ?: return null
            val start=runCatching {Instant.parse(session.getString("startedAt")).toEpochMilli()}.getOrNull() ?: return null
            val entries=session.optJSONArray("exercises") ?: return null
            val current=session.optInt("currentIndex",0)
            val entry=entries.optJSONObject(current)
            val exercise=entry?.optString("blockHeader")?.takeIf {it.isNotBlank()}
                ?:entry?.optJSONObject("exercise")?.optString("name")?.takeIf {it.isNotBlank()}
                ?:"Entrenamiento programado"
            val sets=(0 until entries.length()).sumOf {entries.optJSONObject(it)?.optJSONArray("loggedSets")?.length() ?: 0}
            return PlannedWorkoutStatus(id,session.optString("title").ifBlank {"Entrenamiento"},exercise,start,
                if(entries.length()>0) "${(current+1).coerceIn(1,entries.length())}/${entries.length()}" else "—",sets)
        }
    }
}
