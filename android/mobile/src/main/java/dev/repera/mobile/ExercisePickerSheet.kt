package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.Tune
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

/** Últimos ejercicios del historial (máx. [limit]; paridad iOS `recentExerciseIDs`). */
internal fun recentExerciseIdsFromHistory(
    history: List<WorkoutHistoryEntry>,
    limit: Int = 5,
): List<String> {
    val seen = linkedSetOf<String>()
    for (session in history) {
        for (move in session.movements) {
            val id = move.catalogExerciseId
            if (id.isBlank()) continue
            if (seen.add(id) && seen.size >= limit) return seen.toList()
        }
    }
    return seen.toList()
}

/**
 * Selector de ejercicio a pantalla completa (paridad ExercisePicker iOS):
 * título → búsqueda → chips musculares → Recientes (máx. 5, solo «Todos») y multiselección.
 */
@Composable
internal fun ExercisePickerSheet(
    exercises: List<ExerciseEntry>,
    excluded: Set<String> = emptySet(),
    onPick: (ExerciseEntry) -> Unit = {},
    onDismiss: () -> Unit,
    allowsMultipleSelection: Boolean = false,
    onPickMany: ((List<ExerciseEntry>) -> Unit)? = null,
    recentExerciseIds: List<String> = emptyList(),
) {
    var query by remember { mutableStateOf("") }
    var favoritesOnly by remember { mutableStateOf(false) }
    var muscleFilter by remember { mutableStateOf<String?>(null) }
    var selected by remember { mutableStateOf(setOf<String>()) }
    val context = LocalContext.current
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    val q = query.trim()
    val muscleOptions = remember(exercises) {
        exercises.map { it.muscleGroup }.filter { it.isNotBlank() }.distinct().sorted()
    }
    val filtered = remember(exercises, excluded, q, favoritesOnly, muscleFilter) {
        exercises.asSequence()
            .filter { it.id !in excluded && !it.isCatalogArchived }
            .filter { !favoritesOnly || it.isFavorite }
            .filter { muscleFilter == null || it.muscleGroup == muscleFilter }
            .filter {
                q.isEmpty() ||
                    it.name.contains(q, ignoreCase = true) ||
                    it.muscleGroup.contains(q, ignoreCase = true) ||
                    it.searchAliases.any { a -> a.contains(q, ignoreCase = true) }
            }
            .sortedBy { it.name.lowercase() }
            .take(200)
            .toList()
    }
    val recentRows = remember(recentExerciseIds, exercises) {
        recentExerciseIds
            .mapNotNull { id -> exercises.firstOrNull { it.id == id } }
            .take(5)
    }
    val showsRecents =
        allowsMultipleSelection &&
            q.isEmpty() &&
            !favoritesOnly &&
            muscleFilter == null &&
            recentRows.isNotEmpty()

    ReperaFullscreenDialog(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .statusBarsPadding()
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
                Spacer(Modifier.weight(1f))
                ReperaToolbarGlassIconButton(
                    icon = Icons.Outlined.Tune,
                    contentDescription = "Filtrar",
                    onClick = { favoritesOnly = !favoritesOnly },
                    active = favoritesOnly,
                    modifier = Modifier.testTag("exercise_picker_filter")
                )
            }
            // Título grande antes del buscador (paridad iOS / Biblioteca).
            ReperaPageHeader(
                title = "Elegir ejercicio",
                trailing = {},
                modifier = Modifier
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 4.dp)
                    .testTag("exercise_picker_title")
            )
            // Mismo inset horizontal 16 que LazyColumn → alineado con el listado.
            ReperaSearchField(
                value = query,
                onValueChange = { query = it },
                placeholder = "Buscar ejercicio",
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .testTag("exercise_picker_search")
            )
            // Chips de borde a borde; el aire 16 va como padding de contenido.
            Row(
                Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Spacer(Modifier.width(16.dp))
                MuscleFilterChip("Todos", selected = muscleFilter == null) { muscleFilter = null }
                muscleOptions.take(8).forEach { muscle ->
                    MuscleFilterChip(muscle, selected = muscleFilter == muscle) { muscleFilter = muscle }
                }
                Spacer(Modifier.width(16.dp))
            }
            LazyColumn(
                Modifier.weight(1f),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                if (showsRecents) {
                    item {
                        Text(
                            "Recientes",
                            style = MaterialTheme.typography.titleSmall,
                            modifier = Modifier.padding(vertical = 8.dp)
                        )
                    }
                    items(recentRows, key = { "recent-${it.id}" }) { entry ->
                        PickerRow(entry, aliases, selected.contains(entry.id), allowsMultipleSelection) {
                            if (allowsMultipleSelection) {
                                selected = if (entry.id in selected) selected - entry.id else selected + entry.id
                            } else onPick(entry)
                        }
                    }
                    item {
                        Text(
                            "Todos (A–Z)",
                            style = MaterialTheme.typography.titleSmall,
                            modifier = Modifier.padding(vertical = 8.dp)
                        )
                    }
                }
                if (filtered.isEmpty()) {
                    item {
                        Text(
                            if (favoritesOnly) "No hay favoritos que coincidan." else "Sin coincidencias",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(vertical = 16.dp)
                        )
                    }
                } else {
                    items(filtered, key = { it.id }) { entry ->
                        PickerRow(entry, aliases, selected.contains(entry.id), allowsMultipleSelection) {
                            if (allowsMultipleSelection) {
                                selected = if (entry.id in selected) selected - entry.id else selected + entry.id
                            } else {
                                onPick(entry)
                                onDismiss()
                            }
                        }
                    }
                }
            }
            if (allowsMultipleSelection && selected.isNotEmpty()) {
                FloatingPrimaryCta(
                    title = "Añadir ${selected.size} ejercicio${if (selected.size == 1) "" else "s"}",
                    onClick = {
                        val picked = selected.mapNotNull { id -> exercises.firstOrNull { it.id == id } }
                        onPickMany?.invoke(picked)
                        onDismiss()
                    },
                    modifier = Modifier
                        .navigationBarsPadding()
                        .testTag("exercise_picker_add_many")
                )
            } else {
                Spacer(Modifier.navigationBarsPadding())
            }
        }
    }
}

