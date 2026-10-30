package dev.repera.mobile

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter

private val dayDisplayFmt = DateTimeFormatter.ofPattern("dd/MM/yyyy")
private val metaBoxShape = RoundedCornerShape(11.dp)

/**
 * Fecha | Hora | Duración en un único cuadro (paridad iOS surface2).
 * Mientras el teclado está abierto el campo muestra el borrador en vivo.
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

    var showDurationPad by remember { mutableStateOf(false) }
    var durationDraft by remember { mutableStateOf(durationMinutes.toString()) }

    val durationShown = if (showDurationPad) {
        val d = durationDraft.filter(Char::isDigit)
        if (d.isEmpty()) "" else "$d min"
    } else "$durationMinutes min"

    val boxBg = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f)
    val divider = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .clip(metaBoxShape)
            .background(boxBg)
            .testTag("workout_meta_datetime"),
        verticalAlignment = Alignment.CenterVertically
    ) {
        MetaUnifiedCell(
            caption = "Fecha",
            value = dayLabel,
            testTag = dayTestTag,
            modifier = Modifier.weight(1.15f),
            onClick = {
                DatePickerDialog(
                    ctx,
                    { _, y, m, d ->
                        onDayIso(LocalDate.of(y, m + 1, d).toString())
                    },
                    day.year,
                    day.monthValue - 1,
                    day.dayOfMonth
                ).show()
            }
        )
        Box(
            Modifier
                .width(1.dp)
                .height(36.dp)
                .background(divider)
        )
        MetaUnifiedCell(
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
        Box(
            Modifier
                .width(1.dp)
                .height(36.dp)
                .background(divider)
        )
        MetaUnifiedCell(
            caption = "Duración",
            value = durationShown,
            testTag = durationTestTag,
            modifier = Modifier.weight(1f),
            onClick = {
                durationDraft = durationMinutes.toString()
                showDurationPad = true
            }
        )
    }

    if (showDurationPad) {
        ReperaNumericKeypadSheet(
            title = "Duración (min)",
            draft = durationDraft,
            onDraftChange = { durationDraft = it.filter(Char::isDigit).take(3) },
            onDismiss = {
                durationDraft.filter(Char::isDigit).toIntOrNull()?.coerceIn(1, 600)
                    ?.let(onDurationMinutes)
                showDurationPad = false
            },
            onCommit = { raw ->
                val mins = raw.filter(Char::isDigit).toIntOrNull()?.coerceIn(1, 600)
                if (mins != null) onDurationMinutes(mins)
                showDurationPad = false
            },
            allowsDecimal = false,
            showDraftPreview = true
        )
    }
}

/** Título editable con look meta (caption + fondo surface2). */
@Composable
internal fun WorkoutMetaTitleField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "Entreno",
    enabled: Boolean = true,
    testTag: String = "workout_meta_title"
) {
    ReperaMetaTextField(
        caption = "Nombre",
        value = value,
        onValueChange = onValueChange,
        modifier = modifier,
        placeholder = placeholder,
        enabled = enabled,
        testTag = testTag
    )
}

/** Notas del entreno con look meta (caption + fondo surface2). */
@Composable
internal fun WorkoutMetaNotesField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    testTag: String = "workout_meta_notes"
) {
    ReperaMetaTextField(
        caption = "Notas",
        value = value,
        onValueChange = onValueChange,
        modifier = modifier,
        placeholder = "Notas del entreno",
        singleLine = false,
        enabled = enabled,
        testTag = testTag
    )
}

/** `ddMMyyyy` → `dd/MM/yyyy` parcial mientras se teclea. */
internal fun formatDdMmYyyyDraft(digits: String): String {
    val d = digits.filter(Char::isDigit).take(8)
    return buildString {
        d.forEachIndexed { i, c ->
            if (i == 2 || i == 4) append('/')
            append(c)
        }
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
private fun MetaUnifiedCell(
    caption: String,
    value: String,
    testTag: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Column(
        modifier = modifier
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 8.dp)
            .testTag(testTag),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Text(
            caption,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            value,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 1
        )
    }
}
