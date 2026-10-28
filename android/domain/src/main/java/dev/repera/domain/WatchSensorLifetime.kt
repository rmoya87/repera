package dev.repera.domain

/** A callback can run before a suspended start returns. Keep ownership until it settles. */
object WatchSensorLifetime {
    fun mayRetire(starting:Boolean,terminal:Boolean):Boolean =
        !starting && terminal
}
