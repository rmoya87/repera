package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class HistoricalRelinkTransactionTest {
    private fun source(): ByteArray {
        val official=JSONObject().put("id","official").put("name","Toes to bar")
        val snap=JSONObject().put("id","old").put("name","T2B")
        return JSONObject().put("exercises",JSONArray().put(official))
            .put("workouts",JSONArray().put(JSONObject().put("date","unchanged").put("exercises",
                JSONArray().put(JSONObject().put("exercise",snap).put("results","untouched")))))
            .toString().toByteArray()
    }
    private class Memory(var bytes: ByteArray): HistoricalRelinkTransaction.Store {
        var backupBytes: ByteArray?=null
        var calls=mutableListOf<String>()
        var failBackup=false
        var raceAfterBackup=false
        override fun read()=bytes.copyOf()
        override fun backup(accountId:String,digest:String,bytes:ByteArray):String {
            calls.add("backup")
            check(!failBackup)
            assertEquals(64,digest.length)
            backupBytes=bytes.copyOf()
            if(raceAfterBackup) this.bytes="new training write".toByteArray()
            return "memory-backup"
        }
        override fun compareAndSwap(expected:ByteArray,replacement:ByteArray):Boolean {
            calls.add("cas")
            if(!bytes.contentEquals(expected)) return false
            bytes=replacement.copyOf(); return true
        }
    }
    @Test fun backupPrecedesWriteAndRollbackRestoresExactOriginalBytes() {
        val original=source();val store=Memory(original.copyOf())
        val plan=HistoricalRelinkTransaction.prepare("account",original)!!
        val applied=HistoricalRelinkTransaction.apply(plan,"account",store)!!
        assertEquals(listOf("backup","cas"),store.calls)
        assertArrayEquals(original,store.backupBytes)
        assertEquals(1,plan.changeCount)
        assertTrue(HistoricalRelinkTransaction.rollback(applied,"account",store))
        assertArrayEquals(original,store.bytes)
    }
    @Test fun concurrentWriteAfterBackupCannotBeOverwritten() {
        val store=Memory(source()).apply {raceAfterBackup=true}
        val plan=HistoricalRelinkTransaction.prepare("account",store.bytes)!!
        assertNull(HistoricalRelinkTransaction.apply(plan,"account",store))
        assertEquals("new training write",String(store.bytes))
    }
    @Test fun rollbackRefusesLaterTrainingAndAccountSwitch() {
        val store=Memory(source());val plan=HistoricalRelinkTransaction.prepare("account",store.bytes)!!
        val applied=HistoricalRelinkTransaction.apply(plan,"account",store)!!
        assertFalse(HistoricalRelinkTransaction.rollback(applied,"other",store))
        store.bytes="later training".toByteArray()
        assertFalse(HistoricalRelinkTransaction.rollback(applied,"account",store))
        assertEquals("later training",String(store.bytes))
    }
    @Test fun failedBackupAndWrongAccountNeverWrite() {
        val original=source();val store=Memory(original).apply {failBackup=true}
        val plan=HistoricalRelinkTransaction.prepare("account",original)!!
        assertNull(HistoricalRelinkTransaction.apply(plan,"other",store));assertTrue(store.calls.isEmpty())
        assertTrue(runCatching {HistoricalRelinkTransaction.apply(plan,"account",store)}.isFailure)
        assertArrayEquals(original,store.bytes);assertEquals(listOf("backup"),store.calls)
    }
    @Test fun activeSessionAndNoChangeNeverProducePlan() {
        val active=JSONObject(String(source())).put("activeSession",JSONObject().put("id","live"))
        assertNull(HistoricalRelinkTransaction.prepare("account",active.toString().toByteArray()))
        assertNull(HistoricalRelinkTransaction.prepare("account",JSONObject().toString().toByteArray()))
    }
    @Test fun planDefendsAgainstMutableByteArraysAndStaleSnapshots() {
        val original=source();val store=Memory(original.copyOf())
        val plan=HistoricalRelinkTransaction.prepare("account",original)!!
        original[0]=0;val copy=plan.original();copy[0]=1
        assertEquals('{'.code.toByte(),plan.original()[0])
        store.bytes="changed before backup".toByteArray()
        assertNull(HistoricalRelinkTransaction.apply(plan,"account",store));assertTrue(store.calls.isEmpty())
    }
}
