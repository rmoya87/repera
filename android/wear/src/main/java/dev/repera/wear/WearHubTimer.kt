package dev.repera.wear

import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.VolumeOff
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.ui.res.stringResource
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.FilledIconButton
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.IconButtonDefaults
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.touchTargetAwareSize
import dev.repera.domain.TimerCompletionDetails
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

internal data class WearTimerDraft(
    val modeRaw: String = "up",
    val durationMinutes: Int = 5,
    val rounds: Int = 8,
    val workSeconds: Int = 40,
    val restSeconds: Int = 20
) {
    fun toDetails(): TimerCompletionDetails = TimerCompletionDetails(
        modeRaw = modeRaw,
        configuredSeconds = when (modeRaw) {
            "intervals" -> (rounds * (workSeconds + restSeconds)).coerceAtLeast(1)
            else -> (durationMinutes * 60).coerceAtLeast(1)
        },
        rounds = if (modeRaw == "intervals") rounds else 1,
        workSeconds = if (modeRaw == "intervals") workSeconds else 0,
        restSeconds = if (modeRaw == "intervals") restSeconds else 0,
        countdownSeconds = 0
    )
}

@Composable
internal fun WearTimerConfigScreen(
    draft: WearTimerDraft,
    onDraftChange: (WearTimerDraft) -> Unit,
    onStart: () -> Unit,
    onBack: () -> Unit
) {
    var choosingMode by remember { mutableStateOf(true) }
    val scrollState = rememberScrollState()
    val scope = rememberCoroutineScope()
    val focus = remember { FocusRequester() }

    // La corona desplaza realmente el contenido, también en los relojes más pequeños.
    LaunchedEffect(choosingMode) {
        scrollState.scrollTo(0)
        focus.requestFocus()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(scrollState)
            .padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 22.dp)
            .onRotaryScrollEvent {
                scope.launch { scrollState.scrollBy(it.verticalScrollPixels) }
                true
            }
            .focusRequester(focus)
            .focusable()
            .pointerInput(choosingMode) {
                var swipeRight = 0f
                detectHorizontalDragGestures(
                    onHorizontalDrag = { _, amount -> swipeRight += amount },
                    onDragEnd = {
                        if (swipeRight > 55f) {
                            if (choosingMode) onBack() else choosingMode = true
                        }
                        swipeRight = 0f
                    },
                    onDragCancel = { swipeRight = 0f }
                )
            }
            .semantics {
                customActions = listOf(
                    CustomAccessibilityAction(
                        label = if (choosingMode) "Volver" else "Cambiar tipo",
                        action = {
                            if (choosingMode) onBack() else choosingMode = true
                            true
                        }
                    )
                )
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Solo una cabecera: la modalidad sustituye «Temporizador» al elegirla.
        // El gesto a la derecha retrocede al selector o al hub, según el estado.
        WearHubScalingTitle(
            text = if (choosingMode) "Temporizador" else when (draft.modeRaw) {
                "up" -> "Cronómetro"
                "intervals" -> "Intervalos"
                else -> "Cuenta atrás"
            },
            modifier = Modifier.fillMaxWidth(),
            maxFontSp = 17.sp,
            minFontSp = 14.sp,
            maxLines = 1
        )

        if (choosingMode) {
            WearTimerModeOption(
                title = "Cuenta atrás",
                subtitle = "Desde un tiempo",
                selected = draft.modeRaw == "down"
            ) {
                onDraftChange(draft.copy(modeRaw = "down"))
                choosingMode = false
            }
            WearTimerModeOption(
                title = "Cronómetro",
                subtitle = "Tiempo ascendente",
                selected = draft.modeRaw == "up"
            ) {
                onDraftChange(draft.copy(modeRaw = "up"))
                choosingMode = false
            }
            WearTimerModeOption(
                title = "Intervalos",
                subtitle = "Trabajo y descanso",
                selected = draft.modeRaw == "intervals"
            ) {
                onDraftChange(draft.copy(modeRaw = "intervals"))
                choosingMode = false
            }
        } else {
            when (draft.modeRaw) {
                "intervals" -> {
                    WearMetricStepper(
                        label = "Rondas",
                        flatControls = true,
                        value = draft.rounds.toString(),
                        onMinus = { onDraftChange(draft.copy(rounds = (draft.rounds - 1).coerceAtLeast(1))) },
                        onPlus = { onDraftChange(draft.copy(rounds = (draft.rounds + 1).coerceAtMost(99))) }
                    )
                    WearMetricStepper(
                        label = "Trabajo · segundos",
                        flatControls = true,
                        value = draft.workSeconds.toString(),
                        onMinus = {
                            onDraftChange(draft.copy(workSeconds = (draft.workSeconds - 5).coerceAtLeast(5)))
                        },
                        onPlus = {
                            onDraftChange(draft.copy(workSeconds = (draft.workSeconds + 5).coerceAtMost(600)))
                        }
                    )
                    WearMetricStepper(
                        label = "Descanso · segundos",
                        flatControls = true,
                        value = draft.restSeconds.toString(),
                        onMinus = {
                            onDraftChange(draft.copy(restSeconds = (draft.restSeconds - 5).coerceAtLeast(0)))
                        },
                        onPlus = {
                            onDraftChange(draft.copy(restSeconds = (draft.restSeconds + 5).coerceAtMost(600)))
                        }
                    )
                }
                else -> {
                    WearMetricStepper(
                        label = "Minutos",
                        flatControls = true,
                        value = draft.durationMinutes.toString(),
                        onMinus = {
                            onDraftChange(draft.copy(durationMinutes = (draft.durationMinutes - 1).coerceAtLeast(1)))
                        },
                        onPlus = {
                            onDraftChange(draft.copy(durationMinutes = (draft.durationMinutes + 1).coerceAtMost(180)))
                        }
                    )
                }
            }

            Button(
                onClick = onStart,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .semantics { contentDescription = "Comenzar temporizador" },
                colors = ButtonDefaults.buttonColors(
                    containerColor = WearOg.accent,
                    contentColor = WearOg.onAccent
                )
            ) {
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Outlined.PlayArrow,
                            contentDescription = null,
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(Modifier.size(4.dp))
                        Text(
                            "Comenzar",
                            maxLines = 1,
                            softWrap = false,
                            color = WearOg.onAccent,
                            style = MaterialTheme.typography.titleSmall.copy(
                                fontSize = 16.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        )
                    }
                }
            }
        }
        Spacer(Modifier.height(6.dp))
    }
}

