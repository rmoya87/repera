package dev.repera.domain

/** Vínculo estable sesión Repera ↔ registro de Salud del propio dispositivo.
 *
 *  Port del contrato de escritura de HealthKitStore.finishWorkout (iOS):
 *  - Idempotencia: el clientRecordId deriva SOLO del id de sesión, así que
 *    reintentar la escritura actualiza el mismo registro en vez de duplicar.
 *  - El id del registro de Health Connect se persiste en la sesión
 *    (healthKitWorkoutUUID iOS) y es la asociación primaria.
 *  - Nunca se escriben kcal ni FC: la señal la aporta el dispositivo que la
 *    midió; Repera solo registra la sesión (tipo fuerza, como iOS). */
object HealthSessionLink {
    /** Campo JSON aditivo en la sesión persistida con el id del registro. */
    const val SNAPSHOT_FIELD = "healthConnectRecordId"

    /** clientRecordId estable por sesión (unicidad por app en Health Connect:
     *  insertar dos veces el mismo clientRecordId actualiza, no duplica). */
    fun clientRecordId(sessionId: String): String = "repera-session-$sessionId"
}
