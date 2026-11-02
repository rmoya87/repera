package dev.repera.wear

import androidx.compose.foundation.focusable
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
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.PlayArrow
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
import androidx.wear.compose.material3.IconButton
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
    val backSize = IconButtonDefaults.SmallButtonSize

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
            .focusable(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = {
                    if (choosingMode) onBack() else choosingMode = true
                },
                modifier = Modifier
                    .touchTargetAwareSize(backSize)
                    .semantics {
                        contentDescription = if (choosingMode) "Volver" else "Cambiar tipo"
                    }
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                    contentDescription = null,
                    modifier = Modifier.size(IconButtonDefaults.iconSizeFor(backSize))
                )
            }
            WearHubScalingTitle(
                text = "Temporizador",
                modifier = Modifier.weight(1f),
                maxFontSp = 17.sp,
                minFontSp = 14.sp,
                maxLines = 1
            )
            Spacer(Modifier.size(backSize))
        }

        if (choosingMode) {
            Text(
                "Elige un temporizador",
                color = Color.White,
                style = MaterialTheme.typography.titleSmall.copy(
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold
                ),
                textAlign = TextAlign.Center
            )

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
            Text(
                when (draft.modeRaw) {
                    "up" -> "Cronómetro"
                    "intervals" -> "Intervalos"
                    else -> "Cuenta atrás"
                },
                color = Color.White,
                style = MaterialTheme.typography.titleMedium.copy(
                    fontSize = 19.sp,
                    fontWeight = FontWeight.Bold
                ),
                textAlign = TextAlign.Center
            )

            when (draft.modeRaw) {
                "intervals" -> {
                    WearMetricStepper(
                        label = "Rondas",
                        value = draft.rounds.toString(),
                        onMinus = { onDraftChange(draft.copy(rounds = (draft.rounds - 1).coerceAtLeast(1))) },
                        onPlus = { onDraftChange(draft.copy(rounds = (draft.rounds + 1).coerceAtMost(99))) }
                    )
                    WearMetricStepper(
                        label = "Trabajo · segundos",
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
        colors = if (selected) {
            ButtonDefaults.buttonColors(containerColor = WearOg.accent, contentColor = WearOg.onAccent)
        } else {
            ButtonDefaults.filledTonalButtonColors(containerColor = WearOg.card, contentColor = Color.White)
        }
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    title,
                    modifier = Modifier.weight(1f),
                    color = if (selected) WearOg.onAccent else Color.White,
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
                        tint = WearOg.onAccent
                    )
                }
            }
            Text(
                subtitle,
                color = if (selected) WearOg.onAccent.copy(alpha = 0.75f) else WearOg.label2,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp),
                maxLines = 1,
                softWrap = false
            )
        }
    }
}

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
            color = Color.White,
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
    onDiscard: () -> Unit
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
            onFinished(draft.toDetails(), startedAt, System.currentTimeMillis())
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
    val pager = rememberPagerState(pageCount = { 2 })
    var confirmDiscard by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxSize()) {
        HorizontalPager(state = pager, modifier = Modifier.fillMaxSize()) { page ->
            if (page == 0) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 12.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterVertically)
                ) {
                    Text(
                        if (paused != 0) "En pausa" else when (draft.modeRaw) {
                            "up" -> "Cronómetro"
                            "down" -> "Cuenta atrás"
                            else -> if (resting) "Descanso" else "Trabajo"
                        },
                        color = when {
                            paused != 0 -> WearOg.yellow
                            resting -> WearOg.accent
                            else -> Color.White
                        },
                        style = MaterialTheme.typography.titleSmall.copy(
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold
                        ),
                        maxLines = 1,
                        textAlign = TextAlign.Center
                    )
                    if (draft.modeRaw == "intervals") {
                        Text(
                            "Ronda " + roundNumber + "/" + draft.rounds,
                            color = WearOg.label2,
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 13.sp),
                            maxLines = 1
                        )
                    }
                    WearTimerAdaptiveClock(display)
                    if (draft.modeRaw == "intervals") {
                        Text(
                            "Total " + wearClockLabel(remaining),
                            color = WearOg.label2,
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp),
                            maxLines = 1
                        )
                    }
                    Text(
                        "Desliza para controles ›",
                        color = WearOg.label2,
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp),
                        textAlign = TextAlign.Center,
                        maxLines = 1
                    )
                }
            } else {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp, Alignment.CenterVertically)
                ) {
                    Text("Controles", style = MaterialTheme.typography.titleSmall, maxLines = 1)
                    FilledIconButton(
                        onClick = { paused = if (paused == 0) 1 else 0 },
                        modifier = Modifier.touchTargetAwareSize(IconButtonDefaults.DefaultButtonSize),
                        colors = IconButtonDefaults.filledIconButtonColors()
                    ) {
                        Icon(
                            imageVector = if (paused == 0) {
                                Icons.Outlined.Pause
                            } else {
                                Icons.Outlined.PlayArrow
                            },
                            contentDescription = if (paused == 0) "Pausar" else "Reanudar"
                        )
                    }
                    // TextButton Wear es circular y recorta a «Descar».
                    Button(
                        onClick = { confirmDiscard = true },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(44.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color.Transparent,
                            contentColor = WearOg.red
                        )
                    ) {
                        WearButtonLabel("Descartar", color = WearOg.red)
                    }
                }
            }
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