@Composable
private fun WearTimerModeOption(
    title: String,
    subtitle: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 62.dp)
            .semantics { contentDescription = title + ". " + subtitle },
        // Sin fondos de tarjetas; el color y el check distinguen el modo seleccionado.
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.Transparent,
            contentColor = if (selected) WearOg.accent else Color.White
        )
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    title,
                    modifier = Modifier.weight(1f),
                    color = if (selected) WearOg.accent else Color.White,
                    maxLines = 1,
                    softWrap = false,
                    style = MaterialTheme.typography.titleSmall.copy(
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                )
                if (selected) {
                    Icon(
                        imageVector = Icons.Outlined.Check,
                        contentDescription = null,
                        modifier = Modifier.size(17.dp),
                        tint = WearOg.accent
                    )
                }
            }
            Text(
                subtitle,
                color = if (selected) WearOg.accent else WearOg.label2,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp),
                maxLines = 1,
                softWrap = false
            )
        }
    }
}

private val WearTimerRed = Color(0xFFFF382E) // DigitalClockDisplay iPhone
private val WearTimerRoundGreen = Color(0xFF38FF59)

/** Reloj ajustable: 180 minutos y formatos largos no se recortan en una esfera pequeña. */
@Composable
private fun WearTimerAdaptiveClock(seconds: Int) {
    BasicText(
        text = wearClockLabel(seconds),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 3.dp)
            .semantics { contentDescription = "Tiempo " + wearClockLabel(seconds) },
        style = MaterialTheme.typography.displayMedium.copy(
            color = WearTimerRed,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        ),
        maxLines = 1,
        softWrap = false,
        overflow = TextOverflow.Clip,
        autoSize = TextAutoSize.StepBased(
            minFontSize = 27.sp,
            maxFontSize = 43.sp,
            stepSize = 1.sp
        )
    )
}

