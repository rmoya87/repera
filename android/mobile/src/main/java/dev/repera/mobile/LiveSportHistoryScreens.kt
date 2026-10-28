package dev.repera.mobile

import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.Whatshot
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
                ReperaCard(Modifier.fillMaxWidth().testTag("sport_${sport.id}").clickable { onOpenSport(sport) }) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
                            Icon(sport.materialIcon,contentDescription=null,tint=MaterialTheme.colorScheme.primary)
                            Text(sport.title, style = MaterialTheme.typography.titleMedium)
                        }
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
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Volver a Deportes") }
            Text(sport.title, style = MaterialTheme.typography.headlineMedium)
        }
        item {
            ReperaCard(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Resumen", style = MaterialTheme.typography.titleMedium)
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        WorkoutSummaryTile("Actividades", "${summary.activityCount}", sport.materialIcon, Modifier.weight(1f))
                        WorkoutSummaryTile("Tiempo", LiveSportHistory.formatDuration(summary.totalDurationSeconds), Icons.Outlined.AccessTime, Modifier.weight(1f))
                        when {
                            sport.usesGPS -> WorkoutSummaryTile("Distancia", dev.repera.domain.ReperaNumberFormat.decimal(summary.totalKilometers) + " km", Icons.Outlined.Route, Modifier.weight(1f))
                            summary.measuredEnergyKcal != null -> WorkoutSummaryTile("Energía medida", "${summary.measuredEnergyKcal!!.roundToInt()} kcal", Icons.Outlined.Whatshot, Modifier.weight(1f))
                            summary.measuredHeartRateBpm != null -> WorkoutSummaryTile("Pulso medio", "${summary.measuredHeartRateBpm!!.roundToInt()} lpm", Icons.Outlined.FavoriteBorder, Modifier.weight(1f))
                        }
                    }
                    summary.measuredHeartRateBpm?.takeIf { sport.usesGPS || summary.measuredEnergyKcal != null }?.let {
                        Text("Pulso medio medido: ${it.roundToInt()} lpm", style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
        if (own.isNotEmpty()) item {
            val records = LiveSportHistory.records(sport, sessions)
            ReperaCard(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Mejores marcas · ${sport.title}", style = MaterialTheme.typography.titleMedium)
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        records.longestDistanceMeters?.takeIf { sport.usesGPS }?.let {
                            WorkoutSummaryTile("Mayor distancia", dev.repera.domain.ReperaNumberFormat.decimal(it / 1000) + " km", Icons.Outlined.Route, Modifier.weight(1f)) }
                        records.fastestRecordedKilometerSeconds?.takeIf { sport.usesGPS }?.let {
                            WorkoutSummaryTile("Mejor km", LiveSportHistory.formatDuration(it), Icons.Outlined.Timer, Modifier.weight(1f)) }
                        records.longestActiveSeconds?.let {
                            WorkoutSummaryTile("Mayor duración", LiveSportHistory.formatDuration(it), Icons.Outlined.AccessTime, Modifier.weight(1f)) }
                    }
                    Text("Marcas basadas en actividades guardadas de este deporte. No representan récords de fuerza.", style = MaterialTheme.typography.bodySmall)
                }
            }
        }
        if (sport.usesGPS && favoriteRoutes.isNotEmpty()) {
            item { Text("Rutas favoritas · evolución", style = MaterialTheme.typography.titleMedium) }
            items(favoriteRoutes, key = { "route-${it.id}" }) { route ->
                OutlinedButton(onClick = { onOpenRoute(route) }, modifier = Modifier.fillMaxWidth()) {
                    Text("${route.title} · ${own.count { it.liveRouteID == route.id }} veces · favorita")
                }
            }
        }
        item { Text(if (sport.usesGPS) "Recorridos realizados" else "Actividades realizadas",
            style = MaterialTheme.typography.titleMedium) }
        items(own, key = { it.id }) { session ->
            SaveRouteSwipeRow(session.id, sport.usesGPS && canSaveRoute(session.id),
                { onSaveRoute(session.id) }) {
            ReperaCard(Modifier.fillMaxWidth().testTag("live_session_${session.id}").clickable { onOpenSession(session.id) }) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text(session.title, style = MaterialTheme.typography.titleSmall)
                    (session.startedEpochMillis ?: session.finishedEpochMillis)?.let {
                        Text(Instant.ofEpochMilli(it).atZone(ZoneId.systemDefault())
                            .format(DateTimeFormatter.ofPattern("d MMM yyyy · HH:mm")),
                            style = MaterialTheme.typography.bodySmall)
                    }
                    val metrics = buildList {
                        add(LiveSportHistory.formatDuration(session.activeDurationSeconds ?: 0.0))
                        session.recordedDistanceMeters?.takeIf { it > 0 }?.let { add(dev.repera.domain.ReperaNumberFormat.decimal(it / 1000) + " km") }
                        session.averageHeartRateBpm?.takeIf { it > 0 }?.let { add("${it.roundToInt()} lpm") }
                        session.activeEnergyKcal?.takeIf { it > 0 }?.let { add("${it.roundToInt()} kcal") }
                    }
                    Text(metrics.joinToString(" · "), style = MaterialTheme.typography.bodySmall)
                }
            }
            }
        }
    }
}

