package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

private val fieldShape = RoundedCornerShape(11.dp)

@Composable
private fun metaFieldBackground() =
    MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f)

/**
 * Campo con caption + valor sobre fondo surface2 (paridad meta Fecha/Hora).
 * Texto editable in-place; no cambia el teclado del sistema.
 */
@Composable
internal fun ReperaMetaTextField(
    caption: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier.fillMaxWidth(),
    placeholder: String = "",
    singleLine: Boolean = true,
    enabled: Boolean = true,
    testTag: String = "repera_meta_text",
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default
) {
    Column(
        modifier = modifier
            .clip(fieldShape)
            .background(metaFieldBackground())
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        if (caption.isNotBlank()) {
            Text(
                caption,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            enabled = enabled,
            singleLine = singleLine,
            minLines = if (singleLine) 1 else 2,
            maxLines = if (singleLine) 1 else 5,
            textStyle = MaterialTheme.typography.bodyLarge.copy(
                color = MaterialTheme.colorScheme.onSurface
            ),
            cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
            keyboardOptions = keyboardOptions,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = if (singleLine) 24.dp else 48.dp)
                .testTag(testTag),
            decorationBox = { inner ->
                Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterStart) {
                    if (value.isEmpty() && placeholder.isNotEmpty()) {
                        Text(
                            placeholder,
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    inner()
                }
            }
        )
    }
}

/**
 * Campo numérico con el mismo look; al tocar abre el teclado personalizado
 * (no el IME numérico del sistema).
 */
@Composable
internal fun ReperaMetaNumericField(
    caption: String,
    value: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier.fillMaxWidth(),
    enabled: Boolean = true,
    testTag: String = "repera_meta_numeric"
) {
    Column(
        modifier = modifier
            .clip(fieldShape)
            .background(metaFieldBackground())
            .clickable(
                enabled = enabled,
                indication = null,
                interactionSource = remember { MutableInteractionSource() },
                onClick = onClick
            )
            .padding(horizontal = 12.dp, vertical = 8.dp)
            .testTag(testTag),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        if (caption.isNotBlank()) {
            Text(
                caption,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Text(
            value.ifBlank { "—" },
            style = MaterialTheme.typography.bodyLarge,
            color = if (value.isBlank()) {
                MaterialTheme.colorScheme.onSurfaceVariant
            } else {
                MaterialTheme.colorScheme.onSurface
            },
            maxLines = 1
        )
    }
}
