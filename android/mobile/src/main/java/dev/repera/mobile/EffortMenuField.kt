package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import dev.repera.domain.Effort

/**
 * Menú RIR/RPE compacto (PlayEditableSetsView iOS): celda «—» / valor,
 * sin OutlinedTextField ancho que parta «Sin RIR» en vertical.
 * [storedRir] siempre en RIR; la etiqueta sigue [effortUnit].
 */
@Composable
internal fun EffortMenuField(
    storedRir: Double?,
    effortUnit: String,
    enabled: Boolean = true,
    compact: Boolean = false,
    onChange: (Double?) -> Unit
) {
    var open by remember { mutableStateOf(false) }
    val isRpe = effortUnit == "rpe"
    val labelPrefix = if (isRpe) "RPE" else "RIR"
    val options: List<Double?> = buildList {
        add(null)
        if (isRpe) (0..10).forEach { add(it.toDouble()) }
        else (0..5).forEach { add(it.toDouble()) }
    }
    fun menuLabel(value: Double?): String = when {
        value == null -> "Sin $labelPrefix"
        else -> "$labelPrefix ${value.toInt()}"
    }
    // Celda compacta como iOS «RIR —»; el menú sí muestra «Sin RIR».
    val display = when {
        storedRir == null -> "—"
        isRpe -> "${(Effort.fromRIR(storedRir, "rpe") ?: storedRir).toInt()}"
        else -> "${storedRir.toInt()}"
    }
    Box(modifier = Modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = if (compact) 36.dp else 40.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f))
                .clickable(enabled = enabled) { open = true }
                .padding(horizontal = 8.dp, vertical = 8.dp)
                .testTag("effort_menu_field"),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = display,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Clip,
                softWrap = false
            )
        }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            options.forEach { opt ->
                DropdownMenuItem(
                    text = { Text(menuLabel(opt)) },
                    onClick = {
                        open = false
                        onChange(
                            if (opt == null) null
                            else if (isRpe) Effort.toRIR(opt, "rpe")
                            else opt
                        )
                    },
                    modifier = Modifier.testTag(
                        if (opt == null) "effort_none" else "effort_${opt.toInt()}"
                    )
                )
            }
        }
    }
}
