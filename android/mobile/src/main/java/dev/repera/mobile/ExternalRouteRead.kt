package dev.repera.mobile

import androidx.health.connect.client.records.ExerciseRoute
import dev.repera.domain.WorkoutRoutePoint

/** Resultado de leer la ruta GPS de una sesion EXTERNA de Health Connect
 *  (paridad Apple fetchRoutePoints + ensureWorkoutRouteAccess, 6826b9a7).
 *  La ruta de otra app puede requerir consentimiento POR SESION
 *  (ExerciseRouteRequestContract); nunca se estima ni se sustituye por GPX
 *  propio. */
sealed class ExternalRouteRead {
    /** Lectura en curso o no realizada todavia. */
    object Unavailable : ExternalRouteRead()
    /** El registro no tiene ruta (NoData o ruta vacia). */
    object NoRoute : ExternalRouteRead()
    /** HC exige consentimiento por sesion (exerciseRouteResult=ConsentRequired). */
    object ConsentRequired : ExternalRouteRead()
    /** Ruta autorizada con sus puntos. */
    data class Points(val points: List<WorkoutRoutePoint>) : ExternalRouteRead()
}

/** Conversion HC -> dominio (ExerciseRoute.Location no tiene velocidad). */
internal fun ExerciseRoute.toWorkoutRoutePoints(): List<WorkoutRoutePoint> =
    route.map { loc ->
        WorkoutRoutePoint(
            id = 0,
            latitude = loc.latitude,
            longitude = loc.longitude,
            recordedAtEpochMs = loc.time.toEpochMilli(),
            speedMps = null,
            altitudeMeters = loc.altitude?.inMeters,
            horizontalAccuracyMeters = loc.horizontalAccuracy?.inMeters,
            verticalAccuracyMeters = loc.verticalAccuracy?.inMeters,
            isEstimated = null
        )
    }

/** Decision pura de presentacion de la ruta externa en la hoja de detalle.
 *  Separada del flujo HC/Activity para ser testeable con dobles. */
object ExternalRouteSheetModel {
    sealed class State {
        object Loading : State()
        object Hidden : State()          // Unavailable/NoRoute/<2 puntos
        object ConsentNeeded : State()   // boton de consentimiento por sesion
        data class Shown(val points: List<WorkoutRoutePoint>) : State()
    }

    fun present(read: ExternalRouteRead?): State = when (read) {
        null -> State.Loading
        is ExternalRouteRead.Unavailable -> State.Hidden
        is ExternalRouteRead.NoRoute -> State.Hidden
        is ExternalRouteRead.ConsentRequired -> State.ConsentNeeded
        is ExternalRouteRead.Points ->
            // RouteMapModel necesita >= 2 puntos para dibujar un tramo.
            if (read.points.size >= 2) State.Shown(read.points) else State.Hidden
    }
}
