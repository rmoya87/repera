package dev.repera.mobile

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import java.time.LocalTime
import java.util.Locale

/**
 * Fecha | Hora | Duración en una fila (campos separados), paridad PlanView iOS
 * `oneOffDateTimeDurationRow` / `completedDateTimeDurationRow`.
 */
@Composable
internal fun WorkoutDateTimeDurationRow(
    dayIso: String?,
    clock: String,
    durationMinutes: Int,
    onDayIso: (String) -> Unit,
    onClock: (String) -> Unit,
    onDurationMinutes: (Int) -> Unit,
    modifier: Modifier = Modifier,
    dayTestTag: String = "workout_meta_date",
    timeTestTag: String = "workout_meta_time",
    durationTestTag: String = "workout_meta_duration"
) {
    val ctx = LocalContext.current
    val day = dayIso?.let { runCatching { LocalDate.parse(it) }.getOrNull() } ?: LocalDate.now()
    val time = runCatching { LocalTime.parse(clock) }.getOrElse { LocalTime.of(18, 0) }
    val dayLabel = day.format(reperaPlanDayFormatter).replaceFirstChar {
        if (it.isLowerCase()) it.titlecase(Locale("es", "ES")) else it.toString()
    }
    val timeLabel = "%02d:%02d".format(time.hour, time.minute)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .testTag("workout_meta_datetime"),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.Top
    ) {
        MetaFieldColumn(
            caption = "Fecha",
            value = dayLabel,
            testTag = dayTestTag,
            modifier = Modifier.weight(1f),
            onClick = {
                DatePickerDialog(
                    ctx,
                    { _, y, m, d -> onDayIso(LocalDate.of(y, m + 1, d).toString()) },
                    day.year,
                    day.monthValue - 1,
                    day.dayOfMonth
                ).show()
            }
        )
        MetaFieldColumn(
            caption = "Hora",
            value = timeLabel,
            testTag = timeTestTag,
            modifier = Modifier.weight(1f),
            onClick = {
                TimePickerDialog(
                    ctx,
                    { _, h, mi -> onClock("%02d:%02d".format(h, mi)) },
                    time.hour,
                    time.minute,
                    true
                ).show()
            }
        )
        MetaFieldColumn(
            caption = "Duración",
            value = "$durationMinutes min",
            testTag = durationTestTag,
            modifier = Modifier.weight(1f),
            onClick = {
                val next = when {
                    durationMinutes < 30 -> 30
                    durationMinutes < 45 -> 45
                    durationMinutes < 60 -> 60
                    durationMinutes < 90 -> 90
                    else -> (durationMinutes + 15).coerceAtMost(600)
                }
                onDurationMinutes(next)
            }
        )
    }
}

@Composable
private fun MetaFieldColumn(
    caption: String,
    value: String,
    testTag: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Text(
            caption,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        TextButton(
            onClick = onClick,
            modifier = Modifier
                .fillMaxWidth()
                .testTag(testTag)
                .padding(0.dp),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                horizontal = 4.dp,
                vertical = 4.dp
            )
        ) {
            Text(
                value,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
