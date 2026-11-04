package dev.repera.wear

import dev.repera.domain.WatchQuantityPolicy

/** The accelerometer is registered only while reps can actually be counted. */
internal object WearMotionPolicy {
    fun shouldCount(
        session: WatchSessionSummary?,
        paused: Boolean,
        restRemaining: Int,
        started: Boolean
    ): Boolean = started && session != null && session.phase == "counting" &&
        session.canLogOnWatch && WatchQuantityPolicy.usesMotion(session.inputMode) &&
        session.wodFormatLabel == null && !paused && restRemaining <= 0
}
