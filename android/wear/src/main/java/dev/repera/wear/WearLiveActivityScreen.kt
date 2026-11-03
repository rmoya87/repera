package dev.repera.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.FilledIconButton
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.IconButtonDefaults
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.touchTargetAwareSize
import dev.repera.domain.ActivityConditionsSnapshot
import dev.repera.domain.LiveSport
import dev.repera.domain.LiveSportHistory
import dev.repera.domain.ReperaNumberFormat
import org.json.JSONObject

/**
 * Companion Comenzar: página 0 = métricas; deslizar de derecha a izquierda
 * abre página 1 de Pausar / Finalizar. Confirmación de fin = modal encima.
 */
@Composable
internal fun WearLiveActivityScreen(
    live: JSONObject,
    health: Pair<Int?, Double?>?,
    onLiveCommand: (String) -> Unit,
    onDismissLiveToHome: () -> Unit,
    modifier: Modifier = Modifier
) {
    val phase = live.optString("phase")
    val sport = LiveSport.byId(live.optString("sportId"))
    // Mantener dos páginas también al entrar en revisión evita un índice inválido.
    val pager = rememberPagerState(initialPage = 0, pageCount = { 2 })
    var confirmFinish by remember(live.optString("sessionId")) { mutableStateOf(false) }

    Box(modifier = modifier.fillMaxSize()) {
        HorizontalPager(
            state = pager,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            when {
                phase == "review" -> WearLiveReviewPage(onDismissLiveToHome)
                page == 0 -> WearLiveMetricsPage(live = live, sport = sport, health = health)
                else -> WearLiveControlsPage(
                    phase = phase,
                    onPauseResume = {
                        onLiveCommand(if (phase == "paused") "resume" else "pause")
                    },
                    onRequestFinish = { confirmFinish = true }
                )
            }
        }

        if (confirmFinish) {
            WearConfirmFinishModal(
                onCancel = { confirmFinish = false },
                onConfirm = {
                    confirmFinish = false
                    onLiveCommand("finish")
                }
            )
        }
    }
}

@Composable
private fun WearLiveMetricsPage(
    live: JSONObject,
    sport: LiveSport?,
    health: Pair<Int?, Double?>?
) {
    val phase = live.optString("phase")
    val now = remember(live.optString("sessionId")) {
        mutableLongStateOf(System.currentTimeMillis())
    }
    LaunchedEffect(live.optString("sessionId"), phase) {
        while (true) {
            kotlinx.coroutines.delay(1_000)
            now.longValue = System.currentTimeMillis()
        }
    }
    val extra = if (phase == "recording") {
        ((now.longValue - live.optLong("capturedAtMillis")) / 1000.0).coerceAtLeast(0.0)
    } else {
        0.0
    }
    val elapsed = live.optDouble("elapsedSeconds", 0.0) + extra
    val meters = live.optDouble("distanceMeters", 0.0)
    val usesGps = sport?.usesGPS == true
    val showSpeed = sport?.displaysSpeed == true
    val showElevation = sport?.tracksElevation == true
    val speed = live.optDouble("averageSpeedKmh").takeIf { !live.isNull("averageSpeedKmh") && it > 0 }
    val elevation = live.optDouble("elevationGainMeters")
        .takeIf { !live.isNull("elevationGainMeters") && showElevation && it > 0 }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(start = 12.dp, end = 12.dp, top = 6.dp, bottom = 16.dp),
        horizontalAlignment = Alignment.Start,
        verticalArrangement = Arrangement.spacedBy(7.dp)
    ) {
        when (phase) {
            "paused" -> Text(
                "En pausa",
                color = WearOg.orange,
                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold)
            )
            "review" -> Text(
                "Revisar en el teléfono",
                color = WearOg.label2,
                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold)
            )
        }

        Text(
            LiveSportHistory.formatDuration(elapsed),
            style = MaterialTheme.typography.displayMedium.copy(
                fontSize = 40.sp,
                fontWeight = FontWeight.Bold
            ),
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.fillMaxWidth()
        )

        if (usesGps) {
            WearLiveMetricRow(
                label = "km",
                value = if (meters > 0) ReperaNumberFormat.decimal(meters / 1000.0) else "—"
            )
            if (showSpeed) {
                WearLiveMetricRow(
                    label = "km/h",
                    value = speed?.let { ReperaNumberFormat.decimal(it) } ?: "—"
                )
            } else {
                WearLiveMetricRow(label = "Ritmo", value = companionPaceLabel(meters, elapsed))
            }
            if (showElevation) {
                WearLiveMetricRow(
                    label = "Desnivel",
                    value = elevation?.let { String.format("+%.0f m", it) } ?: "—"
                )
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text("FC", color = WearOg.label2, style = MaterialTheme.typography.labelSmall)
            WearHeartRateZoneBar(bpm = health?.first, prominent = !usesGps)
        }
        WearLiveMetricRow(
            label = "kcal",
            value = health?.second?.takeIf { it >= 0 }?.let { String.format("%.0f", it) } ?: "—",
            prominent = !usesGps
        )

        if (!live.isNull("nextTurn") && phase != "review") {
            Text(
                live.optString("nextTurn"),
                style = MaterialTheme.typography.labelSmall,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(10.dp))
                    .padding(7.dp)
            )
        }

        live.optJSONObject("conditions")?.let { conditionsBlock(it) }

    }
}

