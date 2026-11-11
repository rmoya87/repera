package dev.repera.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.VolumeOff
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
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
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin
import org.json.JSONObject

/**
 * Companion Comenzar: con ruta, desplazamiento vertical Navegación → Métricas.
 * Horizontal: Controles ← Métricas/Navegación → Now Playing (centro = métricas).
 */
@Composable
internal fun WearLiveActivityScreen(
    live: JSONObject,
    health: Pair<Int?, Double?>?,
    onLiveCommand: (String) -> Unit,
    onDismissLiveToHome: () -> Unit,
    modifier: Modifier = Modifier,
    notice: String? = null,
    finishPending: Boolean = false,
    audioMuted: Boolean = false,
    onToggleAudioMuted: () -> Unit = {}
) {
    val phase = live.optString("phase")
    val sport = LiveSport.byId(live.optString("sportId"))
    val hasGuidance = phase != "review" &&
        !live.isNull("nextTurn") && live.optString("nextTurn").isNotBlank()
    val liveSessionId = live.optString("sessionId")
    val haptic = LocalHapticFeedback.current
    val currentTurn = live.optString("nextTurn")
    val turnMeters = live.optInt("nextTurnMeters", -1).takeIf {
        !live.isNull("nextTurnMeters") && it >= 0
    }
    var previousTurnMeters by remember(liveSessionId, currentTurn) { mutableStateOf<Int?>(null) }
    var turnHapticSent by remember(liveSessionId, currentTurn) { mutableStateOf(false) }
    LaunchedEffect(turnMeters, liveSessionId, currentTurn) {
        if (hasGuidance && turnMeters != null) {
            if (turnMeters > 150) turnHapticSent = false
            if (previousTurnMeters != null && previousTurnMeters!! > 100 &&
                turnMeters <= 100 && !turnHapticSent) {
                turnHapticSent = true
                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
            }
        }
        previousTurnMeters = turnMeters
    }
    var metricsWereAlreadyVisible by remember(liveSessionId) { mutableStateOf(!hasGuidance) }
    LaunchedEffect(hasGuidance, liveSessionId) {
        if (!hasGuidance) metricsWereAlreadyVisible = true
    }
    // Tres páginas: Controles | Centro | Now Playing. Centro evita índice inválido en review.
    val pager = rememberPagerState(initialPage = 1, pageCount = { 3 })
    var confirmFinish by remember(live.optString("sessionId")) { mutableStateOf(false) }
    var confirmCancel by remember(live.optString("sessionId")) { mutableStateOf(false) }

    Box(modifier = modifier.fillMaxSize()) {
        HorizontalPager(
            state = pager,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            when {
                phase == "review" -> WearLiveReviewPage(onDismissLiveToHome)
                page == 0 -> WearLiveControlsPage(
                    phase = phase,
                    notice = notice,
                    finishPending = finishPending,
                    audioMuted = audioMuted,
                    onPauseResume = {
                        onLiveCommand(if (phase == "paused") "resume" else "pause")
                    },
                    onRequestFinish = { confirmFinish = true },
                    onRequestCancel = { confirmCancel = true },
                    onToggleAudioMuted = onToggleAudioMuted
                )
                page == 2 -> WearNowPlayingPage()
                else -> {
                    if (hasGuidance) {
                        key(liveSessionId) {
                            val verticalPages = rememberPagerState(
                                initialPage = if (metricsWereAlreadyVisible) 1 else 0,
                                pageCount = { 2 }
                            )
                            VerticalPager(state = verticalPages, modifier = Modifier.fillMaxSize()) { verticalPage ->
                                if (verticalPage == 0) {
                                    WearLiveNavigationPage(live)
                                } else {
                                    WearLiveMetricsPage(
                                        live = live, sport = sport, health = health, notice = notice
                                    )
                                }
                            }
                        }
                    } else {
                        WearLiveMetricsPage(live = live, sport = sport, health = health, notice = notice)
                    }
                }
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
        if (confirmCancel) {
            WearConfirmFinishModal(
                title = "¿Cancelar actividad?",
                confirmLabel = "Cancelar actividad",
                destructive = true,
                onCancel = { confirmCancel = false },
                onConfirm = {
                    confirmCancel = false
                    onLiveCommand("cancel")
                }
            )
        }
    }
}

/** La navegación se puede consultar sin desplazar por una lista de métricas. */
@Composable
private fun WearLiveNavigationPage(live: JSONObject) {
    val instruction = live.optString("nextTurn")
    val direction = when {
        instruction.contains("izquierda", ignoreCase = true) -> "↰"
        instruction.contains("derecha", ignoreCase = true) -> "↱"
        instruction.contains("vuelta", ignoreCase = true) -> "↶"
        else -> "↑"
    }
    val meters = if (live.isNull("nextTurnMeters")) null else live.optInt("nextTurnMeters", -1)
        .takeIf { it >= 0 }
    val distance = meters?.let {
        if (it >= 1000) String.format(java.util.Locale.ROOT, "%.1f km", it / 1000.0)
        else "$it m"
    }
    Column(
        modifier = Modifier.fillMaxSize().padding(horizontal = 15.dp, vertical = 6.dp)
            .semantics(mergeDescendants = true) {
                contentDescription = listOfNotNull(distance, instruction).joinToString(", ")
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceEvenly
    ) {
        Text(direction, color = WearOg.accent,
            style = MaterialTheme.typography.displayLarge.copy(fontWeight = FontWeight.Bold),
            textAlign = TextAlign.Center)
        distance?.let { label ->
            // Wear Material3 Typography no tiene headline*; displayMedium encaja entre
            // displayLarge (flecha) y titleMedium (instrucción).
            Text(
                label,
                color = WearOg.accent,
                style = MaterialTheme.typography.displayMedium.copy(fontWeight = FontWeight.Bold),
                textAlign = TextAlign.Center,
                maxLines = 1
            )
        }
        Text(instruction, style = MaterialTheme.typography.titleMedium,
            textAlign = TextAlign.Center, maxLines = 3,
            overflow = TextOverflow.Ellipsis)
    }
}

@Composable
private fun WearLiveMetricsPage(
    live: JSONObject,
    sport: LiveSport?,
    health: Pair<Int?, Double?>?,
    notice: String?
) {
    val phase = live.optString("phase")
    val now = remember(live.optString("sessionId")) {
        mutableLongStateOf(System.currentTimeMillis())
    }
    val latest by rememberUpdatedState(live)
    LaunchedEffect(live.optString("sessionId"), phase) {
        // Only a recording clock moves; align to its own second boundary.
        while (phase == "recording") {
            val sinceCapture = System.currentTimeMillis() - latest.optLong("capturedAtMillis") +
                (latest.optDouble("elapsedSeconds", 0.0) * 1000).toLong()
            kotlinx.coroutines.delay(wearMsUntilNextSecond(sinceCapture))
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
    val speed = live.optDouble("averageSpeedKmh").takeIf { !live.isNull("averageSpeedKmh") && it > 0 }
    // Escala a la cara redonda: tipografía/gaps que caben; sin recorte de km/kcal/LPM.
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val side = minOf(maxWidth, maxHeight)
        // Inset circular ~14 % evita mentón/bisel; end un poco más para el arco.
        val edge = side * 0.14f
        val scale = WearLiveMetricsScale.fit(maxHeight - edge * 2)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(
                    start = edge,
                    end = edge + 6.dp,
                    top = edge,
                    bottom = edge
                ),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(scale.gap, Alignment.CenterVertically)
        ) {
            notice?.let { WearLiveNotice(it) }
            when (phase) {
                "paused" -> Text(
                    "En pausa",
                    color = WearOg.orange,
                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
                "review" -> Text(
                    "Revisar en el teléfono",
                    color = WearOg.label2,
                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            // Tiempo solo; km/kcal debajo alineados con las columnas outdoor.
            Text(
                LiveSportHistory.formatDuration(elapsed),
                style = MaterialTheme.typography.displayMedium.copy(
                    fontSize = scale.time,
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1,
                softWrap = false,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )

            if (usesGps) {
                val completedKm = (meters / 1000.0).toInt()
                val lastCompleted = live.optDouble("lastKilometerSeconds")
                    .takeIf { !live.isNull("lastKilometerSeconds") && it > 0 }
                    ?.toInt()
                val lastKm = wearLastKilometerSeconds(
                    completedSeconds = lastCompleted,
                    meters = meters,
                    elapsedSeconds = elapsed.toInt(),
                    completedKilometers = completedKm,
                    boundaryElapsedSeconds = if (completedKm > 0 && lastCompleted != null) {
                        (elapsed.toInt() - lastCompleted).coerceAtLeast(0)
                    } else 0
                )
                WearOutdoorSplitRow(
                    leftValue = wearDurationLabel(lastKm),
                    leftLabel = "último km",
                    rightValue = if (showSpeed) {
                        speed?.let { ReperaNumberFormat.decimal(it) }
                            ?: wearAverageSpeedLabel(meters, elapsed)
                    } else {
                        companionPaceLabel(meters, elapsed)
                    },
                    rightLabel = if (showSpeed) "media" else "ritmo medio",
                    valueSize = scale.split,
                    labelSize = scale.label
                )
                WearOutdoorKmKcalRow(
                    kmValue = if (meters > 0) ReperaNumberFormat.decimal(meters / 1000.0) else "—",
                    kcalValue = String.format("%.0f", displayedEnergyKcal(health?.second)),
                    valueSize = scale.inline
                )
            } else {
                WearLiveMetricInline(
                    label = "Kcal",
                    value = String.format("%.0f", displayedEnergyKcal(health?.second)),
                    valueSize = scale.inline
                )
            }

            WearHeartRateBpmLabel(
                bpm = health?.first,
                valueSize = scale.heart,
                modifier = Modifier.fillMaxWidth()
            )
            // Condiciones fuera del viewport live: ocupan mentón y recortan métricas.
        }

        WearHeartRateZoneBar(
            bpm = health?.first,
            rimBottomRight = true,
            modifier = Modifier
                .fillMaxSize()
                .zIndex(1f)
        )
    }
}

/** Tipografía live Wear según altura útil (todo visible, sin scroll). */
private data class WearLiveMetricsScale(
    val time: androidx.compose.ui.unit.TextUnit,
    val split: androidx.compose.ui.unit.TextUnit,
    val inline: androidx.compose.ui.unit.TextUnit,
    val heart: androidx.compose.ui.unit.TextUnit,
    val label: androidx.compose.ui.unit.TextUnit,
    val gap: androidx.compose.ui.unit.Dp
) {
    companion object {
        fun fit(usableHeight: androidx.compose.ui.unit.Dp): WearLiveMetricsScale {
            val h = usableHeight.value
            return when {
                h < 140f -> WearLiveMetricsScale(
                    time = 28.sp, split = 17.sp, inline = 17.sp, heart = 17.sp,
                    label = 9.sp, gap = 7.dp
                )
                h < 165f -> WearLiveMetricsScale(
                    time = 32.sp, split = 19.sp, inline = 18.sp, heart = 18.sp,
                    label = 10.sp, gap = 9.dp
                )
                else -> WearLiveMetricsScale(
                    time = 36.sp, split = 21.sp, inline = 19.sp, heart = 19.sp,
                    label = 10.sp, gap = 11.dp
                )
            }
        }
    }
}

@Composable
private fun WearLiveNotice(message: String) {
    Text(
        message,
        color = WearOg.yellow,
        style = MaterialTheme.typography.labelSmall,
        textAlign = TextAlign.Center,
        maxLines = 3,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier.fillMaxWidth()
    )
}

/** Controles 2×2: Pausar|Play · Finalizar / X roja · Audio. */
@Composable
private fun WearLiveControlsPage(
    phase: String,
    notice: String?,
    finishPending: Boolean,
    audioMuted: Boolean,
    onPauseResume: () -> Unit,
    onRequestFinish: () -> Unit,
    onRequestCancel: () -> Unit,
    onToggleAudioMuted: () -> Unit
) {
    val btn = IconButtonDefaults.DefaultButtonSize
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically)
    ) {
        notice?.let { WearLiveNotice(it) }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            FilledIconButton(
                onClick = onPauseResume,
                enabled = !finishPending,
                modifier = Modifier.touchTargetAwareSize(btn),
                colors = IconButtonDefaults.filledIconButtonColors()
            ) {
                Icon(
                    imageVector = if (phase == "paused") Icons.Filled.PlayArrow else Icons.Filled.Pause,
                    contentDescription = stringResource(
                        if (phase == "paused") R.string.wear_cd_resume else R.string.wear_cd_pause
                    )
                )
            }
            FilledIconButton(
                onClick = onRequestFinish,
                enabled = !finishPending,
                modifier = Modifier.touchTargetAwareSize(btn),
                colors = IconButtonDefaults.filledIconButtonColors()
            ) {
                Icon(imageVector = Icons.Filled.Flag, contentDescription = stringResource(R.string.wear_cd_finish))
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            FilledIconButton(
                onClick = onRequestCancel,
                enabled = !finishPending,
                modifier = Modifier.touchTargetAwareSize(btn),
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = WearOg.red,
                    contentColor = Color.White
                )
            ) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = stringResource(R.string.wear_cd_cancel_activity)
                )
            }
            FilledIconButton(
                onClick = onToggleAudioMuted,
                enabled = !finishPending,
                modifier = Modifier.touchTargetAwareSize(btn),
                colors = IconButtonDefaults.filledIconButtonColors()
            ) {
                Icon(
                    imageVector = if (audioMuted) {
                        Icons.AutoMirrored.Outlined.VolumeOff
                    } else {
                        Icons.AutoMirrored.Outlined.VolumeUp
                    },
                    contentDescription = stringResource(
                        if (audioMuted) R.string.wear_cd_unmute else R.string.wear_cd_mute
                    )
                )
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

/** Valor + etiqueta pegados (centrado en Wear circular). */
@Composable
internal fun WearLiveMetricInline(
    label: String,
    value: String,
    prominent: Boolean = false,
    modifier: Modifier = Modifier,
    valueSize: androidx.compose.ui.unit.TextUnit? = null
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Text(
            value,
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Bold,
                fontSize = valueSize ?: if (prominent) 22.sp else 18.sp
            ),
            maxLines = 1,
            softWrap = false
        )
        Text(
            label,
            color = WearOg.label2,
            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
            maxLines = 1
        )
    }
}

/** Alias: mismo layout inline centrado. */
@Composable
internal fun WearLiveMetricRow(label: String, value: String, prominent: Boolean = false) {
    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        WearLiveMetricInline(label = label, value = value, prominent = prominent)
    }
}

@Composable
internal fun WearOutdoorSplitRow(
    leftValue: String,
    leftLabel: String,
    rightValue: String,
    rightLabel: String,
    valueSize: androidx.compose.ui.unit.TextUnit = 22.sp,
    labelSize: androidx.compose.ui.unit.TextUnit = 10.sp
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        WearOutdoorSplitCell(
            value = leftValue,
            label = leftLabel,
            valueSize = valueSize,
            labelSize = labelSize,
            modifier = Modifier.weight(1f)
        )
        WearOutdoorSplitCell(
            value = rightValue,
            label = rightLabel,
            valueSize = valueSize,
            labelSize = labelSize,
            modifier = Modifier.weight(1f)
        )
    }
}

/** km (izq.) y Kcal (der.) en las mismas columnas que último km / ritmo medio. */
@Composable
internal fun WearOutdoorKmKcalRow(
    kmValue: String,
    kcalValue: String,
    valueSize: androidx.compose.ui.unit.TextUnit = 20.sp
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
            WearLiveMetricInline(label = "km", value = kmValue, valueSize = valueSize)
        }
        Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
            WearLiveMetricInline(label = "Kcal", value = kcalValue, valueSize = valueSize)
        }
    }
}

