package dev.repera.mobile

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import org.junit.Test
import org.junit.Rule
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Apple 2ac224f5: «Ver historial completo» solo bajo el tema Entreno. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class ProgressHistoryEntryTest {

    @get:Rule val composeRule = createComposeRule()

    private fun show() {
        composeRule.setContent {
            MaterialTheme {
                ProgressTab(busy = false, syncing = false, status = null,
                    overview = null, onInitializeLocal = {}, onImportJson = {},
                    onDriveSync = {}, onExportJson = {}, onSignOut = {},
                    onReviseFinishedSet = { _, _, _, _, _, _ -> },
                    onDeleteFinishedSet = { _, _, _ -> })
            }
        }
    }

    @Test fun historyEntryVisibleUnderTrainingTopic() {
        show()
        // La lista es perezosa: hay que hacer scroll hasta el boton.
        composeRule.onNodeWithTag("progress_list")
            .performScrollToNode(hasText("Ver historial completo"))
        composeRule.onNodeWithText("Ver historial completo", useUnmergedTree = true)
            .assertExists()
    }

    @Test fun historyEntryHiddenUnderActivityAndRecovery() {
        show()
        composeRule.onNodeWithTag("progress_topic_1", useUnmergedTree = true).performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithText("Ver historial completo", useUnmergedTree = true)
            .assertDoesNotExist()
        composeRule.onNodeWithTag("progress_topic_2", useUnmergedTree = true).performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithText("Ver historial completo", useUnmergedTree = true)
            .assertDoesNotExist()
    }
}
