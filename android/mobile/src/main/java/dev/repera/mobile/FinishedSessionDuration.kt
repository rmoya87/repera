package dev.repera.mobile
import dev.repera.domain.HealthSessionLink
import org.json.JSONObject

/** Apple (live main) ReperaStore.saveWorkout (edición de terminado): la duración solo se deriva
 *  del horario corregido cuando el entreno NO tiene vínculo con Salud ni es captura En vivo.
 *  Con vínculo (healthKitWorkoutUUID / healthConnectRecordId) se preserva la medición original.
 *  Los temporizadores libres usan timerDetails.configuredSeconds (no reloj de pared). */
internal object FinishedSessionDuration {
 fun shouldDeriveFromSchedule(workout:JSONObject):Boolean {
  if (dev.repera.domain.TimerCompletionDetails.fromSession(workout) != null) return false
  val hk=workout.optString("healthKitWorkoutUUID")
  val hc=workout.optString(HealthSessionLink.SNAPSHOT_FIELD)
  val live=workout.optString("liveSportID")
  return hk.isBlank() && hc.isBlank() && (live.isBlank() || live=="null")
 }
}
