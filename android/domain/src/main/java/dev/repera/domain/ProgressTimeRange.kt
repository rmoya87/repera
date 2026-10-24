package dev.repera.domain

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.ZoneId

/**
 * Filtro global de Progreso (cabecera). Por defecto: esta semana.
 * Port 1:1 de ProgressTimeRange.swift (iOS).
 */
enum class ProgressTimeRange(val wire: String) {
    TODAY("today"),
    WEEK("week"),
    MONTH("month"),
    DAYS_90("days90"),
    DAYS_180("days180"),
    DAYS_360("days360");

    val title: String
        get() = when (this) {
            TODAY -> "Hoy"
            WEEK -> "Esta semana"
            MONTH -> "Este mes"
            DAYS_90 -> "90 días"
            DAYS_180 -> "180 días"
            DAYS_360 -> "360 días"
        }

    val subtitleLabel: String get() = title.lowercase()

    /** Días a pintar en gráficas / heatmap. */
    val chartDayCount: Int
        get() = when (this) {
            TODAY -> 1
            WEEK -> 7
            MONTH -> 31
            DAYS_90 -> 90
            DAYS_180 -> 180
            DAYS_360 -> 360
        }

    /** Días a pedir a Salud (margen sobre el periodo visible). */
    val healthFetchDayCount: Int
        get() = when (this) {
            TODAY -> 7
            WEEK -> 14
            MONTH -> 45
            DAYS_90 -> 100
            DAYS_180 -> 190
            DAYS_360 -> 370
        }

    /** Inicio inclusivo del rango (siempre acotado). */
    fun startDate(now: LocalDate = LocalDate.now(), weekStartsOnMonday: Boolean = true): LocalDate =
        when (this) {
            TODAY -> now
            WEEK -> {
                val first = if (weekStartsOnMonday) DayOfWeek.MONDAY else DayOfWeek.SUNDAY
                now.minusDays(((now.dayOfWeek.value - first.value) + 7L) % 7L)
            }
            MONTH -> now.withDayOfMonth(1)
            DAYS_90 -> now.minusDays(89)
            DAYS_180 -> now.minusDays(179)
            DAYS_360 -> now.minusDays(359)
        }

    fun contains(date: LocalDate, now: LocalDate = LocalDate.now(),
                 weekStartsOnMonday: Boolean = true): Boolean {
        if (!date.isBefore(now.plusDays(1))) return false
        return !date.isBefore(startDate(now, weekStartsOnMonday))
    }

    /** Ventana del periodo anterior (misma duración, desplazada hacia atrás). */
    fun previousPeriodBounds(now: LocalDate = LocalDate.now(),
                             weekStartsOnMonday: Boolean = true): Pair<LocalDate, LocalDate> {
        val start = startDate(now, weekStartsOnMonday)
        return when (this) {
            TODAY -> now.minusDays(1) to now
            WEEK -> start.minusDays(7) to start
            MONTH -> start.minusMonths(1) to start
            DAYS_90 -> start.minusDays(90) to start
            DAYS_180 -> start.minusDays(180) to start
            DAYS_360 -> start.minusDays(360) to start
        }
    }

    fun containsInPreviousPeriod(date: LocalDate, now: LocalDate = LocalDate.now(),
                                 weekStartsOnMonday: Boolean = true): Boolean {
        val (start, end) = previousPeriodBounds(now, weekStartsOnMonday)
        return !date.isBefore(start) && date.isBefore(end)
    }

    companion object {
        fun fromWire(wire: String): ProgressTimeRange? = entries.firstOrNull { it.wire == wire }

        /** Zona horaria por defecto del dispositivo (para llamadas con fechas). */
        val defaultZone: ZoneId get() = ZoneId.systemDefault()
    }
}
