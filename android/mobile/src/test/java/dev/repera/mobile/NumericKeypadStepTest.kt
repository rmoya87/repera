package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Test

class NumericKeypadStepTest {
    @Test
    fun kgStepUsesTwoPointFive() {
        val next = applyNumericKeypadAction("60", NumericKeypadAction.Plus, allowsDecimal = true, step = 2.5)
        assertEquals("62,5", next)
    }

    @Test
    fun repsStepUsesOne() {
        val next = applyNumericKeypadAction("8", NumericKeypadAction.Plus, allowsDecimal = false, step = 1.0)
        assertEquals("9", next)
    }
}
