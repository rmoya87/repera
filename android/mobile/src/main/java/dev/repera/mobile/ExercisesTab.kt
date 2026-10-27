package dev.repera.mobile

import dev.repera.domain.SessionSportMetrics
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
import androidx.compose.foundation.layout.size
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
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.SortByAlpha
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
import dev.repera.domain.ExerciseEquipmentGroup
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.selected
import androidx.compose.material3.CardDefaults
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
    onQuickLogOpened: () -> Unit = {},
    onSaveQuickSets:(String,List<QuickLogRow>,String?,String,()->Unit)->Unit = {_,_,_,_,_->},
    onOpenExercise: (String) -> Unit,
    onSetExerciseFavorite: (String, Boolean) -> Unit = { _, _ -> },
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    onNavigateHome: () -> Unit,
    modifier: Modifier = Modifier,
    accountId: String = "", onArchiveChanged: () -> Unit = {},
    onUpdateFinishedWorkout: (String, WorkoutRepository.FinishedWorkoutEdit) -> Unit = { _, _ -> },
    heartSeriesProvider: suspend (String) -> List<Pair<Long,Int>> = { emptyList() },
    exerciseSeries:(String,ExerciseProgressMetric,ExerciseProgressRange)->List<ExerciseProgressPoint> = {_,_,_->emptyList()},
    onSetTestedOneRM:(String,Double?)->Unit = {_,_->},
    wodFavorites:Set<String> = emptySet(),
    onToggleWodFavorite:(String)->Unit = {},
    onPlayWod:(String,String)->Unit = {_,_->},
    requestedLibraryMode:String? = null,
    onLibraryModeRequestConsumed:()->Unit = {}
) {
    var selectedExerciseId by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    var quickLogId by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    // Apple 11ea29a6: abrir «Apuntar» refresca alias del catalogo, sin polling.
    LaunchedEffect(quickLogId) { if (quickLogId != null) onQuickLogOpened() }
    val quickLog=quickLogId?.let {id ->overview?.exerciseEntries?.firstOrNull {it.id==id}}
    quickLog?.let {entry ->
        val quickContext=LocalContext.current
        val last=remember(entry.id,overview?.workouts,accountId) {runCatching {
            val root=org.json.JSONObject(String(LocalSnapshotStore(quickContext,accountId).read()!!))
            ExerciseLoadGuide.lastWorkingSession(entry.id,root.getJSONArray("workouts").let {a ->(0 until a.length()).map {a.getJSONObject(it)}},root.getJSONArray("exercises"))?.sets?.lastOrNull()
        }.getOrNull()}
        QuickLogSheet(entry,accountId,busy,last,{quickLogId=null}) {rows,notes,requestId ->onSaveQuickSets(entry.id,rows,notes,requestId) {quickLogId=null}}
    }
    var selectedLiveSessionID by rememberSaveable(accountId) { mutableStateOf<String?>(null) }
    var libraryMode by rememberSaveable { mutableStateOf("Ejercicios") }
    var selectedSportID by rememberSaveable(accountId) { mutableStateOf<String?>(null) }
    var sportSearch by rememberSaveable { mutableStateOf("") }
    // Entrada desde Progreso ("Deportes · evolución y récords", Apple StatsView): abre el catálogo de deportes una vez.
    LaunchedEffect(requestedLibraryMode) {
        requestedLibraryMode?.let {libraryMode=it;selectedSportID=null;onLibraryModeRequestConsumed()}
    }
    var exerciseSearch by rememberSaveable { mutableStateOf("") }
    var exerciseFilter by rememberSaveable { mutableStateOf("Todos") }
    // Ordenación de biblioteca por grupo (paridad ExerciseSortMode iOS):
    // por defecto alfabético; búsqueda siempre plana por relevancia.
    var exerciseSort by rememberSaveable { mutableStateOf("Alfabético") }
    val context = LocalContext.current
    var routeVersion by remember { mutableStateOf(0) }
    var routeError by remember { mutableStateOf<String?>(null) }
    val routeStore = remember(accountId) {
        if (accountId.isBlank()) null else runCatching { LiveRoutesStore(context, accountId) }.getOrNull()
    }
    var evolutionRouteID by rememberSaveable(accountId) { mutableStateOf<String?>(null) }
    val savedRoutes = remember(routeStore, routeVersion) { routeStore?.routes.orEmpty() }
    val englishAliases = remember(context) { ExerciseSearchAssets.load(context) }
    // LazyListScope is not @Composable: calculate the filtered list here,
    // where remember is legal, then hand the immutable result to LazyColumn.
    val filteredExerciseEntries = remember(exerciseSearch, exerciseFilter, overview?.exerciseEntries) {
        overview?.exerciseEntries.orEmpty()
            .asSequence()
            .filter { exerciseFilter != "Favoritos" || it.isFavorite }
            .filter { ExerciseCatalogFilters.matches(it, exerciseFilter) }
            .map { it to ExerciseAliasSearch.score(exerciseSearch, it.name, englishAliases, it.disciplineTags.joinToString(" "), it.searchAliases) }
            .filter { it.second >= 0 }
            .sortedWith(compareByDescending<Pair<ExerciseEntry, Int>> { it.second }
                .thenBy { it.first.name })
            .map { it.first }.toList()
    }
    // iOS: la búsqueda siempre es plana (relevancia); sin búsqueda, Músculo y
    // Material agrupan en secciones ordenadas con collator es_ES
    // (localizedStandardCompare). LazyListScope no es @Composable: se calcula aquí.
    val exerciseSections = remember(filteredExerciseEntries, exerciseSearch, exerciseSort) {
        if (exerciseSearch.isNotBlank() || exerciseSort == "Alfabético") null
        else filteredExerciseEntries.groupBy { entry ->
                if (exerciseSort == "Músculo") {
                    entry.muscleGroup.ifBlank { "Otros" }
                } else {
                    ExerciseEquipmentGroup.category(entry.name,
                        entry.equipment.ifBlank { null })
                }
            }.toList()
            .sortedWith { a, b -> LibraryCollator.compare(a.first, b.first) }
    }
    if(libraryMode=="WODs") {
        WodLibraryScreen(accountId,busy,wodFavorites,onToggleWodFavorite,{libraryMode="Ejercicios"},
            onPlay=onPlayWod,canPlay=overview!=null,hasActiveSession=activeWorkout!=null,activeRequestId=activeWorkout?.draftRequestId,history=overview?.wodLibraryHistory.orEmpty(),exercises=overview?.exerciseEntries.orEmpty(),onExercise=onOpenExercise,
            exerciseDetail={entry,close ->
                ExerciseDetailScreen(entry,testedOneRM=overview?.testedOneRMByExercise?.get(entry.id),
                    estimatedOneRM=overview?.exerciseProgress?.get(entry.id)?.estimatedOneRM,
                    incrementKg=overview?.trainingSettings?.weightIncrementKg ?: 2.5,
                    onSetTestedOneRM={onSetTestedOneRM(entry.id,it)},busy=busy,onQuickLog={quickLogId=entry.id},
                    onToggleFavorite={onSetExerciseFavorite(entry.id,!entry.isFavorite)},
                    exerciseSeries=exerciseSeries,onBack=close)
            })
        return
    }
    if (libraryMode == "Deportes") {
        val selected = selectedSportID?.let { dev.repera.domain.LiveSport.byId(it) }
        Column(modifier.fillMaxSize()) {
            val detail = overview?.completeHistory?.firstOrNull { it.id == selectedLiveSessionID }
            if (detail != null) {
                LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    item { TextButton(onClick = { selectedLiveSessionID = null }) { Text("Volver al deporte") } }
                    item {
                        Text(detail.title, style = MaterialTheme.typography.headlineMedium)
                        Text(detail.startedAt, style = MaterialTheme.typography.bodySmall)
                        overview?.liveSportSessions?.firstOrNull { it.id == detail.id }?.let { session ->
                            Text(dev.repera.domain.LiveSportHistory.formatDuration(session.activeDurationSeconds ?: 0.0))
                            session.recordedDistanceMeters?.takeIf { it > 0 }?.let { Text(dev.repera.domain.ReperaNumberFormat.decimal(it / 1000)+" km") }
                            session.averageHeartRateBpm?.takeIf { it > 0 }?.let { Text("Pulso medio medido: %.0f lpm".format(it)) }
                            session.activeEnergyKcal?.takeIf { it > 0 }?.let { Text("Energía activa medida: %.0f kcal".format(it)) }
                        }
                    }
                    item { SessionMovementSection(detail.id) }
                    item { SessionSportMetricRow(detail) }
                    item { RouteUnavailableNotice(detail) }
                    item { detail.review?.let { SessionReviewCard(it) } }
                    if (detail.routePoints.size >= 2) item { CardioRouteSection(detail.routePoints, showComputedSplits = detail.liveKilometerSplitsSeconds.isEmpty(),
                        waterSport = detail.liveSportID?.let(dev.repera.domain.LiveSport::byId)?.isWaterSport == true) }
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
                        FinishedWorkoutEditorSection(detail, accountId, busy, overview?.exerciseEntries.orEmpty()) { edit ->
                            onUpdateFinishedWorkout(detail.id, edit)
                        }
                    }
                }
            } else if (selected != null && evolutionRouteID != null && savedRoutes.any { it.id == evolutionRouteID }) {
                LiveRouteEvolutionScreen(savedRoutes.first { it.id == evolutionRouteID }, selected,
                    overview?.liveSportSessions.orEmpty(), onBack = { evolutionRouteID = null },
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
                            val session = overview!!.liveSportSessions.first { it.id == id }
                            val existing = savedRoutes.firstOrNull { it.id == session.liveRouteID }
                            if (existing != null) store.setFavorite(existing.id, true)
                            else {
                                val detail = overview.completeHistory.first { it.id == id }
                                val route = store.addRecordedRoute(detail.title, detail.routePoints, selected.id,
                                    true, session.startedEpochMillis ?: System.currentTimeMillis())
                                WorkoutRepository(context, accountId).setLiveRouteID(id, route.id)
                            }
                            routeVersion++;routeError = null;onArchiveChanged()
                        } catch (_: Exception) { routeError = "No se pudo guardar la ruta. Comprueba el almacenamiento e inténtalo de nuevo." }
                    })
            } else {
                TextButton(onClick = { libraryMode = "Ejercicios" }) { Text("Volver a Ejercicios") }
                OutlinedTextField(value = sportSearch, onValueChange = { sportSearch = it },
                    label = { Text("Buscar deporte") }, singleLine = true,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp))
                LiveSportsCatalogScreen(overview?.liveSportSessions.orEmpty(), sportSearch,
                    onOpenSport = { selectedSportID = it.id })
            }
        }
        return
    }
    val listContent: @Composable ((String)->Unit)->Unit = {openExercise ->
    ReadableColumn {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = groupedListContentPadding(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Ejercicios", style = MaterialTheme.typography.headlineLarge) }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(selected = true, onClick = {}, label = { Text("Ejercicios") })
                FilterChip(selected=false,onClick={libraryMode="WODs"},label={Text("WODs")})
                FilterChip(selected = false, onClick = { libraryMode = "Deportes" }, label = { Text("Deportes") })
            }
        }
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
                // Apple 5099d9f1/fdbd3558: iconos ExerciseCategorySymbols en chips.
                FilterChip(selected = exerciseFilter == "Favoritos",
                    onClick = { exerciseFilter = "Favoritos" },
                    leadingIcon = { Icon(Icons.Filled.Star, null, Modifier.size(16.dp)) },
                    label = { Text("Favoritos") })
                ExerciseCatalogFilters.available(overview?.exerciseEntries.orEmpty()).forEach { filter ->
                    val icon = when {
                        filter == "Todos" -> Icons.Filled.GridView        // square.grid.2x2
                        filter == "Cardio" -> Icons.Filled.Favorite       // heart
                        filter == "Hyrox" -> ExerciseCategorySymbols.discipline("HYROX")
                        else -> ExerciseCategorySymbols.discipline(filter)
                    }
                    FilterChip(selected = exerciseFilter == filter,
                        onClick = { exerciseFilter = filter },
                        leadingIcon = { Icon(icon, null, Modifier.size(16.dp)) },
                        label = { Text(filter) })
                }
            }
        }
        item {
            Row(modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf("Alfabético", "Músculo", "Material").forEach { mode ->
                    // Apple fdbd3558: a.circle / figure.stand / dumbbell.
                    val icon = when (mode) {
                        "Alfabético" -> Icons.Filled.SortByAlpha
                        "Músculo" -> ExerciseCategorySymbols.muscle
                        else -> ExerciseCategorySymbols.equipment
                    }
                    FilterChip(selected = exerciseSort == mode,
                        onClick = { exerciseSort = mode },
                        leadingIcon = { Icon(icon, null, Modifier.size(16.dp)) },
                        label = { Text("Orden: " + mode) })
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
        // iOS: la búsqueda siempre es plana (relevancia); sin búsqueda, los
        // modos Músculo/Material agrupan en secciones ordenadas con collator es.
        if (exerciseSections != null) {
            exerciseSections.forEach { (groupKey, groupEntries) ->
                item(key = "hdr-" + exerciseSort + "-" + groupKey) {
                    Text(groupKey, style = MaterialTheme.typography.titleSmall,
                        modifier = Modifier.padding(top = 4.dp))
                }
                items(groupEntries, key = { it.id }) { entry ->
        Card(modifier = Modifier.fillMaxWidth().testTag("library_exercise_${entry.id}")
            .semantics { selected = selectedExerciseId == entry.id }
            .clickable { openExercise(entry.id) },
            colors = CardDefaults.cardColors(containerColor = if (selectedExerciseId == entry.id)
                MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.surfaceVariant)) {
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
                    onClick = { quickLogId=entry.id },
                    enabled = !busy && entry.supportsBasicInput
                ) { Text(if (entry.supportsBasicInput) "Apuntar ejercicio" else "Registro avanzado pendiente") }
            }
        }
                }
            }
        } else {
        items(entries, key = { it.id }) { entry ->
Card(modifier = Modifier.fillMaxWidth().testTag("library_exercise_${entry.id}")
    .semantics { selected = selectedExerciseId == entry.id }
    .clickable { openExercise(entry.id) },
    colors = CardDefaults.cardColors(containerColor = if (selectedExerciseId == entry.id)
        MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.surfaceVariant)) {
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
            onClick = { quickLogId=entry.id },
            enabled = !busy && entry.supportsBasicInput
        ) { Text(if (entry.supportsBasicInput) "Apuntar ejercicio" else "Registro avanzado pendiente") }
    }
}
        }
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
    }
    }
    androidx.compose.foundation.layout.BoxWithConstraints(modifier.fillMaxSize()) {
        if(adaptiveCardColumns(maxWidth.value)==2) {
            Row(Modifier.fillMaxSize().testTag("library_split"),horizontalArrangement=Arrangement.spacedBy(12.dp)) {
                androidx.compose.foundation.layout.Box(Modifier.weight(1f).testTag("library_selector")) {listContent {selectedExerciseId=it}}
                androidx.compose.foundation.layout.Box(Modifier.weight(1f).testTag("library_detail")) {
                    val selected=overview?.exerciseEntries?.firstOrNull {it.id==selectedExerciseId}
                    if(selected==null) Column(Modifier.fillMaxWidth().padding(24.dp),
                        verticalArrangement=Arrangement.spacedBy(12.dp)) {
                        Text("Selecciona ejercicio",style=MaterialTheme.typography.titleLarge)
                        Text("Elige un ejercicio de la lista para ver sus datos, instrucciones y progreso.")
                    } else key(selected.id) {
                        ExerciseDetailScreen(selected,
                            testedOneRM=overview?.testedOneRMByExercise?.get(selected.id),
                            estimatedOneRM=overview?.exerciseProgress?.get(selected.id)?.estimatedOneRM,
                            incrementKg=overview?.trainingSettings?.weightIncrementKg ?: 2.5,
                            onSetTestedOneRM={onSetTestedOneRM(selected.id,it)},busy=busy,
                            onQuickLog={quickLogId=selected.id},exerciseSeries=exerciseSeries,
                            onToggleFavorite={onSetExerciseFavorite(selected.id,!selected.isFavorite)},
                            onBack={selectedExerciseId=null})
                    }
                }
            }
        } else listContent(onOpenExercise)
    }

}

/**
 * Comparador de secciones de biblioteca: equivalente a localizedStandardCompare
 * es_ES de iOS (ignora acentos a nivel primario/secundario, respeta el alfabeto
 * español).
 */
internal object LibraryCollator {
    private val es = java.text.Collator.getInstance(java.util.Locale("es", "ES"))
    fun compare(a: String, b: String): Int = es.compare(a, b)
}
