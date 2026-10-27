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
import androidx.compose.ui.platform.testTag
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.delay


@Composable
internal fun CreateTab(
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    onCreateRoutine: (String, String, List<RoutineDraftEntry>, Int, Int,
        RoutineSchedule, Int, Int, Int, List<Int>?) -> Unit,
    onAddWodTemplate: (String) -> Unit,
    onOpenBoardScan: () -> Unit,
    onOpenTimer: () -> Unit,
    onOpenFreeWorkout: () -> Unit = {},
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val subscriptions = LocalSubscriptions.current
    val englishAliases = remember(context) { ExerciseSearchAssets.load(context) }
    ReadableColumn {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Crear", style = MaterialTheme.typography.headlineMedium) }
        item {
            OutlinedButton(onClick = onOpenFreeWorkout, enabled = !busy,
                modifier = Modifier.fillMaxWidth().testTag("create_free_workout")) { Text("Crear entreno") }
        }
        if (overview != null) {
            item {
                RoutineCreatorCard(
                    exercises = overview.exerciseEntries,
                    aliases = englishAliases,
                    busy = busy,
                    onSave = onSave@{ title, format, entries, minutes, rounds, schedule, interval, work, rest, ladder ->
                        // Gate de límite Gratis de rutinas (paridad iOS:
                        // canCreateLibraryRoutine(isNew: true)). Las rutinas
                        // nuevas cuentan contra el límite; editar no pasa por aquí.
                        if (schedule.scheduledDate==null && subscriptions != null &&
                            !subscriptions.canCreateLibraryRoutine(isNew = true).allowed
                        ) {
                            subscriptions.presentPaywall(
                                dev.repera.domain.monetization.PaywallContext.ROUTINES_LIMIT,
                                feature = dev.repera.domain.monetization.ReperaFeature.UNLIMITED_ROUTINES
                            )
                            return@onSave
                        }
                        onCreateRoutine(title, format, entries, minutes, rounds,
                            schedule, interval, work, rest, ladder)
                    }
                )
            }
        }
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Temporizador", style = MaterialTheme.typography.titleMedium)
                    Text("Cronómetro, cuenta atrás o intervalos con reloj LED " +
                        "a pantalla completa. Guarda tus configuraciones favoritas.")
                    OutlinedButton(onClick = onOpenTimer,
                        modifier = Modifier.fillMaxWidth()) {
                        Text("Abrir temporizador")
                    }
                }
            }
        }
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Importar pizarra", style = MaterialTheme.typography.titleMedium)
                    Text("Fotografía la pizarra del box y Repera crea la rutina por ti.")
                    OutlinedButton(onClick = onOpenBoardScan,
                        enabled = !busy && overview != null,
                        modifier = Modifier.fillMaxWidth()) {
                        Text("Escanear pizarra")
                    }
                }
            }
        }
        item {
            BenchmarkWodPicker(busy = busy, enabled = overview != null,
                onAdd = onAddWodTemplate)
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
    }
}
