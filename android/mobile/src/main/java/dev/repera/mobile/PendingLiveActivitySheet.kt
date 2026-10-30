package dev.repera.mobile

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.repera.domain.LiveActivityState

/**
 * Modal cuando hay una actividad En vivo pendiente y el usuario quiere
 * empezar otro entreno: cerrar/guardar la anterior y continuar.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun PendingLiveActivitySheet(
    onConfirmCloseAndContinue: () -> Unit,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 20.dp)
                .padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                "Actividad en vivo pendiente",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Text(
                "Hay una actividad de Comenzar en curso. Si continúas, se guardará como entreno y empezará la nueva.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(4.dp))
            Button(
                onClick = onConfirmCloseAndContinue,
                colors = reperaPrimaryButtonColors(),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Cerrar la anterior y empezar", fontWeight = FontWeight.Bold)
            }
            TextButton(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Seguir con la actividad en vivo")
            }
        }
    }
}

/** Finaliza y guarda la live pendiente (si existe). Devuelve false si no pudo. */
internal fun finishAndSavePendingLiveActivity(
    context: Context,
    accountId: String,
): Boolean {
    if (accountId.isBlank()) return false
    if (!LiveActivityRuntime.hasPendingActivity(context, accountId)) return true
    return try {
        val runtime = LiveActivityRuntime.forAccount(context, accountId)
        if (runtime.recoveryBlocked) {
            // Checkpoint dañado: el usuario confirma cerrar → descartar para desbloquear.
            runtime.discard()
            LiveActivityService.stop(context)
            return true
        }
        val now = System.currentTimeMillis()
        when (runtime.state.phase) {
            LiveActivityState.Phase.RECORDING,
            LiveActivityState.Phase.PAUSED -> runtime.finish()
            else -> Unit
        }
        val snap = runtime.state.snapshot(now)
        if (snap != null &&
            (snap.phase == LiveActivityState.Phase.REVIEW ||
                runtime.state.phase == LiveActivityState.Phase.REVIEW)
        ) {
            val title = runtime.state.sport.title
            WorkoutRepository(context, accountId).saveLiveActivity(
                snap,
                runtime.state.finishedMillis ?: now,
                runtime.state.durationSeconds(now),
                title,
                ""
            )
        }
        runtime.discard()
        LiveActivityService.stop(context)
        true
    } catch (_: Exception) {
        false
    }
}
