package dev.repera.domain

import java.time.Instant
import java.time.temporal.ChronoUnit

/**
 * Copy de cancelación Center (paridad iOS `CenterView.cancellationNotice`).
 * Pura: no toca red ni saldo; el servidor confirma créditos tras confirmar.
 */
object CenterCancellationPolicy {
    const val WINDOW_HOURS = 12L

    fun notice(startsAtIso: String?, now: Instant = Instant.now()): String {
        val starts = startsAtIso?.let { runCatching { Instant.parse(it) }.getOrNull() }
            ?: return "El centro aplicará su política de cancelación. Se comprobará el saldo real tras confirmar."
        val cutoff = now.plus(WINDOW_HOURS, ChronoUnit.HOURS)
        return if (starts > cutoff) {
            "Según la política provisional, recuperarás una sesión si cancelas con más de 12 horas de antelación. El servidor confirma el saldo."
        } else {
            "Estás dentro de las últimas 12 horas: la política provisional NO devuelve la sesión utilizada. ¿Deseas cancelar de todos modos?"
        }
    }
}
