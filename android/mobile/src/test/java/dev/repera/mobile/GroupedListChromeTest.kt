package dev.repera.mobile

import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Test

/** Apple OGListChromeModifier: 16pt siempre; +16pt exterior solo en paisaje. */
class GroupedListChromeTest {
    @Test fun portraitKeepsSixteen() {
        assertEquals(16.dp, groupedListHorizontalMargin(false))
    }
    @Test fun landscapeAddsOuterSixteen() {
        assertEquals(32.dp, groupedListHorizontalMargin(true))
    }
}
