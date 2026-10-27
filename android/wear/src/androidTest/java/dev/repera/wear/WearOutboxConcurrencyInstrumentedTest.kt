package dev.repera.wear

import androidx.test.platform.app.InstrumentationRegistry
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.junit.Assert.*
import org.junit.Test

/** Fresh isolated app only. No production phone, sensor or backend activity. */
class WearOutboxConcurrencyInstrumentedTest {
    private val context get()=InstrumentationRegistry.getInstrumentation().targetContext
    @Test fun independentStoresCannotLoseParallelAppendsOrAcknowledgements() {
        val store=WearPendingSetStore(context)
        assertEquals("Fresh isolated outbox required",0,store.count())
        val pool=Executors.newFixedThreadPool(6)
        try {
            val ids=pool.invokeAll((0 until 60).map { Callable {
                WearPendingSetStore(context).append("synthetic",0,5,null)
            } }).map {it.get(20,TimeUnit.SECONDS)}
            assertEquals(60,ids.toSet().size);assertEquals(60,store.count())
            pool.invokeAll(ids.take(30).map {id -> Callable {
                WearPendingSetStore(context).remove(id)
            } }).forEach {it.get(20,TimeUnit.SECONDS)}
            assertEquals(ids.drop(30).toSet(),store.all().map {it.getString("id")}.toSet())
        } finally {pool.shutdownNow();store.clear()}
    }
    @Test fun competingFinishQueuesNeverSilentlyOverwriteAnotherSession() {
        val store=WearPendingFinishStore(context)
        assertNull("Fresh isolated finish outbox required",store.sessionId())
        val pool=Executors.newFixedThreadPool(2)
        try {
            val results=pool.invokeAll(listOf("synthetic-a","synthetic-b").map {id -> Callable {
                runCatching {WearPendingFinishStore(context).queue(id)}.isSuccess
            } }).map {it.get(20,TimeUnit.SECONDS)}
            assertEquals(1,results.count {it})
            assertTrue(store.sessionId() in setOf("synthetic-a","synthetic-b"))
            store.acknowledge("unrelated");assertNotNull(store.sessionId())
        } finally {pool.shutdownNow();store.clear()}
    }
}
