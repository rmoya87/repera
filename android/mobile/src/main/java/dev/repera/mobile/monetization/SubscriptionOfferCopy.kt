package dev.repera.mobile.monetization

/**
 * Copy de ofertas introductorias / fases de descuento de Play Billing.
 * No inventa promociones: solo resume lo que ya viene en `pricingPhases`.
 */
object SubscriptionOfferCopy {
    data class Phase(
        val priceAmountMicros: Long,
        val formattedPrice: String,
        /** ISO-8601 Play (`P1W`, `P2W`, `P1M`, `P1Y`, …). */
        val billingPeriod: String,
        val billingCycleCount: Int = 1
    )

    data class Summary(
        val text: String?,
        val hasFreeTrial: Boolean
    )

    fun summarize(introPhases: List<Phase>): Summary {
        if (introPhases.isEmpty()) return Summary(text = null, hasFreeTrial = false)
        val hasTrial = introPhases.any { it.priceAmountMicros == 0L }
        val first = introPhases.first()
        val text = when {
            hasTrial && introPhases.size == 1 && first.priceAmountMicros == 0L ->
                freeTrialLabel(first.billingPeriod, first.billingCycleCount)
            hasTrial && introPhases.size > 1 ->
                "${freeTrialLabel(first.billingPeriod, first.billingCycleCount)} + oferta"
            first.priceAmountMicros == 0L ->
                freeTrialLabel(first.billingPeriod, first.billingCycleCount)
            else ->
                "Oferta: ${first.formattedPrice}"
        }
        return Summary(text = text, hasFreeTrial = hasTrial)
    }

    private fun freeTrialLabel(period: String, cycles: Int): String {
        val count = cycles.coerceAtLeast(1)
        return when {
            period == "P1D" || period.matches(Regex("P\\d+D")) -> {
                val days = period.removePrefix("P").removeSuffix("D").toIntOrNull() ?: 1
                val total = days * count
                if (total == 14) "14 días gratis" else "$total días gratis"
            }
            period == "P1W" -> if (count == 1) "1 semana gratis" else "$count semanas gratis"
            period == "P2W" -> if (count == 1) "14 días gratis" else "${count * 2} semanas gratis"
            period == "P1M" -> if (count == 1) "1 mes gratis" else "$count meses gratis"
            period == "P1Y" -> if (count == 1) "1 año gratis" else "$count años gratis"
            else -> "Prueba gratis"
        }
    }
}
