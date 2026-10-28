package dev.repera.mobile

import dev.repera.domain.ReperaNumberFormat
import dev.repera.domain.WeightUnit

/** Presentación kg/lb sin cambiar el almacenamiento en kilogramos. */
internal object WeightDisplay {
    fun unit(wire: String?): WeightUnit = WeightUnit.fromWire(wire)

    fun label(wire: String?): String = unit(wire).label

    /** Texto de campo a partir de kg almacenados (vacío si null). */
    fun fieldText(weightKg: Double?, unitWire: String?): String {
        if (weightKg == null || !weightKg.isFinite()) return ""
        return ReperaNumberFormat.decimal(unit(unitWire).displayValue(fromKilograms = weightKg))
    }

    /** Línea compacta « · 100 kg» / « · 220,5 lb». */
    fun suffix(weightKg: Double?, unitWire: String?): String {
        if (weightKg == null || !weightKg.isFinite()) return ""
        val u = unit(unitWire)
        return " · ${ReperaNumberFormat.decimal(u.displayValue(fromKilograms = weightKg))} ${u.label}"
    }

    /** Convierte el valor tecleado a kg; null si vacío o inválido. */
    fun parseToKg(raw: String, unitWire: String?): Double? {
        val parsed = raw.trim().takeIf { it.isNotBlank() }
            ?.let { ReperaNumberFormat.parse(it) }
            ?: return null
        if (!parsed.isFinite() || parsed < 0) return null
        return unit(unitWire).kilograms(fromDisplayValue = parsed)
    }
}