@Composable
private fun WearOutdoorSplitCell(
    value: String,
    label: String,
    modifier: Modifier = Modifier,
    valueSize: androidx.compose.ui.unit.TextUnit = 22.sp,
    labelSize: androidx.compose.ui.unit.TextUnit = 10.sp
) {
    // Pantalla redonda: etiqueta COMPLETA debajo del número (no al lado:
    // «último km» / «ritmo medio» se recortaban a «ú» / «k»).
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        Text(
            value,
            style = MaterialTheme.typography.titleLarge.copy(
                fontWeight = FontWeight.Bold,
                fontSize = valueSize
            ),
            maxLines = 1,
            softWrap = false,
            textAlign = TextAlign.Center
        )
        Text(
            label,
            color = WearOg.label2,
            style = MaterialTheme.typography.labelSmall.copy(
                fontWeight = FontWeight.SemiBold,
                fontSize = labelSize
            ),
            maxLines = 1,
            softWrap = false,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
internal fun WearHeartRateBpmLabel(
    bpm: Int?,
    prominent: Boolean = false,
    modifier: Modifier = Modifier,
    valueSize: androidx.compose.ui.unit.TextUnit? = null
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(3.dp, Alignment.CenterHorizontally)
    ) {
        Text(
            bpm?.toString() ?: "—",
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Bold,
                fontSize = valueSize ?: if (prominent) 22.sp else 20.sp
            ),
            maxLines = 1
        )
        Text(
            "LPM",
            color = WearOg.label2,
            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
            maxLines = 1
        )
    }
}

