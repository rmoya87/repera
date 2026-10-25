package dev.repera.mobile

/** HomeView.recordedDayWorkoutMinutes: linked external measurements take priority;
 * a truncated record written by Repera must not replace the full local session. */
object HealthWorkoutMinutes {
    data class Verified(val minutes:Double,val external:Boolean)
    /** Health Connect session duration excludes explicitly recorded pauses. */
    fun measured(start:Long,end:Long,pauses:List<Pair<Long,Long>>):Double {
        if(end<=start) return 0.0
        var covered=0L;var until=start
        for((a,b) in pauses.sortedBy {it.first}) {
            val lo=maxOf(start,a,until);val hi=minOf(end,b)
            if(hi>lo) {covered+=hi-lo;until=hi}
        }
        return maxOf(0L,end-start-covered)/60000.0
    }
    fun resolve(logged:Double,verified:Verified?):Double {
        val local=maxOf(0.0,logged)
        if(verified==null || !verified.minutes.isFinite() || verified.minutes<=0) return local
        return if(verified.external || kotlin.math.abs(verified.minutes-local)<=maxOf(5.0,local*0.25)) verified.minutes else local
    }
}