@Composable
private fun MuscleFilterChip(label: String, selected: Boolean, onClick: () -> Unit) {
    val dark = isSystemInDarkTheme()
    // No seleccionado: blanco en día / negro en noche (paridad toolbar glass).
    val bg = when {
        selected -> brandGreen
        dark -> Color.Black
        else -> Color.White
    }
    val border = if (selected) {
        Color.Transparent
    } else {
        MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)
    }
    Text(
        label,
        modifier = Modifier
            .clip(CircleShape)
            .background(bg, CircleShape)
            .then(
                if (selected) Modifier else Modifier.border(1.dp, border, CircleShape)
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        color = if (selected) Color.Black else MaterialTheme.colorScheme.onSurface,
        style = MaterialTheme.typography.labelLarge
    )
}

@Composable
private fun PickerRow(
    entry: ExerciseEntry,
    aliases: Map<String, String>,
    checked: Boolean,
    multiselect: Boolean,
    onClick: () -> Unit,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(MaterialTheme.shapes.medium)
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp, horizontal = 4.dp)
            .testTag("exercise_pick_${entry.id}"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        ExerciseListThumb(
            name = entry.name,
            sportTag = entry.sportTag,
            aliases = aliases,
            artKeys = entry.artKeys,
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(entry.displayName, style = MaterialTheme.typography.titleMedium)
            Text(
                libraryExerciseSubtitle(entry),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        if (multiselect) {
            Icon(
                if (checked) Icons.Filled.CheckCircle else Icons.Outlined.AddCircleOutline,
                contentDescription = null,
                tint = if (checked) brandGreen else MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