@Composable
internal fun WearHeartRateZoneBar(
    bpm: Int?,
    estimatedMaxBpm: Double = 190.0,
    prominent: Boolean = false,
    /** Ambiente / Always-On: misma barra, atenuada; no ocultar. */
    attenuated: Boolean = false,
    centered: Boolean = false,
    /**
     * Live métricas Wear: solo el arco de zonas en el marco inferior derecho
     * (el LPM va centrado aparte con [WearHeartRateBpmLabel]).
     */
    rimBottomRight: Boolean = false,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val configuredMax = context.getSharedPreferences("repera.wear.session",
        android.content.Context.MODE_PRIVATE).getInt("maxHeartRateBpm", 190)
    val effectiveMax = if (estimatedMaxBpm == 190.0) configuredMax.toDouble() else estimatedMaxBpm
    val zone = dev.repera.domain.LiveHeartRateZones.zone(bpm, effectiveMax)
    val description = if (zone != null && bpm != null) {
        "Última lectura: frecuencia cardíaca $bpm pulsaciones por minuto, zona $zone de 5"
    } else "Esperando la primera lectura de frecuencia cardíaca"
    val colors = listOf(
        Color(0xFF408CFF), Color(0xFF33D966), Color(0xFFF2D926),
        Color(0xFFFF8C1A), Color(0xFFF23333)
    )
    if (rimBottomRight) {
        WearHeartRateZoneRim(
            zone = zone,
            colors = colors,
            attenuated = attenuated,
            description = description,
            modifier = modifier
        )
        return
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .alpha(if (attenuated) 0.72f else 1f)
            .clearAndSetSemantics { contentDescription = description },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = if (centered) Arrangement.Center else Arrangement.Start
    ) {
        WearHeartRateBpmLabel(bpm = bpm, prominent = prominent)
        Spacer(Modifier.width(8.dp))
        Row(
            modifier = Modifier.weight(1f),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            colors.forEachIndexed { index, color ->
                val active = zone == index + 1
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(if (active) (if (attenuated) 10.dp else 12.dp) else 8.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(color.copy(alpha = when {
                            zone == null -> if (attenuated) 0.08f else 0.12f
                            active -> if (attenuated) 0.72f else 1f
                            else -> if (attenuated) 0.14f else 0.28f
                        }))
                )
            }
        }
    }
}

