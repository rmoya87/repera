package dev.repera.wear
import androidx.test.core.app.ActivityScenario
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Assert.*
import org.junit.Test
/** Synthetic local fixture. No authenticated phone/Health data is used. */
class WearSignOutInstrumentedTest {
 @Test fun signOutEventClearsPlanEvenBeforeSeparatePlanDeletionArrives() {
  val context=InstrumentationRegistry.getInstrumentation().targetContext
  val prefs=context.getSharedPreferences("repera.wear.session",0)
  assertTrue("Fresh isolated watch app required",prefs.all.isEmpty())
  assertEquals("Fresh isolated watch outbox required",0,WearPendingSetStore(context).count())
  assertNull("Fresh isolated finish outbox required",WearPendingFinishStore(context).sessionId())
  prefs.edit().clear().putString("todayPlan",JSONObject().put("id","fixture").put("title","Fixture plan").toString()).commit()
  ActivityScenario.launch(WearMainActivity::class.java).use {scenario ->
   scenario.onActivity {activity ->
    val method=WearMainActivity::class.java.getDeclaredMethod("showSession",ByteArray::class.java,Boolean::class.javaPrimitiveType,ByteArray::class.java)
    method.isAccessible=true;method.invoke(activity,null,true,null)
    assertNull(prefs.getString("todayPlan",null))
    val plan=WearMainActivity::class.java.getDeclaredField("todayPlanJson\$delegate").apply {isAccessible=true}
     .get(activity) as androidx.compose.runtime.State<*>
    assertNull(plan.value)
   }
  }
 }
}
