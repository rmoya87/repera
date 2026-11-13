package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import dev.repera.domain.WodFormat
import kotlinx.coroutines.delay

/**
 * Dock inferior tras Minimizar (paridad iOS minimizedTimerDock):
 * tap en tiempo → fullscreen; Continuar/Pausar + Finalizar.
 * WOD y bloque libre (`manualConfig`).
 */
@Composable
internal fun MinimizedWodClockBar(
    active: ActiveWorkout,
    timer: WodTimerState?,
    busy: Boolean,
    onExpand: () -> Unit,
    onTimerAction: (String) -> Unit,
    onTimerTick: () -> Unit,
    onFinish: () -> Unit,
    modifier: Modifier = Modifier,
    manualConfig: ManualBlockTimerConfig? = null,
    launchConfig: BlockClockLaunchConfig? = null,
) {
    val wod = active.wod
    val launch = launchConfig ?: manualConfig?.let { BlockClockLaunchConfig.fromManual(it) }
    val spec = when {
        launch != null -> launch.toSpec()
        wod != null -> WodClockSpec(
            format = WodFormat.fromWire(wod.format),
            blockTimeCapMinutes = wod.timeCapMinutes,
            blockTimeCapSeconds = wod.timeCapSeconds,
            repeatedWorkSeconds = wod.repeatedWorkSeconds,
            repeatedRestSeconds = wod.repeatedRestSeconds,
            repeatCount = wod.repeatCount,
            intervalSeconds = wod.intervalSeconds,
            rounds = wod.rounds,
            workSeconds = wod.workSeconds,
            restSeconds = wod.restSeconds,
            restBetweenRoundsSeconds = wod.restBetweenRoundsSeconds,
            stations = wod.movements.count { !it.isRest }.coerceAtLeast(1)
        )
        else -> return
    }
    val elapsedClock = timer?.elapsedSeconds ?: 0
    val face = WodClock.face(spec, elapsedClock)
    val format = launch?.let { WodFormat.fromWire(it.formatWire) }
        ?: wod?.let { WodFormat.fromWire(it.format) }
        ?: WodFormat.TABATA
    val intervalFormats = setOf(
        WodFormat.EMOM, WodFormat.DEATH_BY, WodFormat.TABATA, WodFormat.CIRCUIT
    )
    val roundNumber = if (format in intervalFormats && !face.finishedIntervals)
        WodClock.activeIntervalIndex(spec, elapsedClock) + 1 else null
    LaunchedEffect(active.id, active.index, timer?.running) {
        if (timer?.running == true) {
            while (true) {
                delay(250)
                onTimerTick()
            }
        }
    }
    val mm = face.primarySeconds / 60
    val ss = face.primarySeconds % 60
    val timeLabel = "%d:%02d".format(java.util.Locale.ROOT, mm, ss)
    val roundLabel = roundNumber?.let { "Ronda $it" }
        ?: (face.label ?: wod?.title ?: "Temporizador")
    val running = timer?.running == true
    Row(
        modifier
            .fillMaxWidth()
            .background(Color.Black, RoundedCornerShape(18.dp))
            .padding(horizontal = 12.dp, vertical = 10.dp)
            .testTag("minimized_wod_clock_bar"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Column(
            Modifier
                .weight(1f)
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClick = onExpand
                )
                .testTag("minimized_wod_expand")
        ) {
            Text(
                roundLabel,
                color = brandGreen,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                timeLabel,
                color = Color.White,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold
            )
        }
        TextButton(
            onClick = {
                when {
                    running -> onTimerAction("pause")
                    face.finishedIntervals -> {
                        // Cap ya alcanzado: reiniciar para poder Continuar de verdad.
                        onTimerAction("reset")
                        onTimerAction("start")
                    }
                    else -> onTimerAction("start")
                }
            },
            enabled = !busy,
            modifier = Modifier.testTag("minimized_wod_continue")
        ) {
            Text(
                if (running) "Pausar" else "Continuar",
                color = Color.White,
                fontWeight = FontWeight.SemiBold
            )
        }
        TextButton(
            onClick = onFinish,
            enabled = !busy,
            modifier = Modifier.testTag("minimized_wod_finish")
        ) {
            Text("Finalizar", color = brandGreen, fontWeight = FontWeight.Bold)
        }
    }
}