/** Cinco pastillas tangentes al bisel, arco inferior derecho (0° = este, sentido horario). */
@Composable
private fun WearHeartRateZoneRim(
    zone: Int?,
    colors: List<Color>,
    attenuated: Boolean,
    description: String,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    BoxWithConstraints(
        modifier = modifier
            .alpha(if (attenuated) 0.72f else 1f)
            .clearAndSetSemantics { contentDescription = description }
    ) {
        val w = constraints.maxWidth.toFloat()
        val h = constraints.maxHeight.toFloat()
        val cx = w / 2f
        val cy = h / 2f
        // Pegado al bisel derecho (0° = este, horario): arco estrecho fuera del texto.
        val insetPx = with(density) { 0.5.dp.toPx() }
        val radius = min(w, h) / 2f - insetPx
        val startDeg = -22f
        val endDeg = 55f
        colors.forEachIndexed { index, color ->
            val active = zone == index + 1
            val t = (index + 0.5f) / colors.size.toFloat()
            val deg = startDeg + t * (endDeg - startDeg)
            val rad = Math.toRadians(deg.toDouble())
            val segW = with(density) { if (active) 11.dp.toPx() else 9.dp.toPx() }
            val segH = with(density) { if (active) 4.5.dp.toPx() else 3.5.dp.toPx() }
            val x = cx + (radius * cos(rad)).toFloat()
            val y = cy + (radius * sin(rad)).toFloat()
            val alpha = when {
                zone == null -> if (attenuated) 0.10f else 0.18f
                active -> if (attenuated) 0.72f else 1f
                else -> if (attenuated) 0.16f else 0.30f
            }
            Box(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .offset {
                        IntOffset(
                            (x - segW / 2f).roundToInt(),
                            (y - segH / 2f).roundToInt()
                        )
                    }
                    .graphicsLayer { rotationZ = deg + 90f }
                    .size(
                        width = with(density) { segW.toDp() },
                        height = with(density) { segH.toDp() }
                    )
                    .clip(RoundedCornerShape(50))
                    .background(color.copy(alpha = alpha))
            )
        }
    }
}

