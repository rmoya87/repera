package dev.repera.domain


/** Apple ProgressTrendCards (live main): Actual / Objetivo / Δ siempre visibles, «—» si falta el dato. */
object WeightStatsTiles {
    data class Labels(val actual: String, val goal: String, val delta: String)

    private fun kg(v: Double) = ReperaNumberFormat.decimal(v) + " kg"

    fun labels(latestKg: Double?, goalKg: Double?): Labels {
        val delta = if (latestKg != null && goalKg != null) latestKg - goalKg else null
        return Labels(
            actual = latestKg?.let(::kg) ?: "—",
            goal = goalKg?.let(::kg) ?: "—",
            delta = delta?.let { (if (it > 0) "+" else "") + kg(it) } ?: "—"
        )
    }
}
