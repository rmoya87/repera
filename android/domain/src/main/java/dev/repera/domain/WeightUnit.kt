package dev.repera.domain

/**
 * Unidad de presentación de carga. El almacenamiento y las estadísticas
 * trabajan siempre en kilogramos (paridad WeightUnit.swift en main).
 */
enum class WeightUnit(val wire: String) {
    KG("kg"),
    LB("lb");

    val label: String get() = wire

    /** Valor mostrado al usuario a partir de kilogramos almacenados. */
    fun displayValue(fromKilograms: Double): Double =
        if (this == LB) fromKilograms * KG_TO_LB else fromKilograms

    /** Kilogramos a persistir a partir del valor tecleado en la unidad activa. */
    fun kilograms(fromDisplayValue: Double): Double =
        if (this == LB) fromDisplayValue / KG_TO_LB else fromDisplayValue

    companion object {
        const val KG_TO_LB: Double = 2.2046226218

        fun fromWire(wire: String?): WeightUnit =
            entries.firstOrNull { it.wire.equals(wire, ignoreCase = true) } ?: KG
    }
}
