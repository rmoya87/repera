package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.repera.domain.LiveSport
import dev.repera.domain.SessionSportMetrics

/** Tres métricas del deporte (Vel. media, Vel. máx, Ritmo medio o Distancia) con los totales medidos de la actividad.
 *  Apple SessionSportMetricTile. Compile-only: sin pixeles ni TalkBack. Muestra «—» si falta el dato. */
@Composable
internal fun SessionSportMetricRow(workout: WorkoutHistoryEntry) {
    val sport = workout.liveSportID?.let(LiveSport::byId)
    val meters = workout.recordedDistanceMeters
    if (!SessionSportMetrics.showsGpsTiles(sport, meters, workout.routePoints, workout.liveKilometerSplitsSeconds.isNotEmpty())) return
    val active = workout.activeDurationSeconds
    val tiles = SessionSportMetrics.tiles(sport, active, meters, null, workout.routePoints)
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Tile("Vel. media", tiles.averageSpeedKmh?.let(SessionSportMetrics::decimal), "km/h", Modifier.weight(1f))
        Tile("Vel. máx", tiles.maxSpeedKmh?.let(SessionSportMetrics::decimal), "km/h", Modifier.weight(1f))
        if (SessionSportMetrics.showsDistanceInsteadOfPace(sport))
            Tile("Distancia", tiles.distanceKm?.let(SessionSportMetrics::decimal), "km", Modifier.weight(1f))
        else Tile("Ritmo medio", tiles.averagePace, "min/km", Modifier.weight(1f))
    }
}

@Composable
private fun Tile(title: String, value: String?, unit: String, modifier: Modifier,
    tint: androidx.compose.ui.graphics.Color = androidx.compose.ui.graphics.Color.Unspecified) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(title, style = MaterialTheme.typography.labelSmall)
        Text(value ?: "—", style = MaterialTheme.typography.titleMedium,
            color = tint)
        Text(unit, style = MaterialTheme.typography.labelSmall)
    }
}

/** Apple miniStat: Mín / Media / Máx con «—» si falta el dato. Compile-only. */
@Composable
internal fun SessionRangeTiles(title: String, range: SessionSportMetrics.Range?, unit: String,
    heart: Boolean = false) {
    // Tintes Apple CardioRouteComponents miniStat (9a28ba95): FC Mín=acento
    // verde, Media=azul, Máx=rojo; Altitud Mín=gris, Media=azul, Máx=acento.
    val accent = androidx.compose.ui.graphics.Color(0xFF2FA86B)
    val blue = androidx.compose.ui.graphics.Color(0xFF0A84FF)
    val red = androidx.compose.ui.graphics.Color(0xFFE5484D)
    val gray = MaterialTheme.colorScheme.onSurfaceVariant
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(title, style = MaterialTheme.typography.labelMedium)
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Tile("Mín", range?.min?.let(dev.repera.domain.ReperaNumberFormat::integer), unit, Modifier.weight(1f), if (heart) accent else gray)
            Tile("Media", range?.avg?.let(dev.repera.domain.ReperaNumberFormat::integer), unit, Modifier.weight(1f), blue)
            Tile("Máx", range?.max?.let(dev.repera.domain.ReperaNumberFormat::integer), unit, Modifier.weight(1f), if (heart) red else accent)
        }
    }
}

/** Apple HistoryView: distancia recuperada sin puntos GPS (el espejo no sube la ruta). */
internal object RouteUnavailable {
    fun applies(sport: LiveSport?, meters: Double?, routePointCount: Int): Boolean =
        sport?.usesGPS == true && (meters ?: 0.0) > 0.0 && routePointCount < 2
}

/** Compile-only: sin pixeles ni TalkBack. Texto de Apple, adaptado al origen Android. */
@Composable
internal fun RouteUnavailableNotice(workout: WorkoutHistoryEntry) {
    if (!RouteUnavailable.applies(workout.liveSportID?.let(LiveSport::byId), workout.recordedDistanceMeters, workout.routePoints.size)) return
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text("Recorrido no disponible en este dispositivo", style = MaterialTheme.typography.titleSmall)
        Text("Se ha recuperado la distancia, pero los puntos GPS no viajan por Supabase. El recorrido original puede seguir en el dispositivo donde se grabó.",
            style = MaterialTheme.typography.bodySmall)
    }
}
