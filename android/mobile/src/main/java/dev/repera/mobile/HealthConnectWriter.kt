package dev.repera.mobile

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseRoute
import androidx.health.connect.client.records.ExerciseRouteResult
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.units.Length
import androidx.health.connect.client.records.metadata.Metadata
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
class HealthConnectWriter(private val context: Context,private val stillAuthorized:()->Boolean = {true}) {

    /** Devuelve el id del registro de Salud vinculado o null si no hubo
     *  escritura/vínculo (sin permiso, no disponible o fallo). */
    suspend fun syncFinishedSession(
        sessionId: String,
        title: String,
        startEpochMs: Long,
        endEpochMs: Long,
        storedRecordId: String?,
        exerciseType: Int = ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING,
        routePoints: List<dev.repera.domain.WorkoutRoutePoint> = emptyList()
    ): String? {
        if (!stillAuthorized() || !HealthConnectReader(context).available() || endEpochMs <= startEpochMs) return null
        val client = HealthConnectClient.getOrCreate(context)
        val granted = runCatching { client.permissionController.getGrantedPermissions() }
            .getOrNull() ?: return null
        if (!stillAuthorized()) return null
        return runCatching {
            val start = Instant.ofEpochMilli(startEpochMs)
            val end = Instant.ofEpochMilli(endEpochMs)
            var candidates: List<SessionHealthMatcher.CandidateSession> = emptyList()
            if (granted.contains(HealthPermission.getReadPermission(ExerciseSessionRecord::class))) {
                val lo = start.minusMillis(SessionHealthMatcher.QUERY_SLACK_MS)
                val hi = end.plusMillis(SessionHealthMatcher.QUERY_SLACK_MS)
                val response = client.readAllRecords(
                    ExerciseSessionRecord::class, TimeRangeFilter.between(lo, hi))
                candidates = response.map {
                    SessionHealthMatcher.CandidateSession(
                        id = it.metadata.id,
                        startEpochMs = it.startTime.toEpochMilli(),
                        endEpochMs = it.endTime.toEpochMilli(),
                        packageName = it.metadata.dataOrigin.packageName,
                        clientRecordId = it.metadata.clientRecordId
                    )
                }
            }
            // Decisión de vínculo en dominio puro (SessionHealthMatcher.resolveLink):
            // el vínculo persistido solo se reusa si pertenece a ESTA sesión y el
            // registro sigue válido; la ambigüedad se excluye ANTES de insertar.
            if(!stillAuthorized()) return null
            when (val decision = SessionHealthMatcher.resolveLink(
                sessionId, startEpochMs, endEpochMs, storedRecordId,
                candidates, context.packageName)) {
                is SessionHealthMatcher.LinkDecision.UseExisting -> {
                    // Apple 435f6992 attachRecordedRouteIfNeeded: tras vincular,
                    // el recorrido grabado por Repera se adjunta SOLO a un
                    // registro PROPIO de ESTA sesion (nunca a rutas de Watch u
                    // otras apps), una sola vez, y sin perder la ruta local si
                    // falta permiso.
                    attachRecordedRouteIfNeeded(client, granted, decision.recordId,
                        sessionId, routePoints, candidates)
                    return decision.recordId
                }
                SessionHealthMatcher.LinkDecision.Skip -> return null
                SessionHealthMatcher.LinkDecision.Insert -> Unit
            }
            // Reading/adopting a genuine external workout does not require permission to write.
            if(!granted.contains(HealthPermission.getWritePermission(ExerciseSessionRecord::class))) return null
            // Escritura idempotente (mismo clientRecordId ⇒ actualiza).
            val zone = ZoneId.systemDefault().rules.getOffset(start)
            val record = ExerciseSessionRecord(
                startTime = start,
                startZoneOffset = zone,
                endTime = end,
                endZoneOffset = ZoneId.systemDefault().rules.getOffset(end),
                exerciseType = exerciseType,
                title = title,
                metadata = Metadata.manualEntry(
                    device = null,
                    clientRecordId = HealthSessionLink.clientRecordId(sessionId),
                    clientRecordVersion = 0
                ),
                // Apple 435f6992/c7e73a35: el track GPS propio se exporta con la
                // sesion (exige WRITE_EXERCISE_ROUTE; sin permiso, sin ruta y el
                // GPX local se mantiene).
                exerciseRoute = routeFor(granted, routePoints, startEpochMs, endEpochMs)
            )
            if(!stillAuthorized()) return null
            client.insertRecords(listOf(record)).recordIdsList.firstOrNull()
        }.getOrNull()
    }

