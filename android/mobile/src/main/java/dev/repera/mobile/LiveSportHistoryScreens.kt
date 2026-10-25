package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import dev.repera.domain.LiveSport
import dev.repera.domain.LiveSportHistory
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.math.roundToInt

@Composable
internal fun LiveSportsCatalogScreen(
    sessions: List<LiveSportHistory.LiveSession>, query: String,
    onOpenSport: (LiveSport) -> Unit, modifier: Modifier = Modifier
) {
    val sports = LiveSportHistory.sportsWithActivity(sessions).filter {
        foldForSearch(it.title).contains(foldForSearch(query))
    }
    LazyColumn(modifier.fillMaxSize().testTag("live_sports_catalog"),
        contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        if (sports.isEmpty()) item {
            Text("Sin actividades deportivas", style = MaterialTheme.typography.titleMedium)
            Text("Las actividades guardadas desde En vivo aparecerán aquí, con sus recorridos y su evolución.")
        } else {
            item { Text("Deportes registrados", style = MaterialTheme.typography.titleMedium) }
            items(sports, key = { it.id }) { sport ->
                Card(Modifier.fillMaxWidth().testTag("sport_${sport.id}").clickable { onOpenSport(sport) }) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(sport.title, style = MaterialTheme.typography.titleMedium)
                        Text(LiveSportHistory.activitySummaryLine(sport, sessions),
                            style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
    }
}

@Composable
internal fun LiveSportHistoryScreen(
    sport: LiveSport, sessions: List<LiveSportHistory.LiveSession>,
    onBack: () -> Unit, onOpenSession: (String) -> Unit = {}, modifier: Modifier = Modifier,
    favoriteRoutes: List<LiveSavedRoute> = emptyList(),
    canSaveRoute: (String) -> Boolean = { false },
    onSaveRoute: (String) -> Unit = {}, onOpenRoute: (LiveSavedRoute) -> Unit = {}
) {
    val own = LiveSportHistory.sessionsOf(sport, sessions)
    val summary = LiveSportHistory.summary(sport, sessions)
    LazyColumn(modifier.fillMaxSize().testTag("live_sport_history"),
        contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            TextButton(onClick = onBack) { Text("Volver a Deportes") }
            Text(sport.title, style = MaterialTheme.typography.headlineMedium)
        }
        item {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Resumen", style = MaterialTheme.typography.titleMedium)
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        SportSummaryTile("Actividades", "${summary.activityCount}", Modifier.weight(1f))
                        SportSummaryTile("Tiempo", LiveSportHistory.formatDuration(summary.totalDurationSeconds), Modifier.weight(1f))
                        when {
                            sport.usesGPS -> SportSummaryTile("Distancia", "%.1f km".format(summary.totalKilometers), Modifier.weight(1f))
                            summary.measuredEnergyKcal != null -> SportSummaryTile("Energía medida", "${summary.measuredEnergyKcal!!.roundToInt()} kcal", Modifier.weight(1f))
                            summary.measuredHeartRateBpm != null -> SportSummaryTile("Pulso medio", "${summary.measuredHeartRateBpm!!.roundToInt()} lpm", Modifier.weight(1f))
                        }
                    }
                    summary.measuredHeartRateBpm?.takeIf { sport.usesGPS || summary.measuredEnergyKcal != null }?.let {
                        Text("Pulso medio medido: ${it.roundToInt()} lpm", style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
        if (sport.usesGPS && favoriteRoutes.isNotEmpty()) {
            item { Text("Rutas favoritas · evolución", style = MaterialTheme.typography.titleMedium) }
            items(favoriteRoutes, key = { "route-${it.id}" }) { route ->
                OutlinedButton(onClick = { onOpenRoute(route) }, modifier = Modifier.fillMaxWidth()) {
                    Text("★ ${route.title} · ${own.count { it.liveRouteID == route.id }} veces realizada")
                }
            }
        }
        item { Text(if (sport.usesGPS) "Recorridos realizados" else "Actividades realizadas",
            style = MaterialTheme.typography.titleMedium) }
        items(own, key = { it.id }) { session ->
            Card(Modifier.fillMaxWidth().testTag("live_session_${session.id}").clickable { onOpenSession(session.id) }) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text(session.title, style = MaterialTheme.typography.titleSmall)
                    (session.startedEpochMillis ?: session.finishedEpochMillis)?.let {
                        Text(Instant.ofEpochMilli(it).atZone(ZoneId.systemDefault())
                            .format(DateTimeFormatter.ofPattern("d MMM yyyy · HH:mm")),
                            style = MaterialTheme.typography.bodySmall)
                    }
                    val metrics = buildList {
                        add(LiveSportHistory.formatDuration(session.activeDurationSeconds ?: 0.0))
                        session.recordedDistanceMeters?.takeIf { it > 0 }?.let { add("%.2f km".format(it / 1000)) }
                        session.averageHeartRateBpm?.takeIf { it > 0 }?.let { add("${it.roundToInt()} lpm") }
                        session.activeEnergyKcal?.takeIf { it > 0 }?.let { add("${it.roundToInt()} kcal") }
                    }
                    Text(metrics.joinToString(" · "), style = MaterialTheme.typography.bodySmall)
                    if (sport.usesGPS && canSaveRoute(session.id)) {
                        TextButton(onClick = { onSaveRoute(session.id) }) { Text("Guardar ruta") }
                    }
                }
            }
        }
    }
}

@Composable
private fun SportSummaryTile(title: String, value: String, modifier: Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(value, style = MaterialTheme.typography.titleMedium)
        Text(title, style = MaterialTheme.typography.labelSmall)
    }
}

@Composable
internal fun LiveKilometerSplitsSection(seconds: List<Double>, displaysSpeed: Boolean = false) {
    if (seconds.isEmpty()) return
    Column(Modifier.fillMaxWidth().testTag("live_kilometer_splits"), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("Parciales por kilómetro", style = MaterialTheme.typography.titleMedium)
        seconds.forEachIndexed { index, duration ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Km ${index + 1}")
                Text(if (displaysSpeed) "%.1f km/h".format(3600 / duration)
                    else "${LiveSportHistory.formatDuration(duration)} min/km")
            }
        }
    }
}
