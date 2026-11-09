package dev.repera.domain

enum class AdaptiveLoadDecision { INCREASE, MAINTAIN, DELOAD, INSUFFICIENT_DATA }

data class AdaptiveLoadObservation(
    val completed: Boolean,
    val rir: Double?,
    val relativeE1RMChange: Double?,
    val hoursSincePreviousSession: Double?
)

data class AdaptiveLoadAdvice(val decision: AdaptiveLoadDecision, val reason: String)

/** Advisory only: never writes to workouts, never proposes perpetual increments. */
object AdaptiveLoadGuard {
    fun evaluate(recent: List<AdaptiveLoadObservation>, recoveryReady: Boolean? = null): AdaptiveLoadAdvice {
        val sample = recent.take(4)
        if (sample.size < 2) return AdaptiveLoadAdvice(
            AdaptiveLoadDecision.INSUFFICIENT_DATA, "Faltan sesiones comparables."
        )
        if (sample.any {
                (it.rir != null && (!it.rir.isFinite() || it.rir !in 0.0..10.0)) ||
                    (it.relativeE1RMChange != null && !it.relativeE1RMChange.isFinite()) ||
                    (it.hoursSincePreviousSession != null &&
                        (!it.hoursSincePreviousSession.isFinite() || it.hoursSincePreviousSession < 0))
            }) return AdaptiveLoadAdvice(
                AdaptiveLoadDecision.INSUFFICIENT_DATA, "Métricas incompletas o inválidas."
            )
        if (sample.take(3).size == 3 && sample.take(3).all { !it.completed }) {
            return AdaptiveLoadAdvice(AdaptiveLoadDecision.DELOAD, "Tres sesiones seguidas sin completar el objetivo.")
        }
        if (recoveryReady == false) {
            return AdaptiveLoadAdvice(AdaptiveLoadDecision.MAINTAIN, "Recuperación insuficiente: mantener la carga.")
        }
        if (!sample.take(2).all { it.completed }) {
            return AdaptiveLoadAdvice(AdaptiveLoadDecision.MAINTAIN, "Consolidar los objetivos antes de subir.")
        }
        if (!sample.take(2).all { (it.rir ?: -1.0) >= 2.0 }) {
            return AdaptiveLoadAdvice(AdaptiveLoadDecision.MAINTAIN, "Sin margen RIR suficiente para progresar.")
        }
        if (sample.any { (it.hoursSincePreviousSession ?: 72.0) < 24.0 }) {
            return AdaptiveLoadAdvice(AdaptiveLoadDecision.MAINTAIN, "Sesiones demasiado próximas para sugerir aumento.")
        }
        if (sample.take(2).any { (it.relativeE1RMChange ?: 0.0) < -0.05 }) {
            return AdaptiveLoadAdvice(AdaptiveLoadDecision.MAINTAIN, "Tendencia de fuerza descendente.")
        }
        return AdaptiveLoadAdvice(AdaptiveLoadDecision.INCREASE, "Dos sesiones completadas con al menos 2 RIR.")
    }
}