    /** ExerciseRoute con los puntos exportables del track grabado, o null sin
     *  permiso WRITE_EXERCISE_ROUTE / sin >=2 puntos validos. */
    private fun routeFor(
        granted: Set<String>,
        points: List<dev.repera.domain.WorkoutRoutePoint>,
        startEpochMs: Long,
        endEpochMs: Long
    ): ExerciseRoute? {
        if (!granted.contains(HealthPermission.PERMISSION_WRITE_EXERCISE_ROUTE))
            return null
        // Ventana Apple ±60s + recorte EXACTO [start,end], monotono sin
        // duplicados: HC rechaza la ruta fuera del rango de la sesion.
        val exportable = dev.repera.domain.RouteHealthExport.healthConnectRoutePoints(
            points, startEpochMs, endEpochMs)
        if (exportable.isEmpty()) return null
        return ExerciseRoute(exportable.map { p ->
            ExerciseRoute.Location(
                time = Instant.ofEpochMilli(p.recordedAtEpochMs),
                latitude = p.latitude,
                longitude = p.longitude,
                horizontalAccuracy = p.horizontalAccuracyMeters?.let { Length.meters(it) },
                verticalAccuracy = p.verticalAccuracyMeters?.let { Length.meters(it) },
                altitude = p.altitudeMeters?.let { Length.meters(it) }
            )
        })
    }

    /** Adjunta la ruta grabada al registro PROPIO ya vinculado si aun no tiene
     *  ruta (idempotente: Salud es la fuente de verdad de la ruta; una ruta ya
     *  presente jamas se sobrescribe). */
    private suspend fun attachRecordedRouteIfNeeded(
        client: HealthConnectClient,
        granted: Set<String>,
        recordId: String,
        sessionId: String,
        routePoints: List<dev.repera.domain.WorkoutRoutePoint>,
        candidates: List<SessionHealthMatcher.CandidateSession>
    ) {
        if (routePoints.size < 2) return
        if (!granted.contains(HealthPermission.PERMISSION_WRITE_EXERCISE_ROUTE)) return
        if (!granted.contains(HealthPermission.getReadPermission(ExerciseSessionRecord::class))) return
        val own = candidates.firstOrNull {
            it.id == recordId && it.packageName == context.packageName &&
                it.clientRecordId == HealthSessionLink.clientRecordId(sessionId)
        } ?: return
        runCatching {
            val existing = client.readRecord(ExerciseSessionRecord::class, own.id).record
            val alreadyHasRoute = (existing.exerciseRouteResult as? ExerciseRouteResult.Data)
                ?.exerciseRoute?.route?.isNotEmpty() == true
            if (alreadyHasRoute) return@runCatching
            val route = routeFor(granted, routePoints,
                existing.startTime.toEpochMilli(), existing.endTime.toEpochMilli())
            if (route == null) return@runCatching
            val updated = ExerciseSessionRecord(
                startTime = existing.startTime,
                startZoneOffset = existing.startZoneOffset,
                endTime = existing.endTime,
                endZoneOffset = existing.endZoneOffset,
                exerciseType = existing.exerciseType,
                title = existing.title,
                metadata = Metadata.manualEntry(
                    device = null,
                    clientRecordId = HealthSessionLink.clientRecordId(sessionId),
                    clientRecordVersion = existing.metadata.clientRecordVersion + 1
                ),
                exerciseRoute = route
            )
            client.insertRecords(listOf(updated))
        }
    }

