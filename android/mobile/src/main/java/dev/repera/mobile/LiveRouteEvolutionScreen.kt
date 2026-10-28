package dev.repera.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import dev.repera.domain.LiveSport
import dev.repera.domain.LiveSportHistory
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** Comparación de intentos completos. No agrupa por día: dos salidas el
 * mismo día siguen siendo dos intentos, como chartAttempts Apple. */
@Composable
internal fun LiveRouteEvolutionScreen(route: LiveSavedRoute, sport: LiveSport,
    sessions: List<LiveSportHistory.LiveSession>, onBack: () -> Unit,
    onOpenSession: (String) -> Unit, onMapStyleLoaded: (() -> Unit)? = null) {
    var metric by remember(route.id) { mutableStateOf(LiveSportHistory.EvolutionMetric.DURATION) }
    val attempts=sessions.filter {it.liveRouteID==route.id && it.sportID==sport.id && it.finishedEpochMillis!=null}
        .sortedBy {it.startedEpochMillis ?: Long.MIN_VALUE}
    val eligible=LiveSportHistory.eligibleAttempts(attempts,route.distanceKm)
    val fastest=eligible.filter {(it.activeDurationSeconds ?: 0.0)>0}.minByOrNull {it.activeDurationSeconds!!}
    val chart=eligible.mapNotNull {s -> LiveSportHistory.evolutionValue(s,metric,sport)?.let {s to it}}
    val unit=when(metric) {
        LiveSportHistory.EvolutionMetric.DURATION->"min"
        LiveSportHistory.EvolutionMetric.DISTANCE->"km"
        else->if(sport.displaysSpeed) "km/h" else "min/km"
    }
    LazyColumn(Modifier.fillMaxSize().testTag("live_route_evolution"),contentPadding=PaddingValues(16.dp),
        verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item {
            TextButton(onClick=onBack) {Text("Volver al deporte")}
            Text(route.title,style=MaterialTheme.typography.headlineMedium)
        }
        if(route.points.size>=2) item {
            RouteMapView(route.points,isInteractive=true,plannedRoute=true,modifier=Modifier.fillMaxWidth().height(220.dp), onStyleLoaded=onMapStyleLoaded)
        }
        item {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(10.dp)) {
                    Text("Evolución del recorrido",style=MaterialTheme.typography.titleMedium)
                    Text("${attempts.size} veces · Mejor tiempo: ${fastest?.let {LiveSportHistory.formatDuration(it.activeDurationSeconds!!)} ?: "Sin datos"}")
                    Text(if(route.distanceKm>0) dev.repera.domain.ReperaNumberFormat.decimal(route.distanceKm)+" km" else "Distancia sin datos")
                    if(attempts.size!=eligible.size) Text("Los intentos con un recorrido incompleto no cuentan para el mejor tiempo.",style=MaterialTheme.typography.bodySmall)
                    FlowRow(horizontalArrangement=Arrangement.spacedBy(6.dp)) {
                        LiveSportHistory.EvolutionMetric.entries.forEach {option ->
                            FilterChip(selected=metric==option,onClick={metric=option},label={Text(option.title)})
                        }
                    }
                    if(chart.size>=2) {
                        val color=MaterialTheme.colorScheme.primary
                        val first=chart.first().first.startedEpochMillis!!
                        val spanTime=(chart.last().first.startedEpochMillis!!-first).coerceAtLeast(1L).toDouble()
                        val low=chart.minOf {it.second};val high=chart.maxOf {it.second}
                        val span=(high-low).coerceAtLeast(0.001)
                        Text(unit,style=MaterialTheme.typography.labelSmall)
                        Canvas(Modifier.fillMaxWidth().height(200.dp).semantics {
                            contentDescription="${chart.size} intentos: " + chart.joinToString {"%.2f %s".format(it.second,unit)}
                        }) {
                            val vertices = chart.map { (session,value) ->
                                androidx.compose.ui.geometry.Offset(
                                    12f+((session.startedEpochMillis!!-first)/spanTime).toFloat()*(size.width-24),
                                    12f+(1-((value-low)/span).toFloat())*(size.height-24))
                            }
                            val path = Path().apply {
                                moveTo(vertices.first().x, vertices.first().y)
                                // Uniform Catmull-Rom, expressed as cubic Bézier.
                                for (i in 0 until vertices.lastIndex) {
                                    val p0 = vertices[(i-1).coerceAtLeast(0)]
                                    val p1 = vertices[i];val p2 = vertices[i+1]
                                    val p3 = vertices[(i+2).coerceAtMost(vertices.lastIndex)]
                                    cubicTo(p1.x+(p2.x-p0.x)/6, p1.y+(p2.y-p0.y)/6,
                                        p2.x-(p3.x-p1.x)/6, p2.y-(p3.y-p1.y)/6, p2.x,p2.y)
                                }
                            }
                            vertices.forEach { drawCircle(color,5f,it) }
                            drawPath(path,color,style=Stroke(width=3f))
                        }
                        Text("%.2f - %.2f %s".format(low,high,unit),style=MaterialTheme.typography.bodySmall)
                    } else {
                        Text("Sin evolución todavía",style=MaterialTheme.typography.titleSmall)
                        Text("Repite esta ruta para comparar tus tiempos, ritmo y distancia.")
                    }
                }
            }
        }
        item {Text("Sesiones en esta ruta",style=MaterialTheme.typography.titleMedium)}
        items(attempts.reversed(),key={it.id}) {session ->
            OutlinedButton(onClick={onOpenSession(session.id)},modifier=Modifier.fillMaxWidth()) {
                Column(Modifier.fillMaxWidth()) {
                    Text(session.startedEpochMillis?.let {Instant.ofEpochMilli(it).atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("d MMM yyyy · HH:mm"))} ?: session.title)
                    Text("%.2f km · %s".format((session.recordedDistanceMeters ?: 0.0)/1000,LiveSportHistory.formatDuration(session.activeDurationSeconds ?: 0.0)))
                }
            }
        }
    }
}
