package dev.repera.wear

import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.TextButton
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
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            TextButton(onClick = onBack) { Text("✕", color = WearOg.accent) }
            Text("Temporizador", style = MaterialTheme.typography.labelMedium)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            listOf("up" to "Arriba", "down" to "Abajo", "intervals" to "Intervalos").forEach { (wire, label) ->
                TextButton(onClick = { onDraftChange(draft.copy(modeRaw = wire)) }) {
                    Text(
                        if (draft.modeRaw == wire) "$label ✓" else label,
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }
        }
        when (draft.modeRaw) {
            "intervals" -> {
                WearMetricStepper("Rondas", "${draft.rounds}",
                    onMinus = { onDraftChange(draft.copy(rounds = (draft.rounds - 1).coerceAtLeast(1))) },
                    onPlus = { onDraftChange(draft.copy(rounds = (draft.rounds + 1).coerceAtMost(99))) })
                WearMetricStepper("Trabajo (s)", "${draft.workSeconds}",
                    onMinus = { onDraftChange(draft.copy(workSeconds = (draft.workSeconds - 5).coerceAtLeast(5))) },
                    onPlus = { onDraftChange(draft.copy(workSeconds = (draft.workSeconds + 5).coerceAtMost(600))) })
                WearMetricStepper("Descanso (s)", "${draft.restSeconds}",
                    onMinus = { onDraftChange(draft.copy(restSeconds = (draft.restSeconds - 5).coerceAtLeast(0))) },
                    onPlus = { onDraftChange(draft.copy(restSeconds = (draft.restSeconds + 5).coerceAtMost(600))) })
            }
            else -> {
                WearMetricStepper("Minutos", "${draft.durationMinutes}",
                    onMinus = { onDraftChange(draft.copy(durationMinutes = (draft.durationMinutes - 1).coerceAtLeast(1))) },
                    onPlus = { onDraftChange(draft.copy(durationMinutes = (draft.durationMinutes + 1).coerceAtMost(180))) })
            }
        }
        WearPrimaryButton("Iniciar") { onStart() }
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
    Column(
        modifier = Modifier.fillMaxWidth().padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(
            when (draft.modeRaw) {
                "up" -> "Arriba"
                "down" -> "Abajo"
                else -> "Intervalos"
            },
            style = MaterialTheme.typography.labelMedium
        )
        WearClockText(display)
        if (!audioMuted && draft.modeRaw == "down" && remaining in 1..3) {
            Text("!", color = WearOg.yellow, style = MaterialTheme.typography.titleLarge)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TextButton(onClick = {
                discarded = 1
                onDiscard()
            }) { Text("Descartar", color = WearOg.red) }
            TextButton(onClick = { paused = if (paused == 0) 1 else 0 }) {
                Text(if (paused == 0) "Pausar" else "Reanudar")
            }
        }
    }
}
