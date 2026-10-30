package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag

/**
 * Campo numérico con teclado Repera ([ReperaNumericKeypadSheet]),
 * el mismo de ficha de ejercicio / Tope 1RM. Sin teclado del sistema.
 */
@Composable
fun ReperaNumericField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    allowsDecimal: Boolean = true,
    enabled: Boolean = true,
    testTag: String? = null,
) {
    var showPad by remember { mutableStateOf(false) }
    var draft by remember { mutableStateOf(value) }
    Box(modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = {},
            readOnly = true,
            enabled = enabled,
            singleLine = true,
            label = { Text(label) },
            modifier = Modifier
                .fillMaxWidth()
                .then(if (testTag != null) Modifier.testTag(testTag) else Modifier)
        )
        Box(
            Modifier
                .matchParentSize()
                .clickable(enabled = enabled) {
                    draft = value
                    showPad = true
                }
        )
    }
    if (showPad) {
        ReperaNumericKeypadSheet(
            title = label,
            draft = draft,
            onDraftChange = { draft = it },
            onDismiss = { showPad = false },
            onCommit = {
                onValueChange(it)
                showPad = false
            },
            allowsDecimal = allowsDecimal,
            showDraftPreview = true
        )
    }
}