@Composable
private fun WearLiveControlsPage(
    phase: String,
    onPauseResume: () -> Unit,
    onRequestFinish: () -> Unit
) {
    val btn = IconButtonDefaults.DefaultButtonSize
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp, Alignment.CenterVertically)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            FilledIconButton(
                onClick = onPauseResume,
                modifier = Modifier
                    .touchTargetAwareSize(btn)
                    .semantics {
                        contentDescription = if (phase == "paused") "Reanudar" else "Pausar"
                    },
                colors = IconButtonDefaults.filledIconButtonColors()
            ) {
                Icon(
                    imageVector = if (phase == "paused") Icons.Filled.PlayArrow else Icons.Filled.Pause,
                    contentDescription = null
                )
            }
            FilledIconButton(
                onClick = onRequestFinish,
                modifier = Modifier
                    .touchTargetAwareSize(btn)
                    .semantics { contentDescription = "Finalizar" },
                colors = IconButtonDefaults.filledIconButtonColors()
            ) {
                Icon(imageVector = Icons.Filled.Flag, contentDescription = null)
            }
        }
    }
}

@Composable
private fun WearLiveReviewPage(onDismissLiveToHome: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically)
    ) {
        Text(
            "Finalizada · guarda en el teléfono",
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.labelMedium,
            maxLines = 2
        )
        WearPrimaryButton("Volver al inicio", onClick = onDismissLiveToHome)
    }
}

@Composable
internal fun WearConfirmFinishModal(
    title: String = "¿Finalizar?",
    confirmLabel: String = "Finalizar",
    destructive: Boolean = false,
    onCancel: () -> Unit,
    onConfirm: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .zIndex(20f)
            .background(Color.Black.copy(alpha = 0.72f))
            .semantics { contentDescription = "Confirmar finalización" },
        contentAlignment = Alignment.Center
    ) {
        // Sin card: TextButton Wear es circular y corta «Descartar» → Button a ancho.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                title,
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.titleSmall,
                textAlign = TextAlign.Center,
                maxLines = 2
            )
            Button(
                onClick = onConfirm,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(44.dp),
                colors = if (destructive) {
                    ButtonDefaults.buttonColors(
                        containerColor = WearOg.red,
                        contentColor = Color.White
                    )
                } else {
                    ButtonDefaults.buttonColors()
                }
            ) {
                WearButtonLabel(
                    confirmLabel,
                    color = if (destructive) Color.White else WearOg.onAccent
                )
            }
            Button(
                onClick = onCancel,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(44.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Transparent,
                    contentColor = WearOg.red
                )
            ) {
                WearButtonLabel("Cancelar", color = WearOg.red)
            }
        }
    }
}

@Composable
internal fun WearLiveMetricRow(label: String, value: String, prominent: Boolean = false) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            label,
            color = WearOg.label2,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.width(52.dp),
            maxLines = 1
        )
        Text(
            value,
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Bold,
                fontSize = if (prominent) 27.sp else MaterialTheme.typography.titleMedium.fontSize
            ),
            maxLines = 1,
            softWrap = false
        )
    }
}

