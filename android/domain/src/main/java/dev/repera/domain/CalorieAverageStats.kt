package dev.repera.domain

/** Apple ProgressTrendCards: Media/día, Periodo ant. y Variación (siempre visibles; «—» si falta el dato). */
object CalorieAverageStats {
    fun change(daily: Double?, previous: Double?): Double? =
        if (daily == null || previous == null || previous <= 0) null else (daily / previous - 1) * 100
    fun kcalLabel(value: Double?): String = value?.let { "${Math.round(it)} kcal" } ?: "—"
    fun changeLabel(change: Double?): String = change?.let { "${if (it >= 0) "+" else ""}${Math.round(it)} %" } ?: "—"
}
