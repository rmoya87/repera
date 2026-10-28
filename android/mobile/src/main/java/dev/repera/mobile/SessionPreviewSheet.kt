package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.IconButton
import androidx.compose.material3.Icon
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.Icons
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

/**
 * Resumen del plan antes de empezar (SessionPreviewView iOS): cabecera con el
 * día, bloques/ejercicios de la rutina, menú Editar/Borrar y botón Play.
 * La sesión en curso se gestiona desde su propia tarjeta (HomeTab).
 */
@Composable
fun SessionPreviewSheet(
    routine: RoutineEntry,
    busy: Boolean,
    onStart: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onClose: () -> Unit,
    /** Apple 3cb329f3/3666d1ac: destino unico administrado por el padre;
     *  cada fila abre SOLO el ejercicio pulsado. */
    onOpenExercise: (String) -> Unit = {}
) {
    val day = dayLabel(routine)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(bottom = 28.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(routine.title, style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold)
                if (day.isNotEmpty()) {
                    Text("Entreno · $day", style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            var menuOpen by remember { mutableStateOf(false) }
            var confirmDelete by remember { mutableStateOf(false) }
            TextButton(onClick = { menuOpen = true }) { Text("⋯") }
            DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                DropdownMenuItem(
                    text = { Text("Editar") },
                    onClick = { menuOpen = false; onEdit() })
                DropdownMenuItem(
                    text = { Text("Borrar entreno", color = MaterialTheme.colorScheme.error) },
                    onClick = { menuOpen = false; confirmDelete = true })
            }
            // showDeleteConfirm iOS: borrar una rutina pide confirmación.
            if (confirmDelete) {
                androidx.compose.material3.AlertDialog(
                    onDismissRequest = { confirmDelete = false },
                    confirmButton = {
                        TextButton(onClick = { confirmDelete = false; onDelete() }) {
                            Text("Borrar", color = MaterialTheme.colorScheme.error)
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { confirmDelete = false }) { Text("Cancelar") }
                    },
                    title = { Text("Borrar entreno") },
                    text = { Text("Se borra «${routine.title}». Esta acción no se puede deshacer.") }
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        if (routine.blocks.isEmpty()) {
            ReperaEmptyState(
                title = "Esta rutina no tiene bloques",
                subtitle = "Edítala para añadir ejercicios"
            )
        } else {
            routine.blocks.forEach { block ->
                ReperaCard(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)
                ) {
                    Column(Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(block.title, style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold)
                        Text(blockFormatLabel(block),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        block.entries.forEach { entry ->
                            val tappable = entry.exerciseId.isNotBlank()
                            val entryModifier = if (tappable)
                                Modifier.fillMaxWidth().clickable { onOpenExercise(entry.exerciseId) }
                            else Modifier.fillMaxWidth()
                            Row(entryModifier, verticalAlignment = Alignment.CenterVertically) {
                            val detail = buildString {
                                append(entry.name)
                                // Apple 8a940bc5: la vista previa muestra metros
                                // y kg (14 m · 18 kg), nunca "reps" para metros.
                                val unitLabel = when (entry.quantityUnit) {
                                    "meters" -> " m"; "calories" -> " cal"; else -> ""
                                }
                                if (entry.sets > 0 && entry.quantity > 0) {
                                    if (unitLabel.isNotEmpty())
                                        append(" — ${entry.sets}×${entry.quantity}$unitLabel")
                                    else append(" — ${entry.sets}×${entry.quantity}")
                                } else if (entry.quantity > 0) {
                                    append(" — ${entry.quantity}$unitLabel")
                                }
                                entry.weightKg?.let { w ->
                                    append(" @ ${dev.repera.domain.ReperaNumberFormat.decimal(w)} kg")
                                }
                            }
                            Text("· $detail", style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.weight(1f))
                            // Apple e3f1d652: conservar el chevron de disclosure.
                            if (tappable) Text("›",
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
            }
        }
        Spacer(Modifier.height(16.dp))
        Button(
            onClick = { onStart(); onClose() },
            enabled = !busy && routine.supported,
            modifier = Modifier.fillMaxWidth()
        ) { Text(if (routine.supported) "Empezar entrenamiento" else "Formato no disponible") }
        TextButton(onClick = onClose, modifier = Modifier.fillMaxWidth()) { Text("Cerrar") }
    }
}

/** Etiqueta de día 1:1 con SessionPreviewView.dayLabel iOS. */
private fun dayLabel(routine: RoutineEntry): String {
    val locale = Locale("es")
    val day = routine.scheduledDate?.let {
        runCatching { LocalDate.parse(it).dayOfWeek }.getOrNull()
    }?.getDisplayName(TextStyle.FULL, locale)?.replaceFirstChar { it.uppercase(locale) }
        ?: routine.weekday?.let { wd ->
            DayOfWeek.of(wd).getDisplayName(TextStyle.FULL, locale)
                .replaceFirstChar { it.uppercase(locale) }
        } ?: LocalDate.now().dayOfWeek.getDisplayName(TextStyle.FULL, locale)
            .replaceFirstChar { it.uppercase(locale) }
    val minutes = routine.timeMinutes
    return if (minutes != null) "%s · %02d:%02d".format(day, minutes / 60, minutes % 60) else day
}

private fun blockFormatLabel(block: RoutineBlockInfo): String = when (block.format) {
    "strength" -> "Fuerza"
    "amrap" -> "AMRAP ${block.timeCapMinutes}'"
    "emom" -> "EMOM ${block.timeCapMinutes}' · cada ${block.emomIntervalSeconds}s"
    "fortime" -> "For Time · cap ${block.timeCapMinutes}'"
    "tabata" -> "Tabata ${block.workSeconds}/${block.restSeconds}s × ${block.rounds}"
    else -> block.format
}