@Composable
internal fun WearHeartRateZoneBar(
    bpm: Int?, estimatedMaxBpm: Double = 190.0, prominent: Boolean = false
) {
    val zone = dev.repera.domain.LiveHeartRateZones.zone(bpm, estimatedMaxBpm)
    val colors = listOf(
        Color(0xFF408CFF), Color(0xFF33D966), Color(0xFFF2D926),
        Color(0xFFFF8C1A), Color(0xFFF23333)
    )
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            bpm?.toString() ?: "—",
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Bold,
                fontSize = if (prominent) 27.sp else MaterialTheme.typography.titleMedium.fontSize
            ),
            modifier = Modifier.width(if (prominent) 50.dp else 36.dp),
            maxLines = 1
        )
        Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.End) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                colors.forEachIndexed { index, color ->
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(if (zone == index + 1) 12.dp else 8.dp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(color.copy(alpha = if (zone == index + 1) 1f else 0.28f))
                    )
                }
            }
            Text(
                zone?.let { "Zona $it/5" } ?: "Sin lectura",
                style = MaterialTheme.typography.labelSmall,
                color = WearOg.label2,
                maxLines = 1
            )
        }
    }
}

@Composable
private fun conditionsBlock(conditions: JSONObject) {
    val snap = runCatching {
        ActivityConditionsSnapshot.fromJson(conditions)
    }.getOrNull() ?: return

    val temperature = snap.temperatureC?.takeIf { it.isFinite() }
    val wind = snap.windKmh?.takeIf { it.isFinite() }
    val water = snap.family == dev.repera.domain.ActivityConditionsFamily.WATER
    val snow = snap.family == dev.repera.domain.ActivityConditionsFamily.SNOW
    val tide = snap.tideHeightMeters?.takeIf { water && it.isFinite() }
    val nextTide = snap.nextTideLabel?.takeIf { water && it.isNotBlank() }
    val waves = snap.waveHeightMeters?.takeIf { water && it.isFinite() }
    val snowfall = snap.snowfallCm?.takeIf { snow && it.isFinite() && it > 0 }
    val depth = snap.snowDepthMeters?.takeIf { snow && it.isFinite() && it > 0 }

    // Sin un valor meteorológico real no se pinta ni el título ni la tarjeta.
    if (temperature == null && wind == null && tide == null &&
        nextTide == null && waves == null && snowfall == null && depth == null) return

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White.copy(alpha = 0.07f), RoundedCornerShape(12.dp))
            .padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            "Condiciones",
            color = WearOg.label2,
            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold)
        )
        temperature?.let { WearStatsLine("Temperatura", String.format("%.0f °C", it)) }
        wind?.let { WearStatsLine("Viento", String.format("%.0f km/h", it)) }
        tide?.let { height ->
            val trend = snap.tideTrendLabel?.let { " · $it" }.orEmpty()
            WearStatsLine("Marea", String.format("%.2f m%s", height, trend))
        }
        nextTide?.let { WearStatsLine("Próxima marea", it) }
        waves?.let { WearStatsLine("Oleaje", String.format("%.1f m", it)) }
        snowfall?.let { WearStatsLine("Nevada", String.format("%.1f cm/h", it)) }
        depth?.let { WearStatsLine("Nieve", String.format("%.0f cm", it * 100)) }
        snap.disclaimer?.takeIf { it.isNotBlank() }?.let {
            Text(it, color = WearOg.label2, style = MaterialTheme.typography.labelSmall)
        }
        if (snap.attribution.isNotBlank()) {
            Text(
                snap.attribution,
                color = WearOg.label2,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp)
            )
        }
    }
}

private fun companionPaceLabel(meters: Double, elapsedSeconds: Double): String {
    if (meters <= 20) return "—"
    val pace = (elapsedSeconds.coerceAtLeast(1.0) / meters) * 1000.0
    val m = pace.toInt() / 60
    val s = pace.toInt() % 60
    return "%d'%02d\"".format(m, s)
}
