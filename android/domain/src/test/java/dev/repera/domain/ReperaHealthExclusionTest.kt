package dev.repera.domain
import org.junit.Test
import org.junit.Assert.*
class ReperaHealthExclusionTest {
    @Test fun linkedIdWinsEvenOutsideWindow() {
        assertTrue(ReperaHealthExclusion.matches(0,1000,"linked",listOf(ReperaHealthExclusion.Window(100000,200000,"linked"))))
    }
    @Test fun oneStrictOverlapExcludesButAmbiguousAndNearbyDoNot() {
        val w=ReperaHealthExclusion.Window(0,600_000)
        assertTrue(ReperaHealthExclusion.matches(360_000,600_000,"x",listOf(w)))
        assertFalse(ReperaHealthExclusion.matches(360_001,600_000,"x",listOf(w)))
        assertFalse(ReperaHealthExclusion.matches(610_000,900_000,"x",listOf(w)))
        assertFalse(ReperaHealthExclusion.matches(0,600_000,"x",listOf(w,w)))
    }
}
