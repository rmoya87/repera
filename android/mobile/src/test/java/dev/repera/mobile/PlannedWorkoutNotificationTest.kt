package dev.repera.mobile
import android.app.Notification
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
@RunWith(RobolectricTestRunner::class)
@Config(sdk=[35])
class PlannedWorkoutNotificationTest {
 @Test fun platformChronometerAndReopenUseActualStartAndBoundIdentity() {
  val context=ApplicationProvider.getApplicationContext<android.content.Context>()
  val status=PlannedWorkoutStatus("session","Fuerza","Press",1793124000000L,"2/2",3)
  val notification=PlannedWorkoutNotification.build(context,"fixture-owner","revision",status)
  assertEquals(status.startedEpochMillis,notification.`when`)
  assertTrue(notification.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
  assertEquals("Fuerza",notification.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
  assertEquals("Press",notification.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
  assertEquals("Ejercicio 2/2 · 3 series",notification.extras.getCharSequence(Notification.EXTRA_SUB_TEXT).toString())
  val intent=shadowOf(notification.contentIntent).savedIntent
  assertEquals("workout",intent.data!!.host)
  assertEquals("session",intent.getStringExtra("plannedSession"))
  assertEquals("revision",intent.getStringExtra("plannedRevision"))
  assertEquals("fixture-owner",intent.getStringExtra("plannedOwner"))
  val other=PlannedWorkoutNotification.build(context,"fixture-owner","new-login",status)
  assertNotEquals(notification.contentIntent,other.contentIntent)
 }
}
