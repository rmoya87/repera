package dev.repera.mobile

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import dev.repera.domain.Effort

/**
 * I-40 menú RIR/RPE: «Sin RIR» + 0…5 (o RPE 0…10), paridad sheet iOS.
 * [storedRir] siempre en RIR; la etiqueta sigue [effortUnit].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun EffortMenuField(
    storedRir: Double?,
    effortUnit: String,
    enabled: Boolean = true,
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
    fun label(value: Double?): String = when {
        value == null -> "Sin $labelPrefix"
        else -> "$labelPrefix ${value.toInt()}"
    }
    val display = when {
        storedRir == null -> "Sin $labelPrefix"
        isRpe -> label(Effort.fromRIR(storedRir, "rpe"))
        else -> "RIR ${storedRir.toInt()}"
    }
    ExposedDropdownMenuBox(expanded = open, onExpandedChange = { if (enabled) open = it }) {
        OutlinedTextField(
            value = display,
            onValueChange = {},
            readOnly = true,
            enabled = enabled,
            label = { Text(if (isRpe) "RPE" else "RIR") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = open) },
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
                .testTag("effort_menu_field")
        )
        ExposedDropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            options.forEach { opt ->
                DropdownMenuItem(
                    text = { Text(label(opt)) },
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
