package dev.repera.domain

/** Countdown from monotonic time. A delayed tick catches up instead of extending rest. */
class RestCountdown {
    private var deadlineMs:Long?=null
    private var pausedMs=0L
    fun start(seconds:Int,nowMs:Long) {
        require(seconds>=0 && nowMs>=0)
        pausedMs=0
        deadlineMs=nowMs+seconds.toLong()*1000
    }
    fun remainingMillis(nowMs:Long):Long = deadlineMs?.let {(it-nowMs).coerceAtLeast(0)} ?: pausedMs
    fun restore(remainingMillis:Long,paused:Boolean,nowMs:Long) {
        require(remainingMillis in 0L..86400000L && nowMs>=0)
        clear()
        if(paused) pausedMs=remainingMillis else deadlineMs=nowMs+remainingMillis
    }
    fun remainingSeconds(nowMs:Long):Int {
        val millis=remainingMillis(nowMs)
        return ((millis+999)/1000).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    }
    fun pause(nowMs:Long) {
        deadlineMs?.let {pausedMs=(it-nowMs).coerceAtLeast(0)}
        deadlineMs=null
    }
    fun resume(nowMs:Long) {
        if(deadlineMs==null && pausedMs>0) {deadlineMs=nowMs+pausedMs;pausedMs=0}
    }
    fun clear() {deadlineMs=null;pausedMs=0}
}
