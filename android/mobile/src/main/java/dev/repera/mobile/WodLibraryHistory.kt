package dev.repera.mobile
import org.json.JSONObject

data class WodLibraryResult(val id:String,val templateId:String,val elapsedSeconds:Int?,val totalReps:Int?,val rounds:Int?,val format:String?) {
    val summary:String get()=when {
        elapsedSeconds!=null -> "%d:%02d".format(elapsedSeconds/60,elapsedSeconds%60)
        rounds!=null && totalReps!=null -> "$rounds rondas + $totalReps reps"
        totalReps!=null -> "$totalReps reps"
        rounds!=null -> "$rounds rondas"
        else -> "Sin resultado"
    }
}
/** Literal LibraryView ranking; history.last is ranked last, not chronological latest. */
internal object WodLibraryHistory {
    fun read(state:JSONObject):Map<String,List<WodLibraryResult>> {
        val archive=state.optJSONArray("workouts") ?: return emptyMap()
        val rows=mutableListOf<WodLibraryResult>()
        for(i in 0 until archive.length()) {
            val results=archive.getJSONObject(i).optJSONArray("wodResults") ?: continue
            for(j in 0 until results.length()) {
                val r=results.getJSONObject(j)
                val template=r.optString("wodTemplateId").takeIf {it.isNotBlank() && it!="null"} ?: continue
                fun number(key:String)=if(r.has(key) && !r.isNull(key)) r.optInt(key).takeIf {it>=0} else null
                rows.add(WodLibraryResult(r.optString("id"),template,number("elapsedSeconds"),number("totalReps"),number("roundsCompleted"),
                    r.optString("format").takeIf {it.isNotBlank() && it!="null"}))
            }
        }
        return rows.groupBy {it.templateId}.mapValues {(_,group) ->group.sortedWith {a,b ->
            when {
                a.elapsedSeconds!=null && b.elapsedSeconds!=null -> a.elapsedSeconds.compareTo(b.elapsedSeconds)
                a.totalReps!=null && b.totalReps!=null -> b.totalReps.compareTo(a.totalReps)
                else -> 0
            }
        }}
    }
    fun visible(rows:List<WodLibraryResult>,pro:Boolean):List<WodLibraryResult> = if(pro) rows else
        listOfNotNull(rows.firstOrNull(),rows.lastOrNull()?.takeIf {it.id!=rows.firstOrNull()?.id})
}
