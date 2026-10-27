package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDate

class HomeRecoveryModelTest {
    private val today = LocalDate.of(2026, 10, 26)
    @Test fun noDataHidesCard() = assertNull(HomeRecoveryModel.of(null, null, emptyList(), today))
    @Test fun sleepOnly() {
        val m = HomeRecoveryModel.of(7.5, 84, emptyList(), today)!!
        assertEquals(7.5, m.sleepHours!!, 0.0); assertEquals(8, m.sleepIndexOutOf10); assertNull(m.cycleLabel)
    }
    @Test fun cycleOnlyShowsCardWithoutSleep() {
        val m = HomeRecoveryModel.of(null, 90, listOf(today.minusDays(1), today), today)!!
        assertNull(m.sleepHours); assertNull(m.sleepIndexOutOf10); assertEquals("Menstruación registrada", m.cycleLabel)
    }
    @Test fun futureOnlyDaysGiveUnknownLabel() =
        assertEquals("Fase no disponible", HomeRecoveryModel.of(null, null, listOf(today.plusDays(3)), today)!!.cycleLabel)
}
