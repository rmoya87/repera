package dev.repera.domain

import java.text.DecimalFormat
import java.text.DecimalFormatSymbols

/**
 * Port 1:1 de ReperaNumberFormat.swift (032de96d): formato visible único
 * «1.234,56», independiente del idioma del dispositivo; nunca para serializar
 * datos (JSON, Supabase, Health Connect…). Máximo dos decimales en pantalla.
 */
object ReperaNumberFormat {

    /** Solo los decimales necesarios (máximo dos) y agrupación desde 1.000. */
    fun decimal(value: Double, maximumFractionDigits: Int = 2, minimumFractionDigits: Int = 0): String {
        if (!value.isFinite()) return "—"
        val maximum = minOf(2, maxOf(0, maximumFractionDigits))
        val symbols = DecimalFormatSymbols().apply {
            // Apple fija en_US + separadores explícitos: CLDR es_ES omite a
            // veces la agrupación en cifras de cuatro dígitos.
            groupingSeparator = '.'
            decimalSeparator = ','
        }
        val format = DecimalFormat("#,##0.###", symbols)
        format.isGroupingUsed = true
        format.groupingSize = 3
        format.minimumFractionDigits = minOf(maximum, maxOf(0, minimumFractionDigits))
        format.maximumFractionDigits = maximum
        return format.format(value)
    }

    fun integer(value: Int): String = decimal(value.toDouble(), 0, 0)

    /**
     * Admite entradas españolas («1.234,56»), decimales heredados («1234.56»)
     * y cadenas sin separador. El punto seguido de grupos de tres dígitos se
     * interpreta como millares solo si no hay coma.
     */
    fun parse(input: String): Double? {
        val compact = input.trim()
            .replace(" ", "")
            .replace(" ", "")
            .replace(" ", "")
        if (compact.isEmpty()) return null
        val normalized = when {
            compact.contains(",") -> compact.replace(".", "").replace(",", ".")
            THOUSANDS_DOTTED.matches(compact) -> compact.replace(".", "")
            else -> compact
        }
        val result = normalized.toDoubleOrNull() ?: return null
        return if (result.isFinite()) result else null
    }

    private val THOUSANDS_DOTTED = Regex("^[+-]?[0-9]{1,3}(\\.[0-9]{3})+$")
}
