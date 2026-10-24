package dev.repera.mobile

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import dev.repera.domain.HealthSessionLink
import dev.repera.domain.SessionHealthMatcher
import java.time.Instant
import java.time.ZoneId

/** Escritura de la sesión propia en Health Connect
 *  (HealthKitStore.finishWorkout / syncWorkoutToHealth iOS).
 *
 *  Contrato portado:
 *  - Si la sesión ya tiene vínculo persistido y el registro existe, se reusa.
 *  - Si existe un registro PROPIO con el mismo clientRecordId, se adopta su
 *    id (idempotencia entre reinstalaciones del vínculo local).
 *  - Si hay UNA sesión externa inequívoca en ventana (reglas
 *    SessionHealthMatcher = overlappingWorkout iOS), se adopta como vínculo
 *    y NO se escribe nada (un registro real de reloj manda).
 *  - Si no, con permiso de escritura se inserta ExerciseSessionRecord con
 *    clientRecordId estable (reintentos actualizan, no duplican).
 *  - Sin permiso/disponibilidad: devuelve null y el entreno queda intacto
 *    en local (iOS: "guardar únicamente en Repera").
 *  - NUNCA se escriben kcal ni FC para crear el vínculo. */
class HealthConnectWriter(private val context: Context) {

    /** Devuelve el id del registro de Salud vinculado o null si no hubo
     *  escritura/vínculo (sin permiso, no disponible o fallo). */
    suspend fun syncFinishedSession(
        sessionId: String,
        title: String,
        startEpochMs: Long,
        endEpochMs: Long,
        storedRecordId: String?
    ): String? {
        if (!HealthConnectReader(context).available() || endEpochMs <= startEpochMs) return null
        val client = HealthConnectClient.getOrCreate(context)
        val granted = runCatching { client.permissionController.getGrantedPermissions() }
            .getOrNull() ?: return null
        if (!granted.contains(HealthPermission.getWritePermission(ExerciseSessionRecord::class)))
            return null
        return runCatching {
            val start = Instant.ofEpochMilli(startEpochMs)
            val end = Instant.ofEpochMilli(endEpochMs)
            var candidates: List<SessionHealthMatcher.CandidateSession> = emptyList()
            var ownByClientId: String? = null
            if (granted.contains(HealthPermission.getReadPermission(ExerciseSessionRecord::class))) {
                val lo = start.minusMillis(SessionHealthMatcher.QUERY_SLACK_MS)
                val hi = end.plusMillis(SessionHealthMatcher.QUERY_SLACK_MS)
                val response = client.readRecords(ReadRecordsRequest(
                    ExerciseSessionRecord::class, TimeRangeFilter.between(lo, hi)))
                candidates = response.records.map {
                    SessionHealthMatcher.CandidateSession(
                        id = it.metadata.id,
                        startEpochMs = it.startTime.toEpochMilli(),
                        endEpochMs = it.endTime.toEpochMilli(),
                        packageName = it.metadata.dataOrigin.packageName
                    )
                }
                val wantedClientId = HealthSessionLink.clientRecordId(sessionId)
                ownByClientId = response.records.firstOrNull {
                    it.metadata.dataOrigin.packageName == context.packageName &&
                        it.metadata.clientRecordId == wantedClientId
                }?.metadata?.id
            }
            // 1) Vínculo persistido que sigue existiendo.
            SessionHealthMatcher.matchById(candidates, storedRecordId)?.let { return it.id }
            // 2) Registro propio con el clientRecordId de esta sesión.
            ownByClientId?.let { return it }
            // 3) Una única sesión EXTERNA inequívoca: se adopta, no se escribe.
            val association = SessionHealthMatcher.associate(
                startEpochMs, endEpochMs, candidates, context.packageName)
            if (association is SessionHealthMatcher.Association.Matched &&
                association.session.packageName != context.packageName) {
                return association.session.id
            }
            if (association == SessionHealthMatcher.Association.Ambiguous) return null
            // 4) Escritura idempotente (mismo clientRecordId ⇒ actualiza).
            val zone = ZoneId.systemDefault().rules.getOffset(start)
            val record = ExerciseSessionRecord(
                startTime = start,
                startZoneOffset = zone,
                endTime = end,
                endZoneOffset = zone,
                exerciseType = ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING,
                title = title,
                metadata = Metadata.manualEntry(
                    device = null,
                    clientRecordId = HealthSessionLink.clientRecordId(sessionId),
                    clientRecordVersion = 0
                )
            )
            client.insertRecords(listOf(record)).recordIdsList.firstOrNull()
        }.getOrNull()
    }
}
