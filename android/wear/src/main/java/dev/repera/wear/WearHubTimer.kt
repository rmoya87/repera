package dev.repera.wear

import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
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
    val focus = remember { FocusRequester() }
    val backSize = IconButtonDefaults.SmallButtonSize
    LaunchedEffect(Unit) { focus.requestFocus() }
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            // Insets generosos: la fila de 3 chips se cortaba en esfera redonda.
            .padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 20.dp)
            .onRotaryScrollEvent { false }
            .focusRequester(focus)
            .focusable(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier
                    .touchTargetAwareSize(backSize)
                    .semantics { contentDescription = "Volver" }
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
                maxFontSp = 16.sp,
                minFontSp = 12.sp,
                maxLines = 1
            )
            Spacer(Modifier.size(backSize))
        }

        // Modos a ancho completo (como Picker de watchOS), no 3 chips aplastados.
        listOf(
            "up" to "Arriba",
            "down" to "Abajo",
            "intervals" to "Intervalos"
        ).forEach { (wire, label) ->
            val selected = draft.modeRaw == wire
            Button(
                onClick = { onDraftChange(draft.copy(modeRaw = wire)) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(40.dp),
                colors = if (selected) {
                    ButtonDefaults.buttonColors()
                } else {
                    ButtonDefaults.filledTonalButtonColors()
                }
            ) {
                WearButtonLabel(label)
            }
        }

        when (draft.modeRaw) {
            "intervals" -> {
                WearMetricStepper(
                    label = "Rondas",
                    value = "${draft.rounds}",
                    onMinus = { onDraftChange(draft.copy(rounds = (draft.rounds - 1).coerceAtLeast(1))) },
                    onPlus = { onDraftChange(draft.copy(rounds = (draft.rounds + 1).coerceAtMost(99))) }
                )
                WearMetricStepper(
                    label = "Trabajo s",
                    value = "${draft.workSeconds}",
                    onMinus = {
                        onDraftChange(draft.copy(workSeconds = (draft.workSeconds - 5).coerceAtLeast(5)))
                    },
                    onPlus = {
                        onDraftChange(draft.copy(workSeconds = (draft.workSeconds + 5).coerceAtMost(600)))
                    }
                )
                WearMetricStepper(
                    label = "Descanso s",
                    value = "${draft.restSeconds}",
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
                    value = "${draft.durationMinutes}",
                    onMinus = {
                        onDraftChange(
                            draft.copy(durationMinutes = (draft.durationMinutes - 1).coerceAtLeast(1))
                        )
                    },
                    onPlus = {
                        onDraftChange(
                            draft.copy(durationMinutes = (draft.durationMinutes + 1).coerceAtMost(180))
                        )
                    }
                )
            }
        }

        Button(
            onClick = onStart,
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
                .semantics { contentDescription = "Comenzar temporizador" }
        ) {
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Outlined.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(Modifier.size(6.dp))
                    Text(
                        "Comenzar",
                        maxLines = 1,
                        softWrap = false,
                        style = MaterialTheme.typography.titleSmall
                    )
                }
            }
        }
        Spacer(Modifier.height(8.dp))
    }
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

    val display = when (draft.modeRaw) {
        "up" -> elapsed
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
                    verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically)
                ) {
                    WearHubScalingTitle(
                        text = when (draft.modeRaw) {
                            "up" -> "Arriba"
                            "down" -> "Abajo"
                            else -> "Intervalos"
                        },
                        maxFontSp = 14.sp,
                        minFontSp = 11.sp,
                        maxLines = 1
                    )
                    WearClockText(display)
                    if (!audioMuted && draft.modeRaw == "down" && remaining in 1..3) {
                        Text("!", color = WearOg.yellow, style = MaterialTheme.typography.titleLarge)
                    }
                    Text(
                        "Desliza › controles",
                        color = WearOg.label2,
                        style = MaterialTheme.typography.labelSmall,
                        textAlign = TextAlign.Center
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
