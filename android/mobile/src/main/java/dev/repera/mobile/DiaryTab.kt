package dev.repera.mobile

import androidx.compose.ui.Alignment
import androidx.compose.foundation.clickable
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
internal fun DiaryTab(
    aiPrograms: List<AITrainingProgramsStore.Program> = emptyList(),
    onOpenAIPrograms: () -> Unit = {},
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    activeWorkout: ActiveWorkout?,
    onStartRoutine: (String) -> Unit,
    onEditRoutine: (String, String, RoutineSchedule) -> Unit,
    onDeleteRoutine: (String) -> Unit,
    onEditRoutineContent: (String) -> Unit = {},
    onSetRoutineProgression: (String, String) -> Unit = { _, _ -> },
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    onNavigateHome: () -> Unit,
    modifier: Modifier = Modifier
) {
    var diaryDateIso by rememberSaveable { mutableStateOf(LocalDate.now().toString()) }
    val routines = overview?.routineEntries.orEmpty()
    val day = LocalDate.parse(diaryDateIso)
    val todays = routines.filter {
        it.scheduledDate == day.toString() ||
            (it.scheduledDate == null && it.weekday == day.dayOfWeek.value)
    }
    val dated = routines.filter {
        it.scheduledDate != null && it.scheduledDate != day.toString()
    }.sortedBy { it.scheduledDate }
    val weekly = routines.filter { it.weekday != null }
    val library = routines.filter {
        it.scheduledDate == null && it.weekday == null
    }
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Diario", style = MaterialTheme.typography.headlineMedium) }
        // Programas IA (paridad PlanView iOS): entrada cuando el asistente ha
        // propuesto algún programa mult semana.
        if (aiPrograms.isNotEmpty()) {
            items(aiPrograms.take(3), key = { "programa-" + it.id }) { program ->
                Card(modifier = Modifier.fillMaxWidth()
                    .clickable(onClick = onOpenAIPrograms)) {
                    Row(modifier = Modifier.fillMaxWidth().padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(program.title,
                                style = MaterialTheme.typography.titleSmall)
                            Text("${program.durationWeeks} semanas · " +
                                program.startDate + " · " + program.statusLabel,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme
                                    .onSurfaceVariant)
                        }
                    }
                }
            }
        }
        item { CountCard("Rutinas", overview?.routines, overview != null) }
        item {
            WeekCalendarStrip(day) { chosen -> diaryDateIso = chosen.toString() }
        }
        if (routines.isEmpty()) item { Text("No hay rutinas creadas") }
        if (todays.isNotEmpty()) item {
            Text("Entrenamientos · " + day.format(reperaDayFormatter), style = MaterialTheme.typography.titleLarge)
        } else item {
            Text("Sin entrenamientos programados para $day",
                style = MaterialTheme.typography.bodyMedium)
        }
        items(todays, key = { "today:" + it.id }) { routine ->
            ScheduledRoutineCard(routine, busy, activeWorkout == null,
                onStart = { onStartRoutine(it); onNavigateHome() },
                onEdit = onEditRoutine, onDelete = onDeleteRoutine,
                onEditContent = onEditRoutineContent,
                onSetProgression = onSetRoutineProgression)
        }
        if (dated.isNotEmpty()) item {
            Text("Entrenamientos por fecha", style = MaterialTheme.typography.titleLarge)
        }
        items(dated, key = { "date:" + it.id }) { routine ->
            ScheduledRoutineCard(routine, busy, activeWorkout == null,
                onStart = { onStartRoutine(it); onNavigateHome() },
                onEdit = onEditRoutine, onDelete = onDeleteRoutine,
                onEditContent = onEditRoutineContent,
                onSetProgression = onSetRoutineProgression)
        }
        if (weekly.isNotEmpty()) item {
            Text("Programación semanal", style = MaterialTheme.typography.titleLarge)
        }
        items(weekly, key = { "week:" + it.id }) { routine ->
            ScheduledRoutineCard(routine, busy, activeWorkout == null,
                onStart = { onStartRoutine(it); onNavigateHome() },
                onEdit = onEditRoutine, onDelete = onDeleteRoutine,
                onEditContent = onEditRoutineContent,
                onSetProgression = onSetRoutineProgression)
        }
        if (library.isNotEmpty()) item {
            Text("Biblioteca sin fecha", style = MaterialTheme.typography.titleLarge)
        }
        items(library, key = { "library:" + it.id }) { routine ->
            ScheduledRoutineCard(routine, busy, activeWorkout == null,
                onStart = { onStartRoutine(it); onNavigateHome() },
                onEdit = onEditRoutine, onDelete = onDeleteRoutine,
                onEditContent = onEditRoutineContent,
                onSetProgression = onSetRoutineProgression)
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
}
