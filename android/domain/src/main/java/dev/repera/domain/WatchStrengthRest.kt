package dev.repera.domain

/** WatchSessionHub.confirmSet differs from the phone's special-technique rest policy. */
object WatchStrengthRest {
    fun afterConfirmedSet(defaultSeconds:Int,warmup:Boolean,completedWorkSets:Int,plannedWorkSets:Int):Int =
        if(!warmup && completedWorkSets<plannedWorkSets) maxOf(0,defaultSeconds) else 0
}
