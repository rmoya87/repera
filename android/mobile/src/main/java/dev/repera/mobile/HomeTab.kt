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
internal fun HomeTab(
    displayName: String?,
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    todayHealth: TodayHealth?,
    onHealthConnect: () -> Unit,
    activeWorkout: ActiveWorkout?,
    wodTimer: WodTimerState?,
    onWodTimerAction: (String) -> Unit,
    onWodTimerTick: () -> Unit,
    onStartRoutine: (String) -> Unit,
    onWodScore: (Int?, Int?, Int?) -> Unit,
    onWodMovement: (Int, Int, Int, Double?) -> Unit,
    onCompleteWodBlock: () -> Unit,
    onReviseWodMovement: (String, Int, Double?) -> Unit,
    onDeleteWodMovement: (String) -> Unit,
    onLogSet: (Int, Double?, Double?, Boolean, String?, Int?, Int?) -> Unit,
    onReviseSet: (String, Int, Double?, String?, Int?, Int?) -> Unit,
    onDeleteSet: (String) -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit,
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    onNavigateCreate: () -> Unit,
    modifier: Modifier = Modifier
) {
    var homeDateIso by rememberSaveable { mutableStateOf(LocalDate.now().toString()) }
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Hola, " + (displayName ?: "Deportista"),
                style = MaterialTheme.typography.headlineMedium)
        }
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text("Actividad del día", style = MaterialTheme.typography.titleMedium)
                    Text("Pasos: " + (todayHealth?.steps?.toString() ?: "—"))
                    Text("Energía activa: " + (todayHealth?.activeKcal?.let {
                        "${it.toInt()} kcal"
                    } ?: "—"))
                    TextButton(
                        enabled = !busy,
                        onClick = onHealthConnect
                    ) { Text("Conectar o actualizar Salud") }
                }
            }
        }
        item {
            val day = LocalDate.parse(homeDateIso)
            val dayRoutines = overview?.routineEntries.orEmpty().filter {
                it.scheduledDate == day.toString() ||
                    (it.scheduledDate == null && it.weekday == day.dayOfWeek.value)
            }
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Calendario y entrenamientos",
                        style = MaterialTheme.typography.titleLarge)
                    WeekCalendarStrip(day) { homeDateIso = it.toString() }
                    Text("Entrenamientos · $day",
                        style = MaterialTheme.typography.titleMedium)
                    if (dayRoutines.isEmpty()) {
                        Text("Sin entrenamiento programado",
                            style = MaterialTheme.typography.bodyMedium)
                    } else dayRoutines.forEach { routine ->
                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(routine.title, style = MaterialTheme.typography.bodyLarge)
                            TextButton(onClick = {
                                onStartRoutine(routine.id)
                            }, enabled = !busy && activeWorkout == null && routine.supported) {
                                Text(if (routine.supported) "Iniciar entrenamiento"
                                    else "Formato no disponible")
                            }
                        }
                    }
                    Button(onClick = onNavigateCreate,
                        enabled = !busy,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = brandGreen, contentColor = Color.Black
                        )) { Text("Añadir nuevo entrenamiento") }
                }
            }
        }
        item {
            if (activeWorkout != null) {
                key(activeWorkout.id, activeWorkout.index, activeWorkout.completedSets) {
                    if (activeWorkout.wod != null) {
                        WodScoreCard(
                            active = activeWorkout,
                            busy = busy,
                            timer = wodTimer,
                            onTimerAction = onWodTimerAction,
                            onTimerTick = onWodTimerTick,
                            onSave = onWodScore,
                            onMovement = onWodMovement,
                            onCompleteBlock = onCompleteWodBlock,
                            onReviseMovement = onReviseWodMovement,
                            onDeleteMovement = onDeleteWodMovement,
                            onFinish = onFinish
                        )
                    } else {
                        ActiveWorkoutCard(
                            active = activeWorkout,
                            busy = busy,
                            onLogSet = onLogSet,
                            onReviseSet = onReviseSet,
                            onDeleteSet = onDeleteSet,
                            onNext = onNext,
                            onFinish = onFinish
                        )
                    }
                }
            } else {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(18.dp)) {
                        Text("Sesión activa", style = MaterialTheme.typography.titleMedium)
                        Text("Sin entrenamiento iniciado")
                    }
                }
            }
        }
        item { CountCard("Entrenamientos registrados", overview?.workouts, overview != null) }
        item { Text("Historial reciente", style = MaterialTheme.typography.titleMedium) }
        val workouts = overview?.history.orEmpty()
        if (workouts.isEmpty()) item { Text("Todavía no hay sesiones registradas") }
        items(workouts, key = { it.id }) { workout ->
            WorkoutHistoryCard(workout)
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
}
