package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Backspace
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.KeyboardHide
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import dev.repera.domain.ReperaNumberFormat

private val keypadBg = Color(0xFFECEDF2)
private val keyUtility = Color(0xFFDBDEE3)
private val keyErase = Color(0xFFEBEDF2)
private val keyInk = Color(0xFF080F1F)

/**
 * Teclado 4×4 Repera (port de OGReperaNumericKeypad iOS, altura ~328):
 * 1 2 3 ocultar / 4 5 6 + / 7 8 9 − / , 0 borrar ✓
 * Filas fillEqually (sin aspectRatio) para que las teclas no se deformen.
 */
@Composable
fun ReperaNumericKeypad(
    onDigit: (Char) -> Unit,
    onPoint: () -> Unit,
    onPlus: () -> Unit,
    onMinus: () -> Unit,
    onErase: () -> Unit,
    onDismiss: () -> Unit,
    onSubmit: () -> Unit,
    modifier: Modifier = Modifier,
    allowsDecimal: Boolean = true,
) {
    Column(
        modifier
            .fillMaxWidth()
            .background(keypadBg)
            .navigationBarsPadding()
            .padding(start = 8.dp, end = 8.dp, top = 8.dp, bottom = 10.dp)
            .height(302.dp)
            .testTag("repera_numeric_keypad"),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        KeypadRow {
            DigitKey("1") { onDigit('1') }
            DigitKey("2") { onDigit('2') }
            DigitKey("3") { onDigit('3') }
            UtilityKey(Icons.Outlined.KeyboardHide, "Ocultar teclado", onDismiss)
        }
        KeypadRow {
            DigitKey("4") { onDigit('4') }
            DigitKey("5") { onDigit('5') }
            DigitKey("6") { onDigit('6') }
            UtilityKey(Icons.Outlined.Add, "Sumar", onPlus)
        }
        KeypadRow {
            DigitKey("7") { onDigit('7') }
            DigitKey("8") { onDigit('8') }
            DigitKey("9") { onDigit('9') }
            UtilityKey(Icons.Outlined.Remove, "Restar", onMinus)
        }
        KeypadRow {
            DigitKey(",", enabled = allowsDecimal, onClick = onPoint)
            DigitKey("0") { onDigit('0') }
            EraseKey(onErase)
            SubmitKey(onSubmit)
        }
    }
}

/** Aplica una tecla al borrador visible (lógica iOS Coordinator.keypadKey). */
internal fun applyNumericKeypadAction(
    current: String,
    action: NumericKeypadAction,
    allowsDecimal: Boolean = true
): String {
    return when (action) {
        NumericKeypadAction.Erase -> current.dropLast(1)
        NumericKeypadAction.Plus -> {
            val v = ReperaNumberFormat.parse(current) ?: 0.0
            ReperaNumberFormat.decimal(maxOf(0.0, v + 1.0))
        }
        NumericKeypadAction.Minus -> {
            val v = ReperaNumberFormat.parse(current) ?: 0.0
            ReperaNumberFormat.decimal(maxOf(0.0, v - 1.0))
        }
        NumericKeypadAction.Point -> {
            if (!allowsDecimal) current
            else ReperaNumberFormat.keypadDecimal(current, current + ",")
        }
        is NumericKeypadAction.Digit ->
            ReperaNumberFormat.keypadDecimal(current, current + action.char)
    }
}

internal sealed class NumericKeypadAction {
    data class Digit(val char: Char) : NumericKeypadAction()
    data object Point : NumericKeypadAction()
    data object Plus : NumericKeypadAction()
    data object Minus : NumericKeypadAction()
    data object Erase : NumericKeypadAction()
}

/**
 * Teclado anclado abajo + valor editable (inputView iOS).
 * ✓ / ocultar → [onCommit]. Toque fuera / atrás → [onDismiss] sin guardar
 * si hay preview; en modo inline (sin preview) fuera también confirma.
 */
