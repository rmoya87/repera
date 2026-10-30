package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate

private val favoriteEditBlue = Color(0xFF007AFF)

/**
 * Hub de favoritos del menú «＋» de día (port de FavoritesHubView iOS):
 * entrenos, actividades Comenzar y temporizadores habituales.
 * Con [targetDate] el tap copia al día (assignRoutine) sin iniciar sesión.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun FavoritesHubScreen(
    overview: StateOverview?,
    busy: Boolean,
    activeWorkout: ActiveWorkout?,
    onStartRoutine: (String) -> Unit,
    onOpenTimer: (String?) -> Unit,
    onBack: () -> Unit,
    targetDate: LocalDate? = null,
    onAssignRoutineToDate: (String, LocalDate) -> Unit = { _, _ -> },
    onCreateFavoriteWorkout: () -> Unit = {},
    onEditFavoriteWorkout: (String) -> Unit = {},
    onRemoveFavoriteWorkout: (String) -> Unit = {},
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
    var pendingDeleteId by remember { mutableStateOf<String?>(null) }
    var pendingDeleteTitle by remember { mutableStateOf("") }

    if (pendingDeleteId != null) {
        ReperaConfirmSheet(
            title = "¿Eliminar favorito?",
            message = "Se quitará «$pendingDeleteTitle» de Favoritos. La plantilla no se borra del historial.",
            confirmTitle = "Eliminar",
            onConfirm = {
                val id = pendingDeleteId
                pendingDeleteId = null
                if (id != null) onRemoveFavoriteWorkout(id)
            },
            onCancel = { pendingDeleteId = null }
        )
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize().testTag("favorites_hub"),
        contentPadding = reperaScrollContentPadding(extraBottom = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Column {
                ReperaToolbarGlassIconButton(
                    icon = Icons.AutoMirrored.Outlined.ArrowBack,
                    contentDescription = "Volver",
                    onClick = onBack
                )
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
        }
        items(favorites, key = { "favhub:" + it.id }) { routine ->
            FavoriteSwipeCard(
                enabled = !busy,
                onEdit = { onEditFavoriteWorkout(routine.id) },
                onDeleteReveal = {
                    pendingDeleteTitle = routine.title
                    pendingDeleteId = routine.id
                },
                onClick = {
                    if (targetDate != null) onAssignRoutineToDate(routine.id, targetDate)
                    else if (activeWorkout == null) onStartRoutine(routine.id)
                }
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            Modifier
                                .size(44.dp)
                                .background(brandGreen.copy(alpha = 0.14f), CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Outlined.Star,
                                contentDescription = null,
                                tint = brandGreen,
                                modifier = Modifier.size(22.dp)
                            )
                        }
                        Column(Modifier.weight(1f)) {
                            Text(
                                routine.title,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                buildString {
                                    val n = routine.blocks.size
                                    append(if (n == 1) "1 bloque" else "$n bloques")
                                    append(" · ")
                                    append(
                                        if (targetDate != null) "Añadir al día"
                                        else "Empezar"
                                    )
                                },
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    if (targetDate == null) {
                        Text(
                            "Programado",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            modifier = Modifier.horizontalScroll(rememberScrollState())
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
                    Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                        Text(timer.title, style = MaterialTheme.typography.titleMedium)
                        Text(
                            timer.config.shortLabel,
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
        item {
            FavoriteCreateRow(
                icon = Icons.Outlined.Star,
                title = "Crear entreno favorito",
                subtitle = "Plantilla reutilizable desde Añadir entreno",
                enabled = !busy,
                testTag = "fav_create_workout",
                onClick = onCreateFavoriteWorkout
            )
        }
        item {
            FavoriteCreateRow(
                icon = Icons.Outlined.Timer,
                title = "Crear temporizador favorito",
                subtitle = "Configura y guarda con «Guardar en favoritos»",
                enabled = !busy,
                testTag = "fav_create_timer",
                onClick = { onOpenTimer(null) }
            )
        }
    }
}

@Composable
private fun FavoriteCreateRow(
    icon: ImageVector,
    title: String,
    subtitle: String,
    enabled: Boolean,
    testTag: String,
    onClick: () -> Unit
) {
    ReperaCard(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = enabled, onClick = onClick)
            .testTag(testTag)
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.size(28.dp)
            )
            Column(Modifier.weight(1f)) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Swipe L→R: círculo azul + lápiz (editar).
 * Swipe R→L: círculo rojo + basura; al pulsar confirma borrado.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FavoriteSwipeCard(
    enabled: Boolean,
    onEdit: () -> Unit,
    onDeleteReveal: () -> Unit,
    onClick: () -> Unit,
    content: @Composable () -> Unit
) {
    val state = rememberSwipeToDismissBoxState(confirmValueChange = { true })
    SwipeToDismissBox(
        state = state,
        enableDismissFromStartToEnd = enabled,
        enableDismissFromEndToStart = enabled,
        backgroundContent = {
            val dir = state.dismissDirection
            Box(
                Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                contentAlignment = when (dir) {
                    SwipeToDismissBoxValue.StartToEnd -> Alignment.CenterStart
                    SwipeToDismissBoxValue.EndToStart -> Alignment.CenterEnd
                    else -> Alignment.CenterEnd
                }
            ) {
                when (dir) {
                    SwipeToDismissBoxValue.StartToEnd -> {
                        Surface(
                            onClick = onEdit,
                            shape = CircleShape,
                            color = favoriteEditBlue,
                            modifier = Modifier
                                .size(48.dp)
                                .testTag("fav_edit_action")
                        ) {
                            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                Icon(
                                    Icons.Outlined.Edit,
                                    contentDescription = "Editar",
                                    tint = Color.White
                                )
                            }
                        }
                    }
                    SwipeToDismissBoxValue.EndToStart -> {
                        Surface(
                            onClick = onDeleteReveal,
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.error,
                            modifier = Modifier
                                .size(48.dp)
                                .testTag("fav_delete_action")
                        ) {
                            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                Icon(
                                    Icons.Outlined.Delete,
                                    contentDescription = "Eliminar",
                                    tint = Color.White
                                )
                            }
                        }
                    }
                    else -> Spacer(Modifier.size(48.dp))
                }
            }
        }
    ) {
        ReperaCard(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(enabled = enabled, onClick = onClick)
        ) {
            content()
        }
    }
}
