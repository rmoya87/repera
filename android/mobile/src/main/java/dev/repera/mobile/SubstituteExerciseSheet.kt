package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import dev.repera.domain.ExerciseSubstitutes

/**
 * I-40 Sustituir ejercicio: sugerencias por músculo + búsqueda en catálogo.
 */
@Composable
internal fun SubstituteExerciseSheet(
    active: ActiveWorkout,
    catalog: List<ExerciseEntry>,
    onPick: (ExerciseEntry) -> Unit,
    onDismiss: () -> Unit
) {
    var query by remember { mutableStateOf("") }
    val current = remember(active.exerciseId, active.exerciseName) {
        ExerciseSubstitutes.Candidate(
            id = active.exerciseId.ifBlank { active.exerciseName },
            name = active.exerciseName,
            targetMuscle = active.targetMuscle.takeIf { it.isNotBlank() },
            muscleGroup = active.muscleGroup.ifBlank { "Otros" },
            equipment = active.equipment.takeIf { it.isNotBlank() },
            bodyPart = null
        )
    }
    val candidates = remember(catalog) {
        catalog.map {
            ExerciseSubstitutes.Candidate(
                id = it.id,
                name = it.name,
                targetMuscle = it.targetMuscle.takeIf { t -> t.isNotBlank() },
                muscleGroup = it.muscleGroup.ifBlank { "Otros" },
                equipment = it.equipment.takeIf { e -> e.isNotBlank() },
                bodyPart = null
            )
        }
    }
    val suggested = remember(current, candidates) {
        ExerciseSubstitutes.substitutes(current, candidates)
    }
    val suggestedIds = remember(suggested) { suggested.map { it.id }.toSet() }
    val q = query.trim().lowercase()
    val searchHits = remember(q, catalog, active.exerciseId) {
        if (q.isEmpty()) emptyList()
        else catalog.filter {
            it.id != active.exerciseId &&
                (it.name.lowercase().contains(q) ||
                    it.muscleGroup.lowercase().contains(q))
        }.take(40)
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Cerrar") }
        },
        title = { Text("Sustituir ejercicio", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    "Sugerencias del mismo grupo muscular; o busca en el catálogo.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    singleLine = true,
                    label = { Text("Buscar") },
                    modifier = Modifier.fillMaxWidth().testTag("substitute_search")
                )
                LazyColumn(
                    Modifier.heightIn(max = 360.dp).testTag("substitute_list"),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    if (q.isEmpty() && suggested.isNotEmpty()) {
                        item {
                            Text(
                                "Sugeridos",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(vertical = 4.dp)
                            )
                        }
                        items(suggested, key = { "sug-${it.id}" }) { cand ->
                            val entry = catalog.firstOrNull { it.id == cand.id } ?: return@items
                            TextButton(
                                onClick = { onPick(entry) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("substitute_${entry.id}")
                            ) {
                                Text(entry.name + " · " + entry.muscleGroup)
                            }
                        }
                    }
                    if (searchHits.isNotEmpty()) {
                        item {
                            Text(
                                if (q.isEmpty()) "Catálogo" else "Resultados",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(vertical = 4.dp)
                            )
                        }
                        items(
                            searchHits.filter { it.id !in suggestedIds || q.isNotEmpty() },
                            key = { "hit-${it.id}" }
                        ) { entry ->
                            Text(
                                entry.name + " · " + entry.muscleGroup,
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { onPick(entry) }
                                    .padding(vertical = 10.dp)
                                    .testTag("substitute_${entry.id}")
                            )
                        }
                    } else if (q.isNotEmpty()) {
                        item {
                            Text(
                                "Sin coincidencias",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    } else if (suggested.isEmpty()) {
                        item {
                            Text(
                                "Escribe para buscar un ejercicio del catálogo.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
    )
}
