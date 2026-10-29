package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate

/**
 * Hub de favoritos del menú «＋» de día (port de FavoritesHubView iOS):
 * entrenos, actividades Comenzar y temporizadores habituales.
 * Con [targetDate] el tap copia al día (assignRoutine) sin iniciar sesión.
 */
@Composable
internal fun FavoritesHubScreen(
    overview: StateOverview?,
    busy: Boolean,
    activeWorkout: ActiveWorkout?,
    onStartRoutine: (String) -> Unit,
    onOpenTimer: (String?) -> Unit,
    onBack: () -> Unit,
    /** Día ISO desde DayPlus: tap = copiar al día (no empezar). */
    targetDate: LocalDate? = null,
    onAssignRoutineToDate: (String, LocalDate) -> Unit = { _, _ -> },
    onCreateFavoriteWorkout: () -> Unit = {},
    onEditFavoriteWorkout: (String) -> Unit = {},
    onRemoveFavoriteWorkout: (String) -> Unit = {},
    /** «También en Programado» (DayEditorView modo favorito): día de la semana opcional del favorito. */
    onSetWeekday: (routine: RoutineEntry, weekday: Int?) -> Unit = { _, _ -> },
    onOpenSport: (sportID: String) -> Unit = {},
    onRemoveSportFavorite: (id: String) -> Unit = {}
) {
    val context = LocalContext.current
    val timerStore = remember { StandaloneTimerStore(context) }
    var favoriteTimers by remember { mutableStateOf(timerStore.favorites()) }
    val favorites = overview?.routineEntries.orEmpty().filter { it.isFavorite }
    val sportFavorites = overview?.favoriteSportActivities.orEmpty()
        .takeIf { targetDate == null }.orEmpty()
    LazyColumn(
        modifier = Modifier.fillMaxSize().testTag("favorites_hub"),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Column {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Volver")
                }
                ReperaPageHeader(title = "Favoritos")
            }
        }
        if (favorites.isEmpty() && favoriteTimers.isEmpty() && sportFavorites.isEmpty()) {
            item {
                ReperaEmptyState(
                    title = "Sin favoritos",
                    subtitle = "Marca entrenos, actividades o temporizadores como favoritos para tenerlos aquí."
                )
            }
        }
        if (favorites.isNotEmpty()) {
            item { ReperaSectionTitle("Entrenos") }
            if (targetDate != null) {
                item {
                    Text(
                        "Selecciona un favorito para añadir una copia al día elegido sin cambiar la plantilla original.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        items(favorites, key = { "favhub:" + it.id }) { routine ->
            ReperaCard(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = !busy && (targetDate != null || activeWorkout == null)) {
                        if (targetDate != null) {
                            onAssignRoutineToDate(routine.id, targetDate)
                        } else {
                            onStartRoutine(routine.id)
                        }
                    }
            ) {
                Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                    Text(routine.title, style = MaterialTheme.typography.titleMedium)
                    Text(
                        if (targetDate != null) "Toca para añadir al día"
                        else "Toca para empezar",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    if (targetDate == null) {
                        Text(
                            "También en Programado",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            modifier = Modifier.horizontalScroll(
                                androidx.compose.foundation.rememberScrollState()
                            )
                        ) {
                            ReperaFilterChip(
                                selected = routine.weekday == null && routine.scheduledDate == null,
                                enabled = !busy,
                                modifier = Modifier.testTag("fav_weekday_none_" + routine.id),
                                onClick = { onSetWeekday(routine, null) },
                                label = { Text("Solo favorito") }
                            )
                            listOf("L", "M", "X", "J", "V", "S", "D").forEachIndexed { i, d ->
                                ReperaFilterChip(
                                    selected = routine.weekday == i + 1,
                                    enabled = !busy,
                                    modifier = Modifier.testTag(
                                        "fav_weekday_" + (i + 1) + "_" + routine.id
                                    ),
                                    onClick = { onSetWeekday(routine, i + 1) },
                                    label = { Text(d) }
                                )
                            }
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        TextButton(
                            onClick = { onEditFavoriteWorkout(routine.id) },
                            enabled = !busy,
                            modifier = Modifier.testTag("fav_edit_" + routine.id)
                        ) { Text("Editar") }
                        TextButton(
                            onClick = { onRemoveFavoriteWorkout(routine.id) },
                            enabled = !busy,
                            modifier = Modifier.testTag("fav_delete_" + routine.id)
                        ) { Text("Eliminar") }
                    }
                }
            }
        }
        if (sportFavorites.isNotEmpty()) {
            item { ReperaSectionTitle("Actividades") }
            items(sportFavorites, key = { "favsport:" + it.id }) { activity ->
                ReperaCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(enabled = !busy) { onOpenSport(activity.sportID) }
                        .testTag("fav_sport_" + activity.id)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(activity.title, style = MaterialTheme.typography.titleMedium)
                            Text(
                                "Iniciar otra actividad del mismo tipo",
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        TextButton(onClick = { onRemoveSportFavorite(activity.id) }) {
                            Text("Eliminar")
                        }
                    }
                }
            }
        }
        if (favoriteTimers.isNotEmpty()) {
            item { ReperaSectionTitle("Temporizadores") }
            items(favoriteTimers, key = { "favtimer:" + it.id }) { timer ->
                ReperaCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(enabled = !busy) { onOpenTimer(timer.id) }
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(timer.title, style = MaterialTheme.typography.titleMedium)
                            Text(
                                timer.config.shortLabel,
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        TextButton(onClick = {
                            timerStore.delete(timer.id)
                            favoriteTimers = timerStore.favorites()
                        }) { Text("Eliminar") }
                    }
                }
            }
        }
        item {
            TextButton(
                onClick = onCreateFavoriteWorkout,
                enabled = !busy,
                modifier = Modifier.testTag("fav_create_workout")
            ) { Text("Crear entreno favorito") }
        }
        item {
            TextButton(onClick = { onOpenTimer(null) }, enabled = !busy) {
                Text("Crear temporizador favorito")
            }
        }
    }
}
