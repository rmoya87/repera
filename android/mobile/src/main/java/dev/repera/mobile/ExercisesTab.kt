package dev.repera.mobile

import dev.repera.mobile.monetization.LocalSubscriptions
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.IconButton
import androidx.compose.ui.Alignment
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Checkbox
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import dev.repera.domain.ExerciseAliasSearch
import dev.repera.domain.WodFormat
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import java.time.LocalDate
import java.time.LocalTime
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.delay


@Composable
internal fun ExercisesTab(
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    activeWorkout: ActiveWorkout?,
    onQuickLog: (String) -> Unit,
    onOpenExercise: (String) -> Unit,
    onSetExerciseFavorite: (String, Boolean) -> Unit = { _, _ -> },
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    onNavigateHome: () -> Unit,
    modifier: Modifier = Modifier
) {
    var exerciseSearch by rememberSaveable { mutableStateOf("") }
    var exerciseFilter by rememberSaveable { mutableStateOf("Todos") }
    val context = LocalContext.current
    val englishAliases = remember(context) { ExerciseSearchAssets.load(context) }
    // LazyListScope is not @Composable: calculate the filtered list here,
    // where remember is legal, then hand the immutable result to LazyColumn.
    val filteredExerciseEntries = remember(exerciseSearch, exerciseFilter, overview?.exerciseEntries) {
        overview?.exerciseEntries.orEmpty()
            .asSequence()
            .filter { exerciseFilter != "Favoritos" || it.isFavorite }
            .filter { ExerciseCatalogFilters.matches(it, exerciseFilter) }
            .map { it to ExerciseAliasSearch.score(exerciseSearch, it.name, englishAliases) }
            .filter { it.second >= 0 }
            .sortedWith(compareByDescending<Pair<ExerciseEntry, Int>> { it.second }
                .thenBy { it.first.name })
            .map { it.first }.toList()
    }
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Ejercicios", style = MaterialTheme.typography.headlineMedium) }
        item { CountCard("Catálogo local", overview?.exercises, overview != null) }
        item {
            OutlinedTextField(
                value = exerciseSearch,
                onValueChange = { exerciseSearch = it },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                label = { Text("Buscar ejercicio") }
            )
        }
        item {
            Row(modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                // Filtro Favoritos (paridad LibraryView iOS), además de los
                // filtros de catálogo.
                FilterChip(selected = exerciseFilter == "Favoritos",
                    onClick = { exerciseFilter = "Favoritos" },
                    label = { Text("Favoritos") })
                ExerciseCatalogFilters.available(overview?.exerciseEntries.orEmpty()).forEach { filter ->
                    FilterChip(selected = exerciseFilter == filter,
                        onClick = { exerciseFilter = filter },
                        label = { Text(filter) })
                }
            }
        }
        val entries = filteredExerciseEntries
        item {
            Text("${entries.size} ejercicios", style = MaterialTheme.typography.labelMedium)
            if (exerciseFilter == "Hyrox") {
                Text("Movimientos útiles para Hyrox presentes en el catálogo; " +
                    "no equivale al listado oficial completo de estaciones.",
                    style = MaterialTheme.typography.bodySmall)
            }
        }
        if (entries.isEmpty()) item { Text("Sin ejercicios coincidentes") }
        items(entries, key = { it.id }) { entry ->
            Card(modifier = Modifier.fillMaxWidth().clickable { onOpenExercise(entry.id) }) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically) {
                        Text(entry.displayName,
                            style = MaterialTheme.typography.titleMedium,
                            modifier = Modifier.weight(1f))
                        IconButton(onClick = {
                            onSetExerciseFavorite(entry.id, !entry.isFavorite)
                        }, enabled = !busy) {
                            Icon(
                                if (entry.isFavorite) Icons.Default.Star
                                else Icons.Default.StarBorder,
                                contentDescription = if (entry.isFavorite)
                                    "Quitar de favoritos" else "Marcar favorito",
                                tint = if (entry.isFavorite) brandGreen
                                else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    val progress = overview?.exerciseProgress?.get(entry.id)
                    var showHistory by remember(entry.id) { mutableStateOf(false) }
                    var showAllSessions by remember(entry.id) { mutableStateOf(false) }
                    val sessions = overview?.exerciseSessions?.get(entry.id).orEmpty()
                    if (progress != null) {
                        TextButton(onClick = { showHistory = !showHistory }) {
                            Text(if (showHistory) "Ocultar resumen" else "Última sesión y récords")
                        }
                        if (showHistory) {
                            progress.lastDate?.take(10)?.let {
                                Text("Última sesión: $it", style = MaterialTheme.typography.bodyMedium)
                            }
                            progress.maxWeightKg?.let { weight ->
                                Text("Récord de carga: $weight kg" +
                                    (progress.repsAtMaxWeight?.let { " · $it reps" } ?: ""))
                            }
                            progress.bestReps?.let { Text("Máximo: $it reps") }
                            progress.bestCalories?.let { Text("Máximo: $it cal") }
                            progress.bestMeters?.let { Text("Máximo: $it m") }
                            progress.bestDurationSeconds?.let { seconds ->
                                Text("Duración máxima: ${seconds / 60}:${(seconds % 60).toString().padStart(2, '0')}")
                            }
                            if (sessions.isNotEmpty()) {
                                // Historial completo por ejercicio = Pro (paridad
                                // iOS exerciseFullHistory, contexto exerciseHistory).
                                val subscriptions = LocalSubscriptions.current
                                val historyAllowed = subscriptions
                                    ?.decision(dev.repera.domain.monetization.ReperaFeature.EXERCISE_FULL_HISTORY)
                                    ?.allowed ?: true
                                if (historyAllowed) {
                                    Text("Historial · ${sessions.size} sesiones",
                                        style = MaterialTheme.typography.titleSmall)
                                    (if (showAllSessions) sessions else sessions.take(5)).forEach { visit ->
                                        Text(visit.date.take(10) + " · " + visit.title,
                                            style = MaterialTheme.typography.bodyMedium)
                                        Text(visit.lines.joinToString("  "),
                                            style = MaterialTheme.typography.labelSmall)
                                    }
                                    if (sessions.size > 5) TextButton(
                                        onClick = { showAllSessions = !showAllSessions }
                                    ) { Text(if (showAllSessions) "Ver menos" else "Ver todas las sesiones") }
                                } else {
                                    TextButton(onClick = {
                                        subscriptions?.presentPaywall(
                                            dev.repera.domain.monetization.PaywallContext.EXERCISE_HISTORY,
                                            feature = dev.repera.domain.monetization.ReperaFeature.EXERCISE_FULL_HISTORY
                                        )
                                    }) { Text("Historial completo con Repera Pro") }
                                }
                            }
                        }
                    }
                    TextButton(
                        onClick = { onQuickLog(entry.id); onNavigateHome() },
                        enabled = !busy && activeWorkout == null && entry.supportsBasicInput
                    ) { Text(if (entry.supportsBasicInput) "Apuntar series" else "Registro avanzado pendiente") }
                }
            }
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
}
