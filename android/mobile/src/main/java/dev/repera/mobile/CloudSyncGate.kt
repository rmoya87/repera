package dev.repera.mobile

import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/** Drive replacement and mirror recovery must not overlap between check and apply. */
object CloudSyncGate {
    private val running = AtomicInteger(0)
    private val exclusion = ReentrantLock(true)
    fun isDriveSyncRunning(): Boolean = running.get() > 0
    fun <T> driveSync(block: () -> T): T {
        running.incrementAndGet()
        try { return exclusion.withLock(block) } finally { running.decrementAndGet() }
    }
    /** Skip rather than block a mirror while Drive is active or waiting. */
    fun <T> recoverUnlessDrive(block:()->T):T? {
        if(isDriveSyncRunning() || !exclusion.tryLock()) return null
        try {
            if(isDriveSyncRunning()) return null
            return block()
        } finally {exclusion.unlock()}
    }
}
