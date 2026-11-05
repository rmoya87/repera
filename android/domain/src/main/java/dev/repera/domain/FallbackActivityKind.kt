package dev.repera.domain

import java.text.Normalizer

/**
 * When a class/session has no exercise plan, Repera still records Health Connect
 * as gym strength training or HIIT — never an ambiguous “other” activity.
 * Port of Packages/ReperaDomain FallbackActivityKind.
 */
enum class FallbackActivityKind(val liveSportId: String) {
    /** Indoor gym / traditional strength (`LiveSport.STRENGTH`). */
    STRENGTH("strength"),
    /** Interval / metcon-style class (`LiveSport.HIIT`). */
    HIIT("hiit");

    companion object {
        private val hiitHints = listOf(
            "hiit", "h.i.i.t", "tabata", "interval", "metcon",
            "crossfit", "cross fit", "hyrox", "wod", "circuito",
            "circuit", "emom", "amrap", "for time"
        )

        /** Prefer HIIT when the title clearly signals intervals; otherwise gym. */
        fun resolving(title: String): FallbackActivityKind {
            val folded = Normalizer.normalize(title, Normalizer.Form.NFD)
                .replace("\\p{Mn}+".toRegex(), "")
                .lowercase()
            if (hiitHints.any { folded.contains(it) }) return HIIT
            return STRENGTH
        }
    }
}
