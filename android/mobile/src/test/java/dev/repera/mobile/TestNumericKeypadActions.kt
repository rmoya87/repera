package dev.repera.mobile

import androidx.compose.ui.test.assertExists
import androidx.compose.ui.test.junit4.ComposeContentTestRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick

/**
 * Drive the real Repera numeric keypad. NumericField displays Text, not a
 * system TextField: sending IME SetText to a caption is not a valid UI test.
 */
internal fun ComposeContentTestRule.replaceReperaNumericField(
    label: String, replacement: String
) {
    onNodeWithText(label, useUnmergedTree = true).performClick()
    onNodeWithTag("repera_numeric_keypad", useUnmergedTree = true).assertExists()
    // Clear the current draft, including any longer configured value.
    repeat(16) {
        onNodeWithContentDescription("Borrar", useUnmergedTree = true).performClick()
    }
    for (digit in replacement) {
        val key = when (digit) {
            '.', ',' -> ","
            in '0'..'9' -> digit.toString()
            else -> error("Unsupported numeric test input '$digit'")
        }
        onNodeWithContentDescription(key, useUnmergedTree = true).performClick()
    }
    onNodeWithContentDescription("Confirmar", useUnmergedTree = true).performClick()
}
