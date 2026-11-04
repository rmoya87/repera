package dev.repera.wear

import java.util.Locale

/** No AI guesses: only numbers explicitly followed by reps or kilos. */
internal data class WearSpokenSet(val reps: Int?, val weightKg: Double?) {
    companion object {
        fun parse(raw: String): WearSpokenSet? {
            val text = raw.lowercase(Locale("es", "ES")).replace(',', '.')
            val reps = Regex("""\b(\d{1,3})\s*(?:repeticion(?:es)?|reps?|repes|rpt)\b""")
                .find(text)?.groupValues?.get(1)?.toIntOrNull()?.takeIf { it in 0..500 }
            val weight = Regex("""\b(\d{1,3}(?:\.\d{1,2})?)\s*(?:kg|kilos?|kilogramos?)\b""")
                .find(text)?.groupValues?.get(1)?.toDoubleOrNull()
                ?.takeIf { it.isFinite() && it in 0.0..500.0 }
            return if (reps != null || weight != null) WearSpokenSet(reps, weight) else null
        }
    }
}