    companion object {
        /** Tipo Health Connect de la sesión (Apple workoutHealthType: el deporte de «Comenzar» manda; el resto es
         *  fuerza). Health Connect no tiene tipo propio para CrossFit, core, pickleball, pádel, kickboxing, lucha ni
         *  lacrosse: se usa el más cercano (aproximación, no equivalencia verificada con Apple). */
        fun exerciseTypeFor(sport: dev.repera.domain.LiveSport?): Int {
            return when (sport) {
                null -> ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING
                dev.repera.domain.LiveSport.RUNNING, dev.repera.domain.LiveSport.TRAIL -> ExerciseSessionRecord.EXERCISE_TYPE_RUNNING
                dev.repera.domain.LiveSport.CYCLING, dev.repera.domain.LiveSport.MOUNTAIN_BIKE, dev.repera.domain.LiveSport.GRAVEL -> ExerciseSessionRecord.EXERCISE_TYPE_BIKING
                dev.repera.domain.LiveSport.WALKING -> ExerciseSessionRecord.EXERCISE_TYPE_WALKING
                dev.repera.domain.LiveSport.HIKING -> ExerciseSessionRecord.EXERCISE_TYPE_HIKING
                dev.repera.domain.LiveSport.CROSSFIT, dev.repera.domain.LiveSport.HYROX, dev.repera.domain.LiveSport.HIIT ->
                    ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING
                dev.repera.domain.LiveSport.STRENGTH -> ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING
                dev.repera.domain.LiveSport.FUNCTIONAL_STRENGTH, dev.repera.domain.LiveSport.CORE_TRAINING -> ExerciseSessionRecord.EXERCISE_TYPE_CALISTHENICS
                dev.repera.domain.LiveSport.ELLIPTICAL -> ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL
                dev.repera.domain.LiveSport.STAIR_CLIMBING -> ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING
                dev.repera.domain.LiveSport.TENNIS, dev.repera.domain.LiveSport.PADEL, dev.repera.domain.LiveSport.PICKLEBALL -> ExerciseSessionRecord.EXERCISE_TYPE_TENNIS
                dev.repera.domain.LiveSport.BADMINTON -> ExerciseSessionRecord.EXERCISE_TYPE_BADMINTON
                dev.repera.domain.LiveSport.SQUASH -> ExerciseSessionRecord.EXERCISE_TYPE_SQUASH
                dev.repera.domain.LiveSport.SURFING, dev.repera.domain.LiveSport.WINDSURFING, dev.repera.domain.LiveSport.KITESURFING -> ExerciseSessionRecord.EXERCISE_TYPE_SURFING
                dev.repera.domain.LiveSport.SWIMMING -> ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL
                dev.repera.domain.LiveSport.KAYAKING, dev.repera.domain.LiveSport.CANOEING -> ExerciseSessionRecord.EXERCISE_TYPE_PADDLING
                dev.repera.domain.LiveSport.ROWING -> ExerciseSessionRecord.EXERCISE_TYPE_ROWING
                dev.repera.domain.LiveSport.SAILING -> ExerciseSessionRecord.EXERCISE_TYPE_SAILING
                dev.repera.domain.LiveSport.GOLF -> ExerciseSessionRecord.EXERCISE_TYPE_GOLF
                dev.repera.domain.LiveSport.SKIING, dev.repera.domain.LiveSport.CROSS_COUNTRY_SKIING -> ExerciseSessionRecord.EXERCISE_TYPE_SKIING
                dev.repera.domain.LiveSport.ICE_SKATING, dev.repera.domain.LiveSport.SKATEBOARDING -> ExerciseSessionRecord.EXERCISE_TYPE_SKATING
                dev.repera.domain.LiveSport.SNOWBOARDING -> ExerciseSessionRecord.EXERCISE_TYPE_SNOWBOARDING
                dev.repera.domain.LiveSport.SOCCER -> ExerciseSessionRecord.EXERCISE_TYPE_SOCCER
                dev.repera.domain.LiveSport.BASKETBALL -> ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL
                dev.repera.domain.LiveSport.VOLLEYBALL -> ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL
                dev.repera.domain.LiveSport.AMERICAN_FOOTBALL -> ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AMERICAN
                dev.repera.domain.LiveSport.BASEBALL -> ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL
                dev.repera.domain.LiveSport.SOFTBALL -> ExerciseSessionRecord.EXERCISE_TYPE_SOFTBALL
                dev.repera.domain.LiveSport.HOCKEY -> ExerciseSessionRecord.EXERCISE_TYPE_ICE_HOCKEY
                dev.repera.domain.LiveSport.RUGBY -> ExerciseSessionRecord.EXERCISE_TYPE_RUGBY
                dev.repera.domain.LiveSport.BOXING -> ExerciseSessionRecord.EXERCISE_TYPE_BOXING
                dev.repera.domain.LiveSport.KICKBOXING, dev.repera.domain.LiveSport.MARTIAL_ARTS, dev.repera.domain.LiveSport.WRESTLING ->
                    ExerciseSessionRecord.EXERCISE_TYPE_MARTIAL_ARTS
                dev.repera.domain.LiveSport.CLIMBING -> ExerciseSessionRecord.EXERCISE_TYPE_ROCK_CLIMBING
                dev.repera.domain.LiveSport.DANCE -> ExerciseSessionRecord.EXERCISE_TYPE_DANCING
                dev.repera.domain.LiveSport.PILATES -> ExerciseSessionRecord.EXERCISE_TYPE_PILATES
                dev.repera.domain.LiveSport.YOGA -> ExerciseSessionRecord.EXERCISE_TYPE_YOGA
                dev.repera.domain.LiveSport.MOBILITY -> ExerciseSessionRecord.EXERCISE_TYPE_STRETCHING
                dev.repera.domain.LiveSport.LACROSSE, dev.repera.domain.LiveSport.OTHER -> ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT
            }
        }
    }
}
