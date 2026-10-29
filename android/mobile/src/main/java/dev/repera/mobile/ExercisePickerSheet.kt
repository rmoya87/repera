package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * I-43 Selector de ejercicio: tabs Todos | Favoritos + búsqueda
 * (paridad ExercisePicker iOS).
 */
@Composable
internal fun ExercisePickerSheet(
    exercises: List<ExerciseEntry>,
    excluded: Set<String> = emptySet(),
    onPick: (ExerciseEntry) -> Unit,
    onDismiss: () -> Unit
) {
    var query by remember { mutableStateOf("") }
    var favoritesOnly by remember { mutableStateOf(false) }
    val q = query.trim()
    val filtered = remember(exercises, excluded, q, favoritesOnly) {
        exercises.asSequence()
            .filter { it.id !in excluded && !it.isCatalogArchived }
            .filter { !favoritesOnly || it.isFavorite }
            .filter {
                q.isEmpty() ||
                    it.name.contains(q, ignoreCase = true) ||
                    it.muscleGroup.contains(q, ignoreCase = true) ||
                    it.searchAliases.any { a -> a.contains(q, ignoreCase = true) }
            }
            .sortedBy { it.name.lowercase() }
            .take(80)
            .toList()
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Cerrar") }
        },
        title = { Text("Elegir ejercicio", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    ReperaFilterChip(
                        selected = !favoritesOnly,
                        onClick = { favoritesOnly = false },
                        label = { Text("Todos") }
                    )
                    ReperaFilterChip(
                        selected = favoritesOnly,
                        onClick = { favoritesOnly = true },
                        label = { Text("Favoritos") }
                    )
                }
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    singleLine = true,
                    label = { Text("Buscar") },
                    modifier = Modifier.fillMaxWidth().testTag("exercise_picker_search")
                )
                LazyColumn(
                    Modifier.heightIn(max = 360.dp).testTag("exercise_picker_list"),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    if (filtered.isEmpty()) {
                        item {
                            Text(
                                if (favoritesOnly) "No hay favoritos que coincidan."
                                else "Sin coincidencias",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    } else {
                        items(filtered, key = { it.id }) { entry ->
                            Column(
                                Modifier
                                    .fillMaxWidth()
                                    .clickable { onPick(entry) }
                                    .padding(vertical = 10.dp)
                                    .testTag("exercise_pick_${entry.id}")
                            ) {
                                Text(entry.displayName, style = MaterialTheme.typography.titleMedium)
                                Text(
                                    entry.muscleGroup.ifBlank { "Otros" },
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }
        }
    )
}
