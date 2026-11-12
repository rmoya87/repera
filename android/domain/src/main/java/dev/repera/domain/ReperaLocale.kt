package dev.repera.domain

import java.util.Locale

/** Español con región del usuario; números/horas/calendario localizados (paridad ReperaLocale iOS). */
object ReperaLocale {
    val app: Locale
        get() {
            val current = Locale.getDefault()
            val language = current.language.ifBlank { "es" }
            val country = current.country
            return if (country.isNotBlank()) {
                Locale.Builder().setLanguage(language).setRegion(country).build()
            } else {
                Locale.Builder().setLanguage("es").setRegion("ES").build()
            }
        }
}
