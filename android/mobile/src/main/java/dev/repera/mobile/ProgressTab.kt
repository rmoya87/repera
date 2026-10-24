package dev.repera.mobile

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.delay


@Composable
internal fun ProgressTab(
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Deliberately limited to the recent archive loaded by StateOverview.
    // It must never be presented as complete lifetime or billing-gated analytics.
    val recent = overview?.history.orEmpty()
    val today = LocalDate.now()
    val weekStart = today.minusDays((today.dayOfWeek.value - 1).toLong())
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Progreso", style = MaterialTheme.typography.headlineMedium) }
        item { CountCard("Entrenamientos registrados", overview?.workouts, overview != null) }
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text("Esta semana", style = MaterialTheme.typography.titleLarge)
                    Text("${overview?.workoutsThisWeek ?: 0} sesiones esta semana",
                        style = MaterialTheme.typography.headlineSmall)
                    Text("Del ${weekStart} al ${today}")
                    WeekTrainingBars(overview?.weeklyDayTotals.orEmpty())
                    Text("El total semanal usa todo el historial local. " +
                        "Los detalles de abajo muestran las últimas 20 sesiones.",
                        style = MaterialTheme.typography.bodySmall)
                }
            }
        }
        if (overview?.weeklyMuscleGroups?.isNotEmpty() == true) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Series por grupo · esta semana",
                            style = MaterialTheme.typography.titleMedium)
                        val groups = overview.weeklyMuscleGroups.take(8)
                        val ceiling = groups.maxOf { it.sets }.coerceAtLeast(1).toFloat()
                        groups.forEach { group ->
                            Text("${group.group} · ${group.sets} series",
                                style = MaterialTheme.typography.bodySmall)
                            LinearProgressIndicator(
                                progress = { group.sets.toFloat() / ceiling },
                                modifier = Modifier.fillMaxWidth(),
                                color = brandGreen
                            )
                        }
                        Text("Distribución por grupo del catálogo; no mide fatiga ni recuperación.",
                            style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }
        if (recent.isNotEmpty()) {
            item {
                Text("Resultados recientes", style = MaterialTheme.typography.titleMedium)
            }
            items(recent, key = { "progress:" + it.id }) { workout ->
                WorkoutHistoryCard(workout)
            }
        } else {
            item { Text("Todavía no hay entrenamientos para analizar") }
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
}
