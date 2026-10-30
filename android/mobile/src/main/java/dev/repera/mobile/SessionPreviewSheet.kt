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
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
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
            // Toolbar: ☆ ··· ▶ — mismo hit 48 / círculo 44 que el resto de topbars.
            var menuOpen by remember { mutableStateOf(false) }
            var confirmDelete by remember { mutableStateOf(false) }
            Row(
                horizontalArrangement = Arrangement.spacedBy(2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                ReperaToolbarGlassIconButton(
                    icon = if (routine.isFavorite) Icons.Outlined.Star else Icons.Outlined.StarBorder,
                    contentDescription = if (routine.isFavorite) "Quitar de favoritos" else "Favorito",
                    onClick = { onToggleFavorite(!routine.isFavorite) },
                    enabled = !busy,
                    active = routine.isFavorite
                )
                Box {
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.MoreVert,
                        contentDescription = "Más",
                        onClick = { menuOpen = true }
                    )
                    DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                        DropdownMenuItem(
                            text = { Text("Editar") },
                            onClick = { menuOpen = false; onEdit() })
                        DropdownMenuItem(
                            text = { Text("Borrar entreno", color = MaterialTheme.colorScheme.error) },
                            onClick = { menuOpen = false; confirmDelete = true })
                    }
                }
                val isFuture = routine.scheduledDate?.let { iso ->
                    runCatching { LocalDate.parse(iso.take(10)).isAfter(LocalDate.now()) }
                        .getOrDefault(false)
                } == true
                val canStart = !busy && routine.supported && !isFuture
                val playTint = if (canStart) brandGreen
                else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.35f)
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .clickable(
                            enabled = canStart,
                            onClick = { onStart(); onClose() }
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        Modifier
                            .size(44.dp)
                            .clip(CircleShape)
                            .background(playTint),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Filled.PlayArrow,
                            contentDescription = if (isFuture)
                                "No se puede empezar un entreno futuro"
                            else "Empezar entrenamiento",
                            tint = if (canStart) Color.Black
                            else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
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
            // Por hacer: solo ejercicios (mismo desglose Apple que el resumen).
            RoutinePlanBreakdown(
                blocks = routine.blocks,
                exerciseCatalog = exerciseCatalog,
                onOpenExercise = onOpenExercise
            )
        }
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

