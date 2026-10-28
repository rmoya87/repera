package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/** Pantalla "Programas IA" (port de AITrainingProgramsView.swift): revisar y
 *  activar/pausar el marco mult semana propuesto por el asistente. */
@Composable
fun AIProgramsScreen(
    connected: Boolean,
    loading: Boolean,
    programs: List<AITrainingProgramsStore.Program>?,
    updatingId: String?,
    errorMessage: String?,
    onRefresh: () -> Unit,
    onChangeStatus: (AITrainingProgramsStore.Program, String) -> Unit
) {
    LazyColumn(modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)) {
        item { Text("Programas IA",
            style = MaterialTheme.typography.titleLarge) }
        if (!connected) {
            item {
                Text("Inicia sesión con tu cuenta para ver tus programas.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        if (loading && programs.isNullOrEmpty()) {
            item {
                Column(modifier = Modifier.fillMaxWidth().padding(8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator()
                    Text("Cargando programas…")
                }
            }
        }
        if (!loading && programs != null && programs.isEmpty() && connected) {
            item {
                ReperaCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("No hay programas de IA",
                            style = MaterialTheme.typography.titleSmall)
                        Text("Cuando tu asistente cree un programa, " +
                            "aparecerá aquí para que lo revises.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }
        items(programs ?: emptyList()) { program ->
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(program.title,
                        style = MaterialTheme.typography.titleSmall)
                    Text("${program.durationWeeks} semanas · desde " +
                        program.startDate +
                        (program.startTimeZone?.let { " · $it" } ?: ""),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(program.primaryGoal,
                        style = MaterialTheme.typography.bodyMedium)
                    Text(program.statusLabel,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    program.phases.forEach { phase ->
                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text("${phase.title} · ${phase.weeks} sem.",
                                style = MaterialTheme.typography.bodyMedium)
                            Text(phase.focus,
                                style = MaterialTheme.typography.bodySmall)
                            Text("Sesiones/semana: " +
                                phase.targetSessionsPerWeek,
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme
                                    .onSurfaceVariant)
                        }
                    }
                    when (program.status) {
                        "proposed", "paused" -> OutlinedButton(
                            onClick = { onChangeStatus(program, "active") },
                            enabled = updatingId == null
                        ) { Text("Activar programa") }
                        "active" -> OutlinedButton(
                            onClick = { onChangeStatus(program, "paused") },
                            enabled = updatingId == null
                        ) { Text("Pausar programa") }
                    }
                }
            }
        }
        errorMessage?.let {
            item { Text(it, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error) }
        }
        item {
            TextButton(onClick = onRefresh,
                enabled = connected && !loading) { Text("Actualizar") }
        }
    }
}