/** Reveal-only swipe: a gesture never writes a favorite without the action tap. */
@Composable
private fun SaveRouteSwipeRow(id:String,enabled:Boolean,onSave:()->Unit,content:@Composable ()->Unit) {
    val width=with(LocalDensity.current) { 112.dp.toPx() }
    var offset by remember(id) { mutableStateOf(0f) }
    LaunchedEffect(enabled) { if(!enabled) offset=0f }
    Box(Modifier.fillMaxWidth().testTag("swipe_route_$id")
        .semantics {
            if(enabled) customActions=listOf(CustomAccessibilityAction("Guardar ruta") { onSave();true })
        }
        .pointerInput(id,enabled,width) {
            if(enabled) detectHorizontalDragGestures(
                onHorizontalDrag={change,amount -> change.consume();offset=(offset+amount).coerceIn(-width,0f)},
                onDragEnd={offset=if(offset < -width/2) -width else 0f},
                onDragCancel={offset=0f})
        }) {
        if(enabled && offset<0f) TextButton(onClick={onSave();offset=0f},
            modifier=Modifier.align(androidx.compose.ui.Alignment.CenterEnd).width(112.dp)
                .testTag("save_route_$id")) { Text("Guardar ruta") }
        Box(Modifier.offset { IntOffset(offset.roundToInt(),0) }) { content() }
    }
}

// Apple 1b5d4eea/056cba8b/025828b5 (WorkoutSummaryTile): icono+etiqueta en
// fila centrada y valor centrado debajo, altura intrinseca (sin minimo fijo).
@Composable
internal fun WorkoutSummaryTile(title: String, value: String, icon: ImageVector, modifier: Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(7.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null,
                tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(13.dp))
            Text(title, fontSize = 11.sp, fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
        }
        Text(value, fontSize = 20.sp, fontWeight = FontWeight.SemiBold,
            maxLines = 1, textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth())
    }
}

@Composable
internal fun LiveKilometerSplitsSection(seconds: List<Double>, displaysSpeed: Boolean = false,
    routePoints: List<dev.repera.domain.WorkoutRoutePoint> = emptyList(),
    heartRate: List<Pair<Long,Int>> = emptyList()) {
    if (seconds.isEmpty()) return
    val measured = remember(routePoints,heartRate) {
        if (heartRate.isEmpty()) emptyList() else dev.repera.domain.CardioRouteAnalysis.analyze(
            routePoints.map { dev.repera.domain.CardioRouteAnalysis.Sample(it.recordedAtEpochMs/1000.0,it.latitude,it.longitude,it.altitudeMeters) },
            heartRate.map { dev.repera.domain.CardioRouteAnalysis.HeartSample(it.first/1000.0,it.second.toDouble()) }).splits
    }
    Column(Modifier.fillMaxWidth().testTag("live_kilometer_splits"), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("Parciales por kilómetro", style = MaterialTheme.typography.titleMedium)
        val rows = dev.repera.domain.SessionSportMetrics.splitRows(seconds, displaysSpeed,
            measured.mapNotNull { sp -> sp.averageBpm?.let { sp.kilometer to it } }.toMap())
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("KM", Modifier.width(38.dp), style = MaterialTheme.typography.labelSmall)
            Text("Tiempo", Modifier.weight(1f), style = MaterialTheme.typography.labelSmall)
            Text(if (displaysSpeed) "km/h" else "Ritmo", Modifier.weight(1f), style = MaterialTheme.typography.labelSmall)
            Text("Frec. cardiaca", Modifier.width(88.dp), style = MaterialTheme.typography.labelSmall, textAlign = androidx.compose.ui.text.style.TextAlign.End)
        }
        rows.forEach { r ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("${r.kilometer}", Modifier.width(38.dp))
                Text(r.time, Modifier.weight(1f))
                Text(r.rateOrSpeed, Modifier.weight(1f))
                Text(r.bpm, Modifier.width(88.dp), textAlign = androidx.compose.ui.text.style.TextAlign.End)
            }
        }
    }
}