@Composable
internal fun WearTimerRunScreen(
    draft: WearTimerDraft,
    audioMuted: Boolean,
    onFinished: (TimerCompletionDetails, Long, Long) -> Unit,
    onDiscard: () -> Unit,
    onMirror: (String, Int, Int) -> Unit = { _, _, _ -> },
    onToggleAudioMuted: () -> Unit = {},
    remoteCommand: String? = null,
    remoteCommandEpoch: Int = 0
) {
    val totalSeconds = remember(draft) {
        when (draft.modeRaw) {
            "intervals" -> draft.rounds * (draft.workSeconds + draft.restSeconds)
            else -> draft.durationMinutes * 60
        }.coerceAtLeast(1)
    }
    var elapsed by remember { mutableIntStateOf(0) }
    var remaining by remember { mutableIntStateOf(totalSeconds) }
    var paused by remember { mutableIntStateOf(0) }
    var completed by remember { mutableIntStateOf(0) }
    var discarded by remember { mutableIntStateOf(0) }
    val startedAt = remember { System.currentTimeMillis() }

    LaunchedEffect(paused, completed, discarded, draft.modeRaw) {
        while (completed == 0 && discarded == 0 && paused == 0) {
            delay(1000)
            when (draft.modeRaw) {
                "up" -> {
                    elapsed = (elapsed + 1).coerceAtMost(totalSeconds)
                    if (elapsed >= totalSeconds) completed = 1
                }
                "down", "intervals" -> {
                    remaining = (remaining - 1).coerceAtLeast(0)
                    elapsed = totalSeconds - remaining
                    if (remaining <= 0) completed = 1
                }
            }
        }
        if (completed == 1 && discarded == 0) {
            onFinished(draft.toDetails().copy(countdownSeconds = elapsed), startedAt, System.currentTimeMillis())
        }
    }

    // En intervalos, el reloj muestra la fase actual y no una cuenta global confusa.
    val cycleSeconds = (draft.workSeconds + draft.restSeconds).coerceAtLeast(1)
    val phasePosition = elapsed % cycleSeconds
    val resting = draft.modeRaw == "intervals" &&
        draft.restSeconds > 0 && phasePosition >= draft.workSeconds
    val roundNumber = (elapsed / cycleSeconds + 1).coerceAtMost(draft.rounds)
    val phaseRemaining = if (resting) {
        cycleSeconds - phasePosition
    } else {
        draft.workSeconds - phasePosition
    }
    val display = when (draft.modeRaw) {
        "up" -> elapsed
        "intervals" -> phaseRemaining.coerceAtLeast(0)
        else -> remaining
    }
    // Controles ← Reloj → Now Playing. Izquierda→derecha = Pausar/Finalizar.
    LaunchedEffect(elapsed, paused, completed, discarded) {
        if (completed == 0 && discarded == 0 && (elapsed % 3 == 0 || paused != 0)) {
            onMirror(if (paused == 0) "running" else "paused", elapsed, roundNumber)
        }
    }
    LaunchedEffect(remoteCommandEpoch) {
        if (remoteCommandEpoch == 0 || completed != 0 || discarded != 0) return@LaunchedEffect
        when (remoteCommand) {
            "pause" -> paused = 1
            "resume" -> paused = 0
            "finish" -> completed = 1
        }
    }
    val pager = rememberPagerState(initialPage = 1, pageCount = { 3 })
    val metricsScroll = rememberScrollState()
    val metricsFocus = remember { FocusRequester() }
    val metricsScope = rememberCoroutineScope()
    LaunchedEffect(pager.currentPage) {
        if (pager.currentPage == 1) metricsFocus.requestFocus()
    }
    var confirmFinish by remember { mutableStateOf(false) }
    var confirmDiscard by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxSize()) {
        HorizontalPager(state = pager, modifier = Modifier.fillMaxSize()) { page ->
            when (page) {
                0 -> {
                    val btn = IconButtonDefaults.DefaultButtonSize
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(horizontal = 14.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            FilledIconButton(
                                onClick = { paused = if (paused == 0) 1 else 0 },
                                modifier = Modifier.touchTargetAwareSize(btn),
                                colors = IconButtonDefaults.filledIconButtonColors()
                            ) {
                                Icon(
                                    imageVector = if (paused == 0) {
                                        Icons.Outlined.Pause
                                    } else {
                                        Icons.Outlined.PlayArrow
                                    },
                                    contentDescription = stringResource(
                                        if (paused == 0) R.string.wear_cd_pause else R.string.wear_cd_resume
                                    )
                                )
                            }
                            FilledIconButton(
                                onClick = { confirmFinish = true },
                                modifier = Modifier.touchTargetAwareSize(btn),
                                colors = IconButtonDefaults.filledIconButtonColors()
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.Flag,
                                    contentDescription = stringResource(R.string.wear_cd_finish)
                                )
                            }
                        }
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            FilledIconButton(
                                onClick = { confirmDiscard = true },
                                modifier = Modifier.touchTargetAwareSize(btn),
                                colors = IconButtonDefaults.filledIconButtonColors(
                                    containerColor = WearOg.red,
                                    contentColor = Color.White
                                )
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.Close,
                                    contentDescription = stringResource(R.string.wear_cd_discard)
                                )
                            }
                            FilledIconButton(
                                onClick = onToggleAudioMuted,
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
                2 -> WearNowPlayingPage()
                else -> Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(metricsScroll)
                        .onRotaryScrollEvent {
                            metricsScope.launch { metricsScroll.scrollBy(it.verticalScrollPixels) }
                            true
                        }
                        .focusRequester(metricsFocus)
                        .focusable()
                        .padding(horizontal = 14.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(9.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(175.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterVertically)
                    ) {
                        if (draft.modeRaw == "intervals") {
                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(2.dp)
                            ) {
                                Text(
                                    roundNumber.toString(),
                                    color = WearTimerRoundGreen,
                                    style = MaterialTheme.typography.titleLarge.copy(
                                        fontSize = 22.sp, fontWeight = FontWeight.Bold
                                    ),
                                    maxLines = 1,
                                    textAlign = TextAlign.Center
                                )
                                BasicText(
                                    text = wearClockLabel(display),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .semantics {
                                            contentDescription = "Tiempo " + wearClockLabel(display)
                                        },
                                    style = MaterialTheme.typography.displayMedium.copy(
                                        color = WearTimerRed,
                                        fontWeight = FontWeight.Bold,
                                        textAlign = TextAlign.Center
                                    ),
                                    maxLines = 1,
                                    softWrap = false,
                                    overflow = TextOverflow.Clip,
                                    autoSize = TextAutoSize.StepBased(
                                        minFontSize = 28.sp, maxFontSize = 48.sp, stepSize = 1.sp
                                    )
                                )
                                Text(
                                    if (resting) "DESCANSAR" else "TRABAJAR",
                                    color = WearOg.accent,
                                    style = MaterialTheme.typography.labelSmall.copy(
                                        fontSize = 12.sp, fontWeight = FontWeight.SemiBold
                                    ),
                                    maxLines = 1,
                                    textAlign = TextAlign.Center
                                )
                            }
                        } else {
                            Text(
                                if (paused != 0) "En pausa" else if (draft.modeRaw == "up")
                                    "Cronómetro" else "Cuenta atrás",
                                color = if (paused != 0) WearOg.yellow else WearOg.accent,
                                style = MaterialTheme.typography.titleSmall.copy(
                                    fontSize = 16.sp, fontWeight = FontWeight.SemiBold
                                ),
                                maxLines = 1,
                                textAlign = TextAlign.Center
                            )
                            WearTimerAdaptiveClock(display)
                        }
                        if (paused != 0 && draft.modeRaw == "intervals") {
                            Text("En pausa", color = WearOg.yellow,
                                style = MaterialTheme.typography.labelSmall)
                        }
                    }
                    Text(
                        "Métricas",
                        style = MaterialTheme.typography.titleSmall.copy(fontSize = 16.sp),
                        modifier = Modifier.padding(top = 12.dp)
                    )
                    WearStatsLine("Transcurrido", wearClockLabel(elapsed))
                    if (draft.modeRaw != "up") {
                        WearStatsLine("Restante", wearClockLabel(remaining))
                    }
                    if (draft.modeRaw == "intervals") {
                        WearStatsLine("Ronda", roundNumber.toString() + "/" + draft.rounds)
                        WearStatsLine("Fase", if (resting) "Descanso" else "Trabajo")
                        WearStatsLine("Fase restante", wearClockLabel(phaseRemaining.coerceAtLeast(0)))
                    }
                    Spacer(Modifier.height(24.dp))
                }
            }
        }
        if (confirmFinish) {
            WearConfirmFinishModal(
                title = "¿Finalizar temporizador?",
                confirmLabel = "Guardar",
                onCancel = { confirmFinish = false },
                onConfirm = {
                    confirmFinish = false
                    // Evitar que el efecto de fin automático envíe el mismo registro.
                    discarded = 1
                    onFinished(
                        draft.toDetails().copy(countdownSeconds = elapsed),
                        startedAt,
                        System.currentTimeMillis()
                    )
                }
            )
        }
        if (confirmDiscard) {
            WearConfirmFinishModal(
                title = "¿Descartar temporizador?",
                confirmLabel = "Descartar",
                destructive = true,
                onCancel = { confirmDiscard = false },
                onConfirm = {
                    confirmDiscard = false
                    discarded = 1
                    onDiscard()
                }
            )
        }
    }
}
