package dev.repera.mobile

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.staticCompositionLocalOf

/** Proveedor de pasos/distancia por sesión (Apple extras.stepsCount/movementDistanceMeters), inyectado en la raíz. */
internal val LocalSessionMovement = staticCompositionLocalOf<suspend (String) -> dev.repera.domain.SessionMovement?> { { null } }

/** Quitar serie pendiente (Apple removeLiveSet), inyectado en la raíz. */
internal val LocalRemovePendingSet = staticCompositionLocalOf<(String) -> Unit> { {} }

/** Apple persistActiveLiveDraft: rows of ONE exercise (session id + index) + quantity unit. The latest rows are held in memory at once and saved shortly after; any other workout action saves them first. */
internal val LocalPersistLiveRows = staticCompositionLocalOf<(String, Int, List<ActiveSessionDraft.Row>, String?) -> Unit> { { _, _, _, _ -> } }

internal val LocalEditPendingSet = staticCompositionLocalOf<(String, Int, Double?) -> Unit> { { _, _, _ -> } }

internal object SessionMovementText {
    fun lines(m: dev.repera.domain.SessionMovement): List<String> = buildList {
        m.steps?.let { add("Pasos: %,d".format(java.util.Locale("es", "ES"), it)) }
        m.distanceMeters?.let { add("${m.distanceLabel ?: "Distancia"}: %.2f km".format(java.util.Locale("es", "ES"), it / 1000)) }
        if (m.usesTimeWindow) add("Muestras de Salud dentro del horario de la sesión, no ligadas a ella")
    }
}

@Composable
internal fun SessionMovementSection(sessionId: String) {
    val provider = LocalSessionMovement.current
    val movement by produceState<dev.repera.domain.SessionMovement?>(null, sessionId) {
        value = runCatching { provider(sessionId) }.getOrNull()
    }
    movement?.let { m ->
        val lines = SessionMovementText.lines(m)
        lines.forEachIndexed { i, line ->
            Text(line, style = if (i == 0 || !m.usesTimeWindow || i < lines.size - 1) MaterialTheme.typography.bodyMedium else MaterialTheme.typography.bodySmall)
        }
    }
}
