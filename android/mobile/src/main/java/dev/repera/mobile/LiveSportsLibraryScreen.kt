package dev.repera.mobile

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import dev.repera.domain.SessionSportMetrics
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp


@Composable
internal fun LiveSportsLibraryScreen(
    overview: StateOverview?,
    accountId: String,
    busy: Boolean,
    heartSeriesProvider: suspend (String) -> List<Pair<Long, Int>>,
    onUpdateFinishedWorkout: (
        String,
        WorkoutRepository.FinishedWorkoutEdit,
        List<RoutineBlockDraft>?
    ) -> Unit,
    onArchiveChanged: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var selectedLiveSessionID by rememberSaveable(accountId) { mutableStateOf<String?>(null) }
    var selectedSportID by rememberSaveable(accountId) { mutableStateOf<String?>(null) }
    var sportSearch by rememberSaveable { mutableStateOf("") }
    var evolutionRouteID by rememberSaveable(accountId) { mutableStateOf<String?>(null) }
    var editingLiveSession by rememberSaveable(accountId) { mutableStateOf(false) }
    var routeVersion by remember { mutableStateOf(0) }
    var routeError by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    val routeStore = remember(accountId) {
        if (accountId.isBlank()) null else runCatching { LiveRoutesStore(context, accountId) }.getOrNull()
    }
    val savedRoutes = remember(routeStore, routeVersion) { routeStore?.routes.orEmpty() }

    val selected = selectedSportID?.let { dev.repera.domain.LiveSport.byId(it) }
    BackHandler {
        when {
            selectedLiveSessionID != null -> selectedLiveSessionID = null
            evolutionRouteID != null -> evolutionRouteID = null
            selectedSportID != null -> selectedSportID = null
            else -> onBack()
        }
    }
    Column(modifier.fillMaxSize()) {
        val liveOverview = overview
        val detail = liveOverview?.completeHistory?.firstOrNull { it.id == selectedLiveSessionID }
        if (liveOverview != null && detail != null && editingLiveSession) {
            FinishedWorkoutEditorScreen(
                workout = detail,
                accountId = accountId,
                busy = busy,
                exerciseCatalog = liveOverview.exerciseEntries,
                effortUnit = liveOverview.trainingSettings.effortUnit,
                importableRoutines = liveOverview.routineEntries,
                onBack = { editingLiveSession = false },
                onSave = { edit, drafts ->
                    onUpdateFinishedWorkout(detail.id, edit, drafts)
                    editingLiveSession = false
                }
            )
        } else if (liveOverview != null && detail != null) {
            val dragListState = androidx.compose.foundation.lazy.rememberLazyListState()
            ProvideLazyDragAutoScroll(dragListState) {
            LazyColumn(state = dragListState, contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                item { TextButton(onClick = { selectedLiveSessionID = null }) { Text("Volver al deporte") } }
                item {
                    Text(detail.title, style = MaterialTheme.typography.headlineMedium)
                    Text(detail.startedAt, style = MaterialTheme.typography.bodySmall)
                    liveOverview.liveSportSessions.firstOrNull { it.id == detail.id }?.let { session ->
                        Text(dev.repera.domain.LiveSportHistory.formatDuration(session.activeDurationSeconds ?: 0.0))
                        session.recordedDistanceMeters?.takeIf { it > 0 }?.let { Text(dev.repera.domain.ReperaNumberFormat.decimal(it / 1000)+" km") }
                        session.averageHeartRateBpm?.takeIf { it > 0 }?.let { Text("Pulso medio medido: %.0f lpm".format(dev.repera.domain.ReperaNumberFormat.displayLocale, it)) }
                        session.activeEnergyKcal?.takeIf { it > 0 }?.let { Text("Energía activa medida: %.0f kcal".format(dev.repera.domain.ReperaNumberFormat.displayLocale, it)) }
                    }
                }
                item { SessionMovementSection(detail.id) }
                item { SessionSportMetricRow(detail) }
                item { RouteUnavailableNotice(detail) }
                item { detail.review?.let { SessionReviewCard(it) } }
                if (detail.routePoints.size >= 2) item {
                    CardioRouteSection(
                        detail.routePoints,
                        showComputedSplits = detail.liveKilometerSplitsSeconds.isEmpty(),
                        waterSport = detail.liveSportID?.let(dev.repera.domain.LiveSport::byId)?.isWaterSport == true,
                        workoutEpochMs = workoutEpochMs(detail),
                        liveSportId = detail.liveSportID,
                        persistedConditions = detail.activityConditions
                    )
                }
                item {
                    val heart by androidx.compose.runtime.produceState<List<Pair<Long,Int>>>(emptyList(),detail.id) {
                        value=runCatching { heartSeriesProvider(detail.id) }.getOrDefault(emptyList())
                    }
                    HeartRateCurveSection(detail.id,heartSeriesProvider)
                    SessionRangeTiles("Frecuencia cardiaca",SessionSportMetrics.heartRange(heart.map {it.second}),"lpm",heart=true)
                    if (detail.routePoints.size >= 2) SessionRangeTiles("Altitud",SessionSportMetrics.altitudeRange(detail.routePoints),"m")
                    LiveKilometerSplitsSection(detail.liveKilometerSplitsSeconds,
                        detail.liveSportID?.let(dev.repera.domain.LiveSport::byId)?.displaysSpeed == true,
                        detail.routePoints,heart)
                }
                item {
                    FinishedWorkoutEditorSection(
                        workout = detail,
                        accountId = accountId,
                        busy = busy,
                        exerciseCatalog = liveOverview.exerciseEntries,
                        effortUnit = liveOverview.trainingSettings.effortUnit,
                        onOpenFullEditor = { editingLiveSession = true },
                        onSave = { edit -> onUpdateFinishedWorkout(detail.id, edit, null) }
                    )
                }
            }
            }
        } else if (selected != null && evolutionRouteID != null && savedRoutes.any { it.id == evolutionRouteID }) {
            LiveRouteEvolutionScreen(savedRoutes.first { it.id == evolutionRouteID }, selected,
                liveOverview?.liveSportSessions.orEmpty(), onBack = { evolutionRouteID = null },
                onOpenSession = { selectedLiveSessionID = it })
        } else if (selected != null) {
            routeError?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            LiveSportHistoryScreen(selected, overview?.liveSportSessions.orEmpty(),
                onBack = { selectedSportID = null },
                onOpenSession = { selectedLiveSessionID = it },
                favoriteRoutes = savedRoutes.filter { r -> r.isFavorite &&
                    (r.sportID == selected.id || overview?.liveSportSessions.orEmpty().any { it.sportID == selected.id && it.liveRouteID == r.id }) },
                canSaveRoute = { id -> routeStore != null &&
                    overview?.completeHistory?.firstOrNull { it.id == id }?.routePoints.orEmpty().size >= 2 &&
                    savedRoutes.none { r -> r.isFavorite && overview?.liveSportSessions.orEmpty().any { it.id == id && it.liveRouteID == r.id } } },
                onOpenRoute = { evolutionRouteID = it.id },
                onSaveRoute = { id ->
                    try {
                        val store = routeStore ?: error("Almacén no disponible")
                        val current = overview ?: error("Historial no disponible")
                        val session = current.liveSportSessions.firstOrNull { it.id == id }
                            ?: error("Sesión no encontrada")
                        val existing = savedRoutes.firstOrNull { it.id == session.liveRouteID }
                        if (existing != null) store.setFavorite(existing.id, true)
                        else {
                            val detail = current.completeHistory.firstOrNull { it.id == id }
                                ?: error("Sesión no encontrada")
                            val route = store.addRecordedRoute(detail.title, detail.routePoints, selected.id,
                                true, session.startedEpochMillis ?: System.currentTimeMillis())
                            WorkoutRepository(context, accountId).setLiveRouteID(id, route.id)
                        }
                        routeVersion++;routeError = null;onArchiveChanged()
                    } catch (_: Exception) { routeError = "No se pudo guardar la ruta. Comprueba el almacenamiento e inténtalo de nuevo." }
                })
        } else {
            TextButton(onClick = onBack) { Text("Volver") }
            ReperaSearchField(
                value = sportSearch,
                onValueChange = { sportSearch = it },
                placeholder = "Buscar deporte",
                modifier = Modifier.padding(horizontal = 16.dp)
            )
            LiveSportsCatalogScreen(overview?.liveSportSessions.orEmpty(), sportSearch,
                onOpenSport = { selectedSportID = it.id })
        }
    }
}
