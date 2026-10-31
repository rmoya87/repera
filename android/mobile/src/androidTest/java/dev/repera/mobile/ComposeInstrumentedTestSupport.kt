package dev.repera.mobile

import androidx.compose.ui.test.SemanticsNodeInteractionsProvider
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo

/** DayEditorTopBar confirm/back use icon buttons with test tags, not visible text labels. */
fun SemanticsNodeInteractionsProvider.clickEditorConfirm() {
    onNodeWithTag("editor_confirm").performScrollTo().performClick()
}

fun SemanticsNodeInteractionsProvider.clickEditorBack() {
    onNodeWithTag("editor_back").performScrollTo().performClick()
}

fun SemanticsNodeInteractionsProvider.clickPlanAddBlockRow() {
    onNodeWithTag("plan_add_block_row").performScrollTo().performClick()
}
