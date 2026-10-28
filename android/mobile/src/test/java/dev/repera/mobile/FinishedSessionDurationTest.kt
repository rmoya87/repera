package dev.repera.mobile
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.io.File

class FinishedSessionDurationTest {
 @Test fun noLinkDerivesDuration() {
  assertTrue(FinishedSessionDuration.shouldDeriveFromSchedule(JSONObject()))
 }
 @Test fun healthKitLinkPreservesMeasurement() {
  assertFalse(FinishedSessionDuration.shouldDeriveFromSchedule(JSONObject().put("healthKitWorkoutUUID","hk-1")))
 }
 @Test fun healthConnectLinkPreservesMeasurement() {
  assertFalse(FinishedSessionDuration.shouldDeriveFromSchedule(JSONObject().put("healthConnectRecordId","hc-1")))
 }
 @Test fun liveSportCapturePreservesMeasurement() {
  assertFalse(FinishedSessionDuration.shouldDeriveFromSchedule(JSONObject().put("liveSportID","running")))
  assertTrue(FinishedSessionDuration.shouldDeriveFromSchedule(JSONObject().put("liveSportID","null")))
 }
 @Test fun repositoryEditPathUsesTheGate() {
  val src=File("src/main/java/dev/repera/mobile/WorkoutRepository.kt").readText()
  val body=Regex("fun updateFinishedWorkout\\([\\s\\S]*?attachSessionReview|attachToFinishedSession")
  assertTrue("updateFinishedWorkout debe consultar la puerta de vínculo Salud antes de derivar la duración",
   src.contains("FinishedSessionDuration.shouldDeriveFromSchedule(target)"))
 }
}
