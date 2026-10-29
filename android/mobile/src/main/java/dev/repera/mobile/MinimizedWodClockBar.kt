package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
 * I-42 barra flotante tras Minimizar: Ronda · mm:ss, tap → fullscreen,
 * Terminar / Continuar.
 */
@Composable
internal fun MinimizedWodClockBar(
    active: ActiveWorkout,
    timer: WodTimerState?,
    busy: Boolean,
    onExpand: () -> Unit,
    onTimerAction: (String) -> Unit,
    onTimerTick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val wod = active.wod ?: return
    val elapsedClock = timer?.elapsedSeconds ?: 0
    val spec = WodClockSpec(
        format = WodFormat.fromWire(wod.format),
        blockTimeCapMinutes = wod.timeCapMinutes,
        intervalSeconds = wod.intervalSeconds,
        rounds = wod.rounds,
        workSeconds = wod.workSeconds,
        restSeconds = wod.restSeconds,
        restBetweenRoundsSeconds = wod.restBetweenRoundsSeconds,
        stations = wod.movements.count { !it.isRest }.coerceAtLeast(1)
    )
    val face = WodClock.face(spec, elapsedClock)
    val format = WodFormat.fromWire(wod.format)
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
    val timeLabel = "%d:%02d".format(mm, ss)
    val roundLabel = roundNumber?.let { "Ronda $it" } ?: (face.label ?: wod.title)
    Row(
        modifier
            .fillMaxWidth()
            .background(Color.Black, RoundedCornerShape(14.dp))
            .clickable(onClick = onExpand)
            .padding(horizontal = 14.dp, vertical = 10.dp)
            .testTag("minimized_wod_clock_bar"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Column(Modifier.weight(1f)) {
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
            onClick = { onTimerAction(if (timer?.running == true) "pause" else "start") },
            enabled = !busy,
            modifier = Modifier.testTag("minimized_wod_continue")
        ) {
            Text(
                if (timer?.running == true) "Pausar" else "Continuar",
                color = Color.White
            )
        }
        TextButton(
            onClick = onExpand,
            enabled = !busy
        ) {
            Text("Abrir", color = brandGreen, fontWeight = FontWeight.Bold)
        }
    }
}
