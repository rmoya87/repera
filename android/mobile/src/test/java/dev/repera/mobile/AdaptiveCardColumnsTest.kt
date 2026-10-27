package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class AdaptiveCardColumnsTest {
    @Test fun paddedPagesUseViewportCutoffNotInnerCardWidth() {
        assertEquals(1,adaptiveCardColumns(587.9f,32f))
        assertEquals(2,adaptiveCardColumns(588f,32f))
        assertEquals(1,adaptiveCardColumns(619.9f))
        assertEquals(2,adaptiveCardColumns(620f))
        assertEquals(2,adaptiveCardColumns(808f,32f))
    }
}
