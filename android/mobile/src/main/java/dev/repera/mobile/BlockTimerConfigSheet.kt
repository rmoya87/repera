package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.repera.domain.WodClockSpec
import dev.repera.domain.WodFormat

/** Configuración manual al iniciar el reloj de un bloque libre (sin WOD). */
internal data class ManualBlockTimerConfig(
    val workSeconds: Int,
    val restSeconds: Int,
    val rounds: Int
)

/**
 * Prescripción del reloj al abrir desde Play (cualquier formato).
 * No depende de `active.wod` tras un flush async: Tabata/EMOM/… abren ya.
 */
internal data class BlockClockLaunchConfig(
    val formatWire: String,
    val workSeconds: Int = 20,
    val restSeconds: Int = 10,
    val rounds: Int = 8,
    val intervalSeconds: Int = 60,
    val timeCapMinutes: Int = 12,
    val timeCapSeconds: Int? = null,
    val restBetweenRoundsSeconds: Int = 0,
    val stations: Int = 1,
) {
    fun toSpec(): WodClockSpec {
        val format = WodFormat.fromWire(formatWire)
        return WodClockSpec(
            format = format,
            blockTimeCapMinutes = timeCapMinutes.takeIf { it > 0 },
            blockTimeCapSeconds = timeCapSeconds?.takeIf { it > 0 },
            intervalSeconds = intervalSeconds.takeIf { it > 0 },
            plannedIntervals = rounds.takeIf {
                format == WodFormat.EMOM || format == WodFormat.DEATH_BY
            },
            rounds = rounds.coerceAtLeast(1),
            workSeconds = workSeconds.coerceAtLeast(1),
            restSeconds = restSeconds.coerceAtLeast(0),
            restBetweenRoundsSeconds = restBetweenRoundsSeconds.coerceAtLeast(0),
            stations = stations.coerceAtLeast(1),
        )
    }

    companion object {
        fun fromManual(config: ManualBlockTimerConfig) = BlockClockLaunchConfig(
            formatWire = "tabata",
            workSeconds = config.workSeconds,
            restSeconds = config.restSeconds,
            rounds = config.rounds.coerceAtLeast(1),
        )

        fun fromBlockDraft(block: BlockDraftUi, stations: Int = 1): BlockClockLaunchConfig {
            val format = block.format.trim().ifBlank { "tabata" }
            val defaultRounds = when (format) {
                "tabata" -> 8
                "forTime", "emom", "roundsForQuality", "partner" -> 4
                else -> 1
            }
            val rounds = block.rounds.toIntOrNull()?.takeIf { it > 0 } ?: defaultRounds
            val work = block.work.toIntOrNull()?.takeIf { it > 0 } ?: 20
            val rest = block.rest.toIntOrNull()?.coerceAtLeast(0) ?: 10
            val interval = block.interval.toIntOrNull()?.takeIf { it > 0 } ?: 60
            val capMin = block.timeCap.toIntOrNull()?.takeIf { it > 0 } ?: 12
            val capSec = block.capSeconds.toIntOrNull()?.takeIf { it in 0..59 }
            val between = block.roundRest.toIntOrNull()?.coerceAtLeast(0) ?: 0
            val exactCap = if (format == "forTime" && capSec != null) {
                capMin * 60 + capSec
            } else null
            return BlockClockLaunchConfig(
                formatWire = format,
                workSeconds = work,
                restSeconds = rest,
                rounds = rounds,
                intervalSeconds = interval,
                timeCapMinutes = capMin,
                timeCapSeconds = exactCap,
                restBetweenRoundsSeconds = between,
                stations = stations.coerceAtLeast(1),
            )
        }
    }
}

/**
 * Configurar temporizador de bloque (paridad iOS WorkoutView.manualRoundDurationSheet):
 * sheet de abajo · trabajar por ronda + descansar entre rondas siempre visibles.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BlockTimerConfigSheet(
    rounds: Int,
    initialWorkSeconds: Int = 60,
    initialRestSeconds: Int = 0,
    exerciseName: String? = null,
    setsRepsSummary: String? = null,
    onDismiss: () -> Unit,
    onStart: (workSeconds: Int, restSeconds: Int) -> Unit
) {
    var workMin by remember { mutableStateOf((initialWorkSeconds / 60).coerceIn(0, 120).toString()) }
    var workSec by remember { mutableStateOf((initialWorkSeconds % 60).coerceIn(0, 59).toString()) }
    var restMin by remember {
        mutableStateOf((initialRestSeconds / 60).coerceIn(0, 10).toString())
    }
    var restSec by remember {
        mutableStateOf((initialRestSeconds % 60).coerceIn(0, 59).toString())
    }
    val workTotal = (workMin.toIntOrNull() ?: 0) * 60 + (workSec.toIntOrNull() ?: 0)
    val restTotal = (restMin.toIntOrNull() ?: 0) * 60 + (restSec.toIntOrNull() ?: 0)
    val canStart = workTotal > 0
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ReperaModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        modifier = Modifier.testTag("block_timer_config")
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    "Configurar temporizador",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                val subtitle = buildString {
                    exerciseName?.takeIf { it.isNotBlank() }?.let {
                        append(it)
                        if (!setsRepsSummary.isNullOrBlank()) append(" · ")
                    }
                    if (!setsRepsSummary.isNullOrBlank()) append(setsRepsSummary)
                    else append("Bloque libre · $rounds ronda${if (rounds == 1) "" else "s"}")
                }
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            TimerDurationRow(
                title = "Trabajar por ronda",
                minutes = workMin,
                seconds = workSec,
                onMinutes = { workMin = it.filter(Char::isDigit).take(3) },
                onSeconds = { workSec = it.filter(Char::isDigit).take(2) }
            )
            HorizontalDivider(
                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)
            )
            TimerDurationRow(
                title = "Descansar entre rondas",
                minutes = restMin,
                seconds = restSec,
                onMinutes = { restMin = it.filter(Char::isDigit).take(2) },
                onSeconds = { restSec = it.filter(Char::isDigit).take(2) }
            )
            Button(
                colors = reperaPrimaryButtonColors(),
                onClick = { onStart(workTotal, restTotal) },
                enabled = canStart,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
                    .testTag("block_timer_start")
            ) {
                Text("Iniciar temporizador", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun TimerDurationRow(
    title: String,
    minutes: String,
    seconds: String,
    onMinutes: (String) -> Unit,
    onSeconds: (String) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            title,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
        Row(
            Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            ReperaNumericField(
                value = minutes,
                onValueChange = onMinutes,
                label = "MIN",
                allowsDecimal = false,
                modifier = Modifier.weight(1f)
            )
            ReperaNumericField(
                value = seconds,
                onValueChange = {
                    val v = it.filter(Char::isDigit).take(2)
                    onSeconds(if ((v.toIntOrNull() ?: 0) > 59) "59" else v)
                },
                label = "SEG",
                allowsDecimal = false,
                modifier = Modifier.weight(1f)
            )
        }
    }
}
