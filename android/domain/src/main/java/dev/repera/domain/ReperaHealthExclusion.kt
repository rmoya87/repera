package dev.repera.domain

/** Literal HealthKitStore.matchesReperaSession: UUID or ONE >=40% local overlap.
 * Distinct from the stricter matcher used to refine a session's measurements. */
object ReperaHealthExclusion {
    data class Window(val startMillis:Long,val endMillis:Long,val linkedHealthId:String?=null)
    fun matches(healthStart:Long,healthEnd:Long,healthId:String,windows:List<Window>):Boolean {
        if(windows.any {it.linkedHealthId==healthId}) return true
        var hits=0
        val slack=45*60_000L
        for(w in windows) {
            val duration=maxOf(60_000L,w.endMillis-w.startMillis)
            val overlap=maxOf(0L,minOf(healthEnd,w.endMillis)-maxOf(healthStart,w.startMillis))
            if(overlap<duration*0.4) continue
            if(healthStart>=w.endMillis+slack || healthEnd<=w.startMillis-slack) continue
            if(++hits>1) return false
        }
        return hits==1
    }
}
