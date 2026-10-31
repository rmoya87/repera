package dev.repera.wear

import androidx.test.core.app.ActivityScenario
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.WatchInputDraft
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

/** Requires a disposable, signed-out app. Never backs up or overwrites private watch data. */
class WearDraftRecoveryInstrumentedTest {
    @Test fun cachedSessionRestoresEditableDraftAndRecreationDoesNotQueueASet() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val prefs=context.getSharedPreferences("repera.wear.session",0)
        assertTrue("Fresh isolated watch app required",prefs.all.isEmpty())
        assertEquals(0,WearPendingSetStore(context).count())
        assertNull(WearPendingFinishStore(context).sessionId())
        val entry=JSONObject().put("exercise",JSONObject().put("id","e")
            .put("name","Sentadilla").put("equipment","Barra"))
            .put("plannedSets",JSONArray()).put("loggedSets",JSONArray())
        val session=JSONObject().put("id","fixture-draft").put("title","Fixture")
            .put("currentIndex",0).put("exercises",JSONArray().put(entry))
        val boot=android.provider.Settings.Global.getInt(context.contentResolver,android.provider.Settings.Global.BOOT_COUNT)
        val rest=dev.repera.domain.WatchRestState("fixture-draft",true,7500,
            android.os.SystemClock.elapsedRealtime(),boot)
        val draft=WatchInputDraft("fixture-draft",1,0,7,40.0,2.0,30,"reps",0,false,false)
        assertTrue(prefs.edit().putString("snapshot",session.toString())
            .putString("inputDraft",draft.encode()).putString("restState",rest.encode())
            .putBoolean("watchStarted",true).commit())
        try {
            ActivityScenario.launch(WearMainActivity::class.java).use { scenario ->
                fun assertDraft() { scenario.onActivity { activity ->
                    fun value(name:String):Any? = (WearMainActivity::class.java
                        .getDeclaredField(name+"\$delegate").apply {isAccessible=true}
                        .get(activity) as androidx.compose.runtime.State<*>).value
                    assertEquals(7,value("repsInput"));assertEquals(40.0,value("weightInput"))
                    assertEquals(2.0,value("rirInput"));assertEquals(true,value("sessionPaused"))
                    assertEquals(8,value("restRemaining"));assertEquals(0,WearPendingSetStore(context).count())
                } }
                assertDraft()
                scenario.onActivity { activity ->
                    activity.testShowSession()
                    assertNotNull(prefs.getString("snapshot",null))
                    assertTrue(prefs.getBoolean("watchStarted",false))
                }
                assertDraft()
                // recreate() en CI queda bloqueado por diálogos del sistema (PAUSED);
                // la persistencia ya quedó cubierta arriba.
            }
        } finally { prefs.edit().clear().commit() }
    }
}
