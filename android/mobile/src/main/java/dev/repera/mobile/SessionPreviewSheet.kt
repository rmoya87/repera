package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
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
    onOpenExercise: (String) -> Unit = {},
    onToggleFavorite: (Boolean) -> Unit = {},
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
) {
    val day = dayLabel(routine)
    val context = LocalContext.current
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(bottom = 28.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            ReperaToolbarGlassIconButton(
                icon = Icons.Outlined.Close,
                contentDescription = "Cerrar",
                onClick = onClose
            )
            Column(Modifier.weight(1f).padding(start = 8.dp)) {
                // iOS SessionPreviewView: título fijo «Entreno»; nombre de rutina en contenido.
                Text("Entreno", style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold)
                if (day.isNotEmpty()) {
                    Text(day, style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            // Toolbar iOS: ☆ ··· ▶
            IconButton(
                enabled = !busy,
                onClick = { onToggleFavorite(!routine.isFavorite) }
            ) {
                Icon(
                    if (routine.isFavorite) Icons.Outlined.Star else Icons.Outlined.StarBorder,
                    contentDescription = if (routine.isFavorite) "Quitar de favoritos" else "Favorito",
                    tint = if (routine.isFavorite) brandGreen else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            var menuOpen by remember { mutableStateOf(false) }
            var confirmDelete by remember { mutableStateOf(false) }
            Box {
                IconButton(onClick = { menuOpen = true }) {
                    Icon(Icons.Outlined.MoreVert, contentDescription = "Más")
                }
                DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                    DropdownMenuItem(
                        text = { Text("Editar") },
                        onClick = { menuOpen = false; onEdit() })
                    DropdownMenuItem(
                        // R8 P2-5: rutina planificada = «Borrar entreno» (iOS).
                        text = { Text("Borrar entreno", color = MaterialTheme.colorScheme.error) },
                        onClick = { menuOpen = false; confirmDelete = true })
                }
            }
            IconButton(
                enabled = !busy && routine.supported,
                onClick = { onStart(); onClose() },
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(brandGreen)
            ) {
                Icon(
                    Icons.Filled.PlayArrow,
                    contentDescription = "Empezar entrenamiento",
                    tint = Color.Black
                )
            }
            if (confirmDelete) {
                // Paridad iOS (terminados): «¿Eliminar entreno?» / «Eliminar».
                ReperaConfirmSheet(
                    title = "¿Eliminar entreno?",
                    message = "Se eliminará «${routine.title}» de este día.",
                    confirmTitle = "Eliminar",
                    onConfirm = { confirmDelete = false; onDelete() },
                    onCancel = { confirmDelete = false }
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
                    Column(Modifier.padding(16.dp),
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
                            Row(
                                entryModifier.padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                            val resolved = remember(entry.exerciseId, entry.name, exerciseCatalog) {
                                if (entry.exerciseId.isNotBlank()) {
                                    exerciseCatalog.firstOrNull { it.id == entry.exerciseId }
                                        ?: resolveWodExercise(entry.name, exerciseCatalog, aliases,
                                            exerciseId = entry.exerciseId)
                                } else {
                                    resolveWodExercise(entry.name, exerciseCatalog, aliases)
                                }
                            }
                            WodExerciseThumbnail(resolved, aliases, size = 44.dp)
                            val detail = buildString {
                                // R7 P1: nombre del ejercicio (no «· — 3×8»).
                                append(entry.name.ifBlank { "Ejercicio" })
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
                            Text(detail, style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.weight(1f))
                            if (tappable) {
                                Icon(
                                    Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            }
                        }
                    }
                }
            }
        }
        // R7 P1: sin CTA extra «Empezar entrenamiento» (iOS solo tiene ▶ en cabecera).
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
    "" -> "Sin formato"
    "strength" -> "Fuerza"
    "amrap" -> "AMRAP ${block.timeCapMinutes}'"
    "emom" -> "EMOM ${block.timeCapMinutes}' · cada ${block.emomIntervalSeconds}s"
    "fortime", "forTime" -> "For Time · cap ${block.timeCapMinutes}'"
    "tabata" -> "Tabata ${block.workSeconds}/${block.restSeconds}s × ${block.rounds}"
    else -> BlockFormatCatalog.title(block.format)
}
