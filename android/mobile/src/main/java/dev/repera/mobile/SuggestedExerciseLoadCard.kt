package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.ReperaNumberFormat

/**
 * Carga sugerida (paridad iOS SuggestedLoadCard): % verde + fuente, kg a la derecha,
 * slider 50–95 % en pasos de 5, pie con base 1RM/e1RM.
 */
@Composable
internal fun SuggestedExerciseLoadCard(
    tested: Double?,
    estimated: Double?,
    increment: Double
) {
    var percent by rememberSaveable { mutableFloatStateOf(70f) }
    val oneRM = tested?.takeIf { it > 0 } ?: estimated?.takeIf { it > 0 }
    val source = if (tested != null && tested > 0) "1RM" else "e1RM"
    ReperaCard(Modifier.fillMaxWidth()) {
        Column(
            Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            if (oneRM != null) {
                val kg = dev.repera.domain.LoadSuggestion.weightKg(
                    oneRM,
                    percent.toDouble(),
                    increment.coerceAtLeast(0.5)
                )
                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text(
                            "${percent.toInt()}%",
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold,
                            color = brandGreenReadable,
                            modifier = Modifier.testTag("suggested_load_percent_label")
                        )
                        Text(
                            " $source",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(bottom = 4.dp)
                        )
                    }
                    Text(
                        "${ReperaNumberFormat.decimal(kg)} kg",
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.testTag("suggested_load_value")
                    )
                }
                Slider(
                    value = percent,
                    onValueChange = { raw ->
                        // Pasos de 5 % (50…95).
                        percent = ((raw / 5f).toInt() * 5f).coerceIn(50f, 95f)
                    },
                    valueRange = 50f..95f,
                    steps = 8,
                    colors = SliderDefaults.colors(
                        thumbColor = Color.Black,
                        activeTrackColor = brandGreen,
                        inactiveTrackColor = MaterialTheme.colorScheme.surfaceVariant,
                        activeTickColor = Color.Transparent,
                        inactiveTickColor = Color.Transparent
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("suggested_load_percent")
                )
                Text(
                    "Pasos de 5% · sobre $source ${ReperaNumberFormat.decimal(oneRM)} kg",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                Text(
                    "Fija el Tope 1RM en Evolución (o entrena con peso) para calcular kg.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
internal fun TestedOneRMEditor(tested: Double?, busy: Boolean, onSave: (Double?) -> Unit) {
    var editing by remember { mutableStateOf(false) }
    TextButton(
        enabled = !busy,
        onClick = { editing = true },
        modifier = Modifier.testTag("tested_onerm_edit")
    ) {
        Text(
            "Tope 1RM · ${tested?.let { ReperaNumberFormat.decimal(it) + " kg" } ?: "—"}"
        )
    }
    if (editing) {
        TestedOneRMEditorDialog(
            tested = tested,
            busy = busy,
            onDismiss = { editing = false },
            onSave = {
                onSave(it)
                editing = false
            }
        )
    }
}

/** Editor Tope 1RM con teclado Repera (misma lógica que commitTopeEdit iOS). */
@Composable
internal fun TestedOneRMEditorDialog(
    tested: Double?,
    busy: Boolean,
    onDismiss: () -> Unit,
    onSave: (Double?) -> Unit
) {
    var draft by remember(tested) {
        mutableStateOf(tested?.let { ReperaNumberFormat.decimal(it) }.orEmpty())
    }
    fun commit(raw: String) {
        if (busy) {
            onDismiss()
            return
        }
        val trimmed = raw.trim()
        when {
            trimmed.isEmpty() || trimmed == "—" -> onSave(null)
            else -> {
                val v = ReperaNumberFormat.parse(trimmed)
                if (v != null && v > 0) {
                    onSave(kotlin.math.round(v * 10.0) / 10.0)
                } else {
                    onDismiss()
                }
            }
        }
    }
    ReperaNumericKeypadSheet(
        title = "Tope 1RM",
        draft = draft,
        onDraftChange = { draft = it },
        onDismiss = onDismiss,
        onCommit = ::commit,
        showDraftPreview = true
    )
}
