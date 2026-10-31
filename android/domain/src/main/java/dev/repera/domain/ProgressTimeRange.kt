package dev.repera.domain

import java.time.LocalDate
import java.time.ZoneId

/**
 * Filtro global de Progreso (cabecera). Por defecto: últimos 7 días.
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
            WEEK -> "Últimos 7 días"
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
            WEEK -> 16
            MONTH -> 70
            DAYS_90 -> 190
            DAYS_180 -> 370
            DAYS_360 -> 730
        }

    /** Inicio inclusivo del rango (siempre acotado). */
    fun startDate(now: LocalDate = LocalDate.now(), weekStartsOnMonday: Boolean = true): LocalDate =
        when (this) {
            TODAY -> now
            // Ventana móvil: hoy + 6 días anteriores (no semana calendario lun–dom).
            WEEK -> now.minusDays(6)
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

    /** Periodo comparable: mes solo días transcurridos; week/90/180/360 = ventana móvil
     *  completa. Fin exclusivo. */
    fun previousPeriodBounds(now: LocalDate = LocalDate.now(),
                             weekStartsOnMonday: Boolean = true): Pair<LocalDate, LocalDate> {
        val start = startDate(now, weekStartsOnMonday)
        return when (this) {
            TODAY -> now.minusDays(1) to now
            WEEK -> start.minusDays(7) to start
            MONTH -> {
                val elapsedDays = maxOf(1, java.time.temporal.ChronoUnit.DAYS.between(start, now).toInt() + 1)
                val prevStart = start.minusMonths(1)
                // Si el mes anterior es más corto, se limita a su último día.
                val comparableEnd = prevStart.plusDays(elapsedDays.toLong())
                prevStart to minOf(comparableEnd, start)
            }
            DAYS_90 -> start.minusDays(90) to start
            DAYS_180 -> start.minusDays(180) to start
            DAYS_360 -> start.minusDays(360) to start
        }
    }

    /** Apple b4b8f8b8: racha del periodo anterior evaluada en el mismo dia
     *  relativo (bounds.end - 1s), no necesariamente el ultimo dia de la semana
     *  o del mes anterior. */
    fun previousPeriodStreakReference(now: LocalDate = LocalDate.now(),
                                      weekStartsOnMonday: Boolean = true): LocalDate =
        previousPeriodBounds(now, weekStartsOnMonday).second.minusDays(1)

    fun containsInPreviousPeriod(date: LocalDate, now: LocalDate = LocalDate.now(),
                                 weekStartsOnMonday: Boolean = true): Boolean {
        val (start, end) = previousPeriodBounds(now, weekStartsOnMonday)
        return !date.isBefore(start) && date.isBefore(end)
    }

    companion object {
        /**
         * Apple 479d8407: la lectura de Salud se amplia bajo demanda solo cuando
         * el rango elegido necesita mas dias de los ya cargados (360d pide 730
         * con el periodo previo); nunca se vuelve a leer para un rango menor.
         * Devuelve los dias a cargar o null si la cobertura actual ya basta.
         */
        fun healthFetchWidening(loadedDays: Int, range: ProgressTimeRange): Int? =
            range.healthFetchDayCount.takeIf { it > loadedDays }

        fun fromWire(wire: String): ProgressTimeRange? = entries.firstOrNull { it.wire == wire }

        /** Zona horaria por defecto del dispositivo (para llamadas con fechas). */
        val defaultZone: ZoneId get() = ZoneId.systemDefault()
    }
}
