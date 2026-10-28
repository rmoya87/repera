package dev.repera.mobile
import dev.repera.domain.RecoveryEngine
import java.time.LocalDate

/** Apple RecoveryHomeCard.hasHomeData: the card shows with a last night OR a cycle snippet (cycle days only exist when enabled). */
internal object HomeRecoveryModel {
    data class Model(val sleepHours: Double?, val sleepIndexOutOf10: Int?, val cycleLabel: String?)
    fun cycleLabel(phase: RecoveryEngine.CyclePhase) = when (phase) {
        RecoveryEngine.CyclePhase.MENSTRUAL -> "Menstruación registrada"
        RecoveryEngine.CyclePhase.FOLLICULAR -> "Fase folicular estimada"
        RecoveryEngine.CyclePhase.OVULATORY -> "Ovulación aproximada"
        RecoveryEngine.CyclePhase.LUTEAL -> "Fase lútea estimada"
        RecoveryEngine.CyclePhase.UNKNOWN -> "Fase no disponible"
    }
    fun of(lastNightHours: Double?, sleepIndex: Int?, menstrualDays: List<LocalDate>, today: LocalDate): Model? {
        val cycle = menstrualDays.takeIf { it.isNotEmpty() }?.let { cycleLabel(RecoveryEngine.cyclePhase(it, today)) }
        if (lastNightHours == null && cycle == null) return null
        return Model(lastNightHours, if (lastNightHours != null) sleepIndex?.let { kotlin.math.round(it / 10.0).toInt() } else null, cycle)
    }
}
