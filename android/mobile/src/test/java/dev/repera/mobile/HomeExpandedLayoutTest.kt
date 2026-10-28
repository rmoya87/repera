package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class HomeExpandedLayoutTest {
    @Test fun appleHomeWidthCutoffIs620IncludingPagePadding() {
        assertFalse(homeUsesExpandedLayout(619.99f))
        assertTrue(homeUsesExpandedLayout(620f));assertTrue(homeUsesExpandedLayout(840f))
    }
}
