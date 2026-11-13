package dev.repera.mobile
import org.json.JSONObject

data class WodLibraryResult(
    val id:String,val templateId:String,val elapsedSeconds:Int?,
    val totalReps:Int?,val rounds:Int?,val format:String?,
    val measuredValue:Double?=null,val measuredMetric:String?=null,
    val phaseReps:Int?=null,val phaseCount:Int=0,
    val athleteOneReps:Int?=null,val athleteTwoReps:Int?=null
) {
    val summary:String get()=when {
        measuredValue!=null && measuredMetric!=null -> {
            val amount=dev.repera.domain.ReperaNumberFormat.decimal(measuredValue)
            val unit=when(measuredMetric) {
                "loadKg" -> "kg"; "calories" -> "kcal"; "distanceMeters" -> "m"
                else -> measuredMetric
            }
            "$amount $unit"
        }
        elapsedSeconds!=null -> "%d:%02d".format(java.util.Locale.ROOT, elapsedSeconds/60,elapsedSeconds%60)
        rounds!=null && totalReps!=null -> "$rounds rondas + $totalReps reps"
        totalReps!=null -> "$totalReps reps"
        rounds!=null -> "$rounds rondas"
        athleteOneReps!=null || athleteTwoReps!=null ->
            "A1 ${athleteOneReps?:0} · A2 ${athleteTwoReps?:0} reps"
        phaseCount>0 -> "$phaseCount parciales · ${phaseReps?:0} reps"
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
                val phases=r.optJSONArray("phaseResults")
                val partials=(0 until (phases?.length() ?: 0))
                    .map { phases!!.getJSONObject(it) }
                val participants=partials.filter { it.has("participantIndex") }
                fun reps(list:List<JSONObject>)=list.sumOf {it.optInt("completedReps",0)}
                rows.add(WodLibraryResult(
                    r.optString("id"),template,number("elapsedSeconds"),number("totalReps"),
                    number("roundsCompleted"),
                    r.optString("format").takeIf {it.isNotBlank() && it!="null"},
                    r.optDouble("measuredValue").takeIf {r.has("measuredValue") &&
                        !r.isNull("measuredValue") && it.isFinite()},
                    r.optString("measuredMetric").takeIf {it.isNotBlank() && it!="null"},
                    phaseReps=if(partials.isNotEmpty())reps(partials) else null,
                    phaseCount=partials.size,
                    athleteOneReps=if(participants.isNotEmpty())reps(participants.filter {
                        it.optInt("participantIndex")==1}) else null,
                    athleteTwoReps=if(participants.isNotEmpty())reps(participants.filter {
                        it.optInt("participantIndex")==2}) else null
                ))
            }
        }
        return rows.groupBy {it.templateId}.mapValues {(_,group) ->group.sortedWith {a,b ->
            when {
                a.elapsedSeconds!=null && b.elapsedSeconds!=null -> a.elapsedSeconds.compareTo(b.elapsedSeconds)
                a.totalReps!=null && b.totalReps!=null -> b.totalReps.compareTo(a.totalReps)
                a.measuredValue!=null && b.measuredValue!=null &&
                    a.measuredMetric==b.measuredMetric -> b.measuredValue.compareTo(a.measuredValue)
                else -> 0
            }
        }}
    }
    fun visible(rows:List<WodLibraryResult>,pro:Boolean):List<WodLibraryResult> = if(pro) rows else
        listOfNotNull(rows.firstOrNull(),rows.lastOrNull()?.takeIf {it.id!=rows.firstOrNull()?.id})
}
