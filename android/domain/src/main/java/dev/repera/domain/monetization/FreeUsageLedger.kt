package dev.repera.domain.monetization

import java.util.Calendar
import java.util.TimeZone

/**
 * Contadores de uso gratuito (separados del JSON deportivo).
 * Port 1:1 de FreeUsageLedger.swift.
 */
data class FreeUsageState(
    /** Periodo mensual en calendario gregoriano UTC: `yyyy-MM`. */
    val boardScanPeriodKey: String = "",
    val boardScansConsumed: Int = 0,
    /** Intentos ya contabilizados (anti doble callback). */
    val consumedAttemptIDs: List<String> = emptyList(),
    val lastBoardScanConsumedAt: Long? = null
)

/** Lógica pura de cuotas mensuales (testeable sin UI). */
object FreeUsageLedger {
    const val MAX_TRACKED_ATTEMPT_IDS = 64

    private fun utcCalendar(): Calendar =
        Calendar.getInstance(TimeZone.getTimeZone("UTC"))

    /** Clave de mes natural en UTC (consistente entre husos). */
    fun periodKey(now: Long = System.currentTimeMillis(), calendar: Calendar = utcCalendar()): String {
        calendar.timeInMillis = now
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        return "%04d-%02d".format(year, month)
    }

    /** Asegura que el estado refleja el mes actual; resetea contadores al cambiar de periodo. */
    fun normalized(
        state: FreeUsageState,
        now: Long = System.currentTimeMillis(),
        calendar: Calendar = utcCalendar()
    ): FreeUsageState {
        val key = periodKey(now, calendar)
        return if (state.boardScanPeriodKey == key) state else FreeUsageState(boardScanPeriodKey = key)
    }

    fun boardScansRemaining(
        state: FreeUsageState,
        limit: Int = FreePlanLimits.MAX_BOARD_SCANS_PER_MONTH,
        now: Long = System.currentTimeMillis(),
        calendar: Calendar = utcCalendar()
    ): Int {
        val current = normalized(state, now, calendar)
        return maxOf(0, limit - current.boardScansConsumed)
    }

    fun canStartBoardScan(
        state: FreeUsageState,
        isPro: Boolean,
        limit: Int = FreePlanLimits.MAX_BOARD_SCANS_PER_MONTH,
        now: Long = System.currentTimeMillis(),
        calendar: Calendar = utcCalendar()
    ): Boolean {
        if (isPro) return true
        return boardScansRemaining(state, limit, now, calendar) > 0
    }

    /** Consume un escaneo exitoso. Idempotente por `attemptID`. Devuelve el nuevo estado y si consumió. */
    fun consumeBoardScan(
        state: FreeUsageState,
        attemptID: String,
        isPro: Boolean,
        limit: Int = FreePlanLimits.MAX_BOARD_SCANS_PER_MONTH,
        now: Long = System.currentTimeMillis(),
        calendar: Calendar = utcCalendar()
    ): Pair<FreeUsageState, Boolean> {
        if (isPro) return state to false
        val current = normalized(state, now, calendar)
        if (attemptID in current.consumedAttemptIDs) return current to false
        if (current.boardScansConsumed >= limit) return current to false
        val ids = (current.consumedAttemptIDs + attemptID)
            .let { if (it.size > MAX_TRACKED_ATTEMPT_IDS) it.drop(it.size - MAX_TRACKED_ATTEMPT_IDS) else it }
        return current.copy(
            boardScansConsumed = current.boardScansConsumed + 1,
            consumedAttemptIDs = ids,
            lastBoardScanConsumedAt = now
        ) to true
    }
}