@Composable
fun ReperaNumericKeypadSheet(
    title: String,
    draft: String,
    onDraftChange: (String) -> Unit,
    onDismiss: () -> Unit,
    onCommit: (String) -> Unit,
    allowsDecimal: Boolean = true,
    showDraftPreview: Boolean = true,
) {
    Dialog(
        onDismissRequest = {
            if (showDraftPreview) onDismiss() else onCommit(draft)
        },
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = true
        )
    ) {
        Box(Modifier.fillMaxSize()) {
            Box(
                Modifier
                    .fillMaxSize()
                    .clickable(
                        indication = null,
                        interactionSource = remember { MutableInteractionSource() },
                        onClick = {
                            if (showDraftPreview) onDismiss() else onCommit(draft)
                        }
                    )
            )
            Column(
                Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
            ) {
                Surface(
                    Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.surface,
                    shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)
                ) {
                    Column(Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
                        Text(
                            title,
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            draft.ifEmpty { "—" },
                            fontSize = 32.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = brandGreenReadable,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp)
                                .testTag("numeric_keypad_draft"),
                            textAlign = TextAlign.Center
                        )
                    }
                }
                ReperaNumericKeypad(
                    allowsDecimal = allowsDecimal,
                    onDigit = { ch ->
                        onDraftChange(applyNumericKeypadAction(draft, NumericKeypadAction.Digit(ch)))
                    },
                    onPoint = {
                        onDraftChange(applyNumericKeypadAction(draft, NumericKeypadAction.Point))
                    },
                    onPlus = {
                        onDraftChange(applyNumericKeypadAction(draft, NumericKeypadAction.Plus))
                    },
                    onMinus = {
                        onDraftChange(applyNumericKeypadAction(draft, NumericKeypadAction.Minus))
                    },
                    onErase = {
                        onDraftChange(applyNumericKeypadAction(draft, NumericKeypadAction.Erase))
                    },
                    onDismiss = { onCommit(draft) },
                    onSubmit = { onCommit(draft) }
                )
            }
        }
    }
}

@Composable
private fun ColumnScope.KeypadRow(content: @Composable RowScope.() -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .weight(1f),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content
    )
}

@Composable
private fun RowScope.DigitKey(
    label: String,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    KeySurface(
        background = Color.White,
        enabled = enabled,
        onClick = onClick,
        contentDescription = label
    ) {
        Text(
            label,
            fontSize = 28.sp,
            color = keyInk.copy(alpha = if (enabled) 1f else 0.42f),
            fontWeight = FontWeight.Normal
        )
    }
}

@Composable
private fun RowScope.UtilityKey(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit
) {
    KeySurface(background = keyUtility, onClick = onClick, contentDescription = label) {
        Icon(icon, contentDescription = null, tint = keyInk, modifier = Modifier.size(28.dp))
    }
}

@Composable
private fun RowScope.EraseKey(onClick: () -> Unit) {
    KeySurface(background = keyErase, onClick = onClick, contentDescription = "Borrar") {
        Icon(
            Icons.AutoMirrored.Outlined.Backspace,
            contentDescription = null,
            tint = keyInk,
            modifier = Modifier.size(28.dp)
        )
    }
}

@Composable
private fun RowScope.SubmitKey(onClick: () -> Unit) {
    KeySurface(background = brandGreen, onClick = onClick, contentDescription = "Confirmar") {
        Icon(Icons.Outlined.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(32.dp))
    }
}

@Composable
private fun RowScope.KeySurface(
    background: Color,
    onClick: () -> Unit,
    contentDescription: String,
    enabled: Boolean = true,
    content: @Composable () -> Unit
) {
    Box(
        Modifier
            .weight(1f)
            .fillMaxHeight()
            .clip(RoundedCornerShape(12.dp))
            .background(background)
            .semantics { this.contentDescription = contentDescription }
            .clickable(
                enabled = enabled,
                indication = ripple(),
                interactionSource = remember { MutableInteractionSource() },
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}
