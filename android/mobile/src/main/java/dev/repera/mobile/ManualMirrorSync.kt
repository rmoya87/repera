package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/** Estado del botón "Sincronizar ahora" (Apple SettingsView + BusinessWorkoutSyncStore). */
internal data class ManualMirrorSyncState(
    val isSyncing: Boolean = false,
    val connected: Boolean = false,
    val lastSyncAtText: String? = null,
    val mirroredCount: Int = 0,
    val error: String? = null,
    val onSync: () -> Unit = {}
)

internal val LocalManualMirrorSync = staticCompositionLocalOf { ManualMirrorSyncState() }

internal object ManualMirrorSyncText {
    const val NOT_CONNECTED = "No hay una sesión activa en la nube. Reconecta tu cuenta en Ajustes."
    const val IDLE = "Los entrenos finalizados se guardan en este dispositivo y se sincronizan al conectar tu cuenta."
    /** Apple: error > última sincronización > texto inicial. */
    fun footer(state: ManualMirrorSyncState): String = state.error
        ?: state.lastSyncAtText?.let { "Última sincronización: $it · ${state.mirroredCount} registros remotos" }
        ?: IDLE
}

@Composable
internal fun ManualMirrorSyncRow() {
    val state = LocalManualMirrorSync.current
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        OutlinedButton(onClick = state.onSync, enabled = !state.isSyncing && state.connected) {
            Text(if (state.isSyncing) "Sincronizando…" else "Sincronizar ahora")
        }
        Text(ManualMirrorSyncText.footer(state), style = MaterialTheme.typography.bodySmall,
            color = if (state.error != null) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
