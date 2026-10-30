package dev.repera.mobile

import android.app.TimePickerDialog
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter

private val dayDisplayFmt = DateTimeFormatter.ofPattern("dd/MM/yyyy")

/**
 * Fecha | Hora | Duración en una fila. Fecha en `dd/MM/yyyy` con teclado
 * numérico Repera; hora con picker; duración con teclado numérico.
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
    val dayLabel = day.format(dayDisplayFmt)
    val timeLabel = "%02d:%02d".format(time.hour, time.minute)

    var showDatePad by remember { mutableStateOf(false) }
    var dateDraft by remember { mutableStateOf(dayLabel.replace("/", "")) }
    var showDurationPad by remember { mutableStateOf(false) }
    var durationDraft by remember { mutableStateOf(durationMinutes.toString()) }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .testTag("workout_meta_datetime"),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.Top
    ) {
        MetaNumericColumn(
            caption = "Fecha",
            value = dayLabel,
            testTag = dayTestTag,
            modifier = Modifier.weight(1.15f),
            onClick = {
                dateDraft = dayLabel.replace("/", "")
                showDatePad = true
            }
        )
        MetaNumericColumn(
            caption = "Hora",
            value = timeLabel,
            testTag = timeTestTag,
            modifier = Modifier.weight(0.85f),
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
        MetaNumericColumn(
            caption = "Duración",
            value = "$durationMinutes min",
            testTag = durationTestTag,
            modifier = Modifier.weight(1f),
            onClick = {
                durationDraft = durationMinutes.toString()
                showDurationPad = true
            }
        )
    }

    if (showDatePad) {
        ReperaNumericKeypadSheet(
            title = "Fecha",
            draft = dateDraft,
            onDraftChange = { raw ->
                dateDraft = raw.filter(Char::isDigit).take(8)
            },
            onDismiss = { showDatePad = false },
            onCommit = { raw ->
                val digits = raw.filter(Char::isDigit)
                val parsed = parseDdMmYyyy(digits)
                if (parsed != null) onDayIso(parsed.toString())
                showDatePad = false
            },
            allowsDecimal = false,
            showDraftPreview = false
        )
    }
    if (showDurationPad) {
        ReperaNumericKeypadSheet(
            title = "Duración",
            draft = durationDraft,
            onDraftChange = { durationDraft = it.filter(Char::isDigit).take(3) },
            onDismiss = { showDurationPad = false },
            onCommit = { raw ->
                raw.filter(Char::isDigit).toIntOrNull()?.coerceIn(1, 600)?.let(onDurationMinutes)
                showDurationPad = false
            },
            allowsDecimal = false,
            showDraftPreview = false
        )
    }
}

/** Interpreta `ddMMyyyy` / `ddMMyy` → LocalDate. */
internal fun parseDdMmYyyy(digits: String): LocalDate? {
    if (digits.length !in setOf(6, 8)) return null
    val dd = digits.substring(0, 2).toIntOrNull() ?: return null
    val mm = digits.substring(2, 4).toIntOrNull() ?: return null
    val yyyy = when (digits.length) {
        8 -> digits.substring(4, 8).toIntOrNull() ?: return null
        else -> {
            val yy = digits.substring(4, 6).toIntOrNull() ?: return null
            if (yy >= 70) 1900 + yy else 2000 + yy
        }
    }
    return runCatching { LocalDate.of(yyyy, mm, dd) }.getOrNull()
}

@Composable
private fun MetaNumericColumn(
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
        Box {
            OutlinedTextField(
                value = value,
                onValueChange = {},
                readOnly = true,
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag(testTag)
            )
            Box(Modifier.matchParentSize().clickable(onClick = onClick))
        }
    }
}
