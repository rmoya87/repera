package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class StandaloneTimerStoreConfigTest {
    @Test
    fun lastConfigurationRoundTripAndPendingCompletion() {
        val ctx = RuntimeEnvironment.getApplication()
        val store = StandaloneTimerStore(ctx)
        assertNull(store.loadLastConfiguration())
        val config = StandaloneTimerConfig(
            mode = StandaloneTimerMode.DOWN,
            durationMinutes = 12,
            durationSeconds = 30,
            countdownBeforeStart = false
        )
        store.saveLastConfiguration(config)
        val reopened = StandaloneTimerStore(ctx).loadLastConfiguration()
        assertEquals(StandaloneTimerMode.DOWN, reopened!!.mode)
        assertEquals(12, reopened.durationMinutes)
        assertEquals(30, reopened.durationSeconds)
        assertEquals(false, reopened.countdownBeforeStart)

        val pending = StandaloneTimerCompletion(
            id = "t1",
            startedAtMillis = 1_000L,
            finishedAtMillis = 1_000L + config.configuredDurationSeconds * 1000L,
            config = config
        )
        store.savePendingCompletion(pending)
        val loaded = StandaloneTimerStore(ctx).loadPendingCompletion()
        assertEquals("t1", loaded!!.id)
        assertEquals(config.configuredDurationSeconds, loaded.configuredSeconds)
        store.clearPendingCompletion()
        assertNull(StandaloneTimerStore(ctx).loadPendingCompletion())
    }
}
