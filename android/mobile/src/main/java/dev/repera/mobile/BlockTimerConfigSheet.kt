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
import androidx.compose.material3.Switch
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

/** Configuración manual al iniciar el reloj de un bloque libre (sin WOD). */
internal data class ManualBlockTimerConfig(
    val workSeconds: Int,
    val restSeconds: Int,
    val rounds: Int
)

/**
 * Configurar temporizador de bloque (paridad iOS WorkoutView.manualRoundDurationSheet):
 * sheet de abajo · inputs meta · trabajar por ronda + descanso opcional.
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
    var restEnabled by remember { mutableStateOf(initialRestSeconds > 0) }
    var restMin by remember {
        mutableStateOf(
            ((if (initialRestSeconds > 0) initialRestSeconds else 60) / 60)
                .coerceIn(0, 10).toString()
        )
    }
    var restSec by remember {
        mutableStateOf(
            ((if (initialRestSeconds > 0) initialRestSeconds else 60) % 60)
                .coerceIn(0, 59).toString()
        )
    }
    val workTotal = (workMin.toIntOrNull() ?: 0) * 60 + (workSec.toIntOrNull() ?: 0)
    val restTotal = if (restEnabled) {
        (restMin.toIntOrNull() ?: 0) * 60 + (restSec.toIntOrNull() ?: 0)
    } else 0
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
            Row(
                Modifier
                    .fillMaxWidth()
                    .testTag("block_timer_rest_toggle"),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    "Descanso entre series",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.weight(1f)
                )
                Switch(
                    checked = restEnabled,
                    onCheckedChange = { restEnabled = it },
                    colors = reperaSwitchColors()
                )
            }
            if (restEnabled) {
                TimerDurationRow(
                    title = "Tiempo de descanso",
                    minutes = restMin,
                    seconds = restSec,
                    onMinutes = { restMin = it.filter(Char::isDigit).take(2) },
                    onSeconds = { restSec = it.filter(Char::isDigit).take(2) }
                )
            }
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
