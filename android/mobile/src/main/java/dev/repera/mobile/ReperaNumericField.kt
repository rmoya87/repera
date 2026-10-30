package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

private val fieldShape = RoundedCornerShape(11.dp)

/**
 * Campo numérico con teclado Repera ([ReperaNumericKeypadSheet]),
 * el mismo de ficha de ejercicio / Tope 1RM. Sin teclado del sistema.
 * Look: caption + valor sobre fondo surface2 (paridad meta Fecha/Hora).
 */
@Composable
fun ReperaNumericField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier.fillMaxWidth(),
    allowsDecimal: Boolean = true,
    enabled: Boolean = true,
    testTag: String? = null,
) {
    var showPad by remember { mutableStateOf(false) }
    var draft by remember { mutableStateOf(value) }
    // Mientras el pad está abierto el campo muestra el borrador en vivo.
    val shown = if (showPad) draft else value
    Column(
        modifier = modifier
            .clip(fieldShape)
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f))
            .clickable(
                enabled = enabled,
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            ) {
                draft = value
                showPad = true
            }
            .padding(horizontal = 12.dp, vertical = 8.dp)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            shown.ifBlank { "—" },
            style = MaterialTheme.typography.bodyLarge,
            color = if (shown.isBlank()) {
                MaterialTheme.colorScheme.onSurfaceVariant
            } else {
                MaterialTheme.colorScheme.onSurface
            },
            maxLines = 1
        )
    }
    if (showPad) {
        ReperaNumericKeypadSheet(
            title = label,
            draft = draft,
            onDraftChange = { draft = it },
            onDismiss = {
                onValueChange(draft)
                showPad = false
            },
            onCommit = {
                onValueChange(it)
                showPad = false
            },
            allowsDecimal = allowsDecimal,
            showDraftPreview = true
        )
    }
}
