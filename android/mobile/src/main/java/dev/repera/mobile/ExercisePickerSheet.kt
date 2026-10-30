package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable

/**
 * Selector de ejercicio a pantalla completa (paridad ExercisePicker iOS).
 * Topbar: ← / filtrar con [ReperaToolbarGlassIconButton] (círculo blanco día).
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
    val context = LocalContext.current
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
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
            .take(120)
            .toList()
    }

    ReperaFullscreenDialog(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .statusBarsPadding()
                .navigationBarsPadding()
                .testTag("exercise_picker_fullscreen")
        ) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                ReperaToolbarGlassIconButton(
                    icon = Icons.AutoMirrored.Outlined.ArrowBack,
                    contentDescription = "Volver",
                    onClick = onDismiss,
                    modifier = Modifier.testTag("exercise_picker_back")
                )
                Text(
                    "Elegir ejercicio",
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                ReperaToolbarGlassIconButton(
                    icon = Icons.Outlined.Tune,
                    contentDescription = "Filtrar",
                    onClick = { favoritesOnly = !favoritesOnly },
                    active = favoritesOnly,
                    modifier = Modifier.testTag("exercise_picker_filter")
                )
            }
            ReperaSearchField(
                value = query,
                onValueChange = { query = it },
                placeholder = "Buscar ejercicio",
                modifier = Modifier
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .testTag("exercise_picker_search")
            )
            LazyColumn(
                Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                if (filtered.isEmpty()) {
                    item {
                        Text(
                            if (favoritesOnly) "No hay favoritos que coincidan."
                            else "Sin coincidencias",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(vertical = 16.dp)
                        )
                    }
                } else {
                    items(filtered, key = { it.id }) { entry ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .clickable { onPick(entry) }
                                .padding(vertical = 10.dp)
                                .testTag("exercise_pick_${entry.id}"),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            ExerciseListThumb(
                                name = entry.name,
                                sportTag = entry.sportTag,
                                aliases = aliases
                            )
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    entry.displayName,
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Text(
                                    libraryExerciseSubtitle(entry),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