internal fun wearDurationLabel(seconds: Int?): String {
    val n = seconds?.takeIf { it > 0 } ?: return "—"
    val h = n / 3600
    val m = (n % 3600) / 60
    val s = n % 60
    return if (h > 0) String.format("%d:%02d:%02d", h, m, s)
    else String.format("%d:%02d", m, s)
}

internal fun wearAverageSpeedLabel(meters: Double, elapsedSeconds: Double): String {
    if (meters <= 20 || elapsedSeconds <= 0) return "—"
    return ReperaNumberFormat.decimal(meters / elapsedSeconds * 3.6)
}

/** Último km cerrado o proyección del km en curso (≥40 m). */
internal fun wearLastKilometerSeconds(
    completedSeconds: Int?,
    meters: Double,
    elapsedSeconds: Int,
    completedKilometers: Int,
    boundaryElapsedSeconds: Int
): Int? {
    if (completedSeconds != null && completedSeconds > 0) return completedSeconds
    val metersInKm = meters - completedKilometers * 1000.0
    val elapsedInKm = elapsedSeconds - boundaryElapsedSeconds
    if (metersInKm < 40 || elapsedInKm <= 0) return null
    return maxOf(1, ((elapsedInKm.toDouble() / metersInKm) * 1000.0).toInt())
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
