package dev.repera.mobile

import dev.repera.domain.SessionSportMetrics
import dev.repera.domain.StrengthReferenceFrame
import dev.repera.mobile.analytics.ReperaAnalytics
import dev.repera.mobile.monetization.LocalSubscriptions
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.Add
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
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.SortByAlpha
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.IconButton
import androidx.compose.ui.Alignment
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.produceState
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
    onUpdateFinishedWorkout: (
        String,
        WorkoutRepository.FinishedWorkoutEdit,
        List<RoutineBlockDraft>?
    ) -> Unit = { _, _, _ -> },
    heartSeriesProvider: suspend (String) -> List<Pair<Long,Int>> = { emptyList() },
    exerciseSummary:suspend (String)->dev.repera.domain.ExerciseHistorySummary? = { null },
    repRecords:suspend (String)->List<dev.repera.domain.StrengthRepRecord> = { emptyList() },
    exerciseSeries:suspend (String,ExerciseProgressMetric,ExerciseProgressRange)->List<ExerciseProgressPoint> = {_,_,_->emptyList()},
    onSetTestedOneRM:(String,Double?)->Unit = {_,_->},
    wodFavorites:Set<String> = emptySet(),
    onToggleWodFavorite:(String)->Unit = {},
    onPlayWod:(String,String)->Unit = {_,_->},
    requestedLibraryMode:String? = null,
    onLibraryModeRequestConsumed:()->Unit = {},
    onCreateExercise: () -> Unit = {}
) {
    var selectedExerciseId by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    var quickLogId by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    // Apple 11ea29a6: abrir «Apuntar» refresca alias del catalogo, sin polling.
    LaunchedEffect(quickLogId) { if (quickLogId != null) onQuickLogOpened() }
    val quickLog=quickLogId?.let {id ->overview?.exerciseEntries?.firstOrNull {it.id==id}}
    quickLog?.let {entry ->
        val quickContext=LocalContext.current
        val last by produceState<LoadGuideSet?>(null,entry.id,overview?.workouts,accountId) {
            value=kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {runCatching {
                val bytes=LocalSnapshotStore(quickContext,accountId).read() ?: return@runCatching null
                val root=org.json.JSONObject(String(bytes,Charsets.UTF_8))
                val workouts=root.optJSONArray("workouts") ?: return@runCatching null
                ExerciseLoadGuide.lastWorkingSession(entry.id,(0 until workouts.length()).mapNotNull {workouts.optJSONObject(it)},root.optJSONArray("exercises"))?.sets?.lastOrNull()
            }.getOrNull()}
        }
        QuickLogSheet(entry,accountId,busy,last,{quickLogId=null}) {rows,notes,requestId ->onSaveQuickSets(entry.id,rows,notes,requestId) {quickLogId=null}}
    }
    var libraryMode by rememberSaveable { mutableStateOf("Ejercicios") }
    // Entrada desde Progreso u otras rutas: solo WODs sigue viviendo en Ejercicios.
    LaunchedEffect(requestedLibraryMode) {
        requestedLibraryMode?.let { mode ->
            if (mode == "WODs") libraryMode = mode
            onLibraryModeRequestConsumed()
        }
    }
    var exerciseSearch by rememberSaveable { mutableStateOf("") }
    var exerciseFilter by rememberSaveable { mutableStateOf("Todos") }
    // Ordenación de biblioteca por grupo (paridad ExerciseSortMode iOS):
    // por defecto alfabético; búsqueda siempre plana por relevancia.
    var exerciseSort by rememberSaveable { mutableStateOf("Alfabético") }
    var showingExerciseFilters by rememberSaveable {mutableStateOf(false)}
    if(showingExerciseFilters) ExerciseFilterSheet(
        listOf("WODs") + listOf("Favoritos") +
            ExerciseCatalogFilters.available(overview?.exerciseEntries.orEmpty()),
        exerciseFilter,exerciseSort,
        onFilter = { value ->
            when (value) {
                "WODs" -> {
                    libraryMode = "WODs"
                    showingExerciseFilters = false
                }
                else -> exerciseFilter = value
            }
        },
        onSort = { exerciseSort = it },
        onClose = { showingExerciseFilters = false })
    val context = LocalContext.current
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
                    competitionSex=overview?.trainingSettings?.competitionSex,
                    birthYear=overview?.trainingSettings?.birthYear,
                    bodyWeightKg=overview?.bodyWeightHistory?.firstOrNull()?.kg,
                    strengthReferenceFrame=overview?.trainingSettings?.strengthReferenceFrame
                        ?: StrengthReferenceFrame.AMATEUR.wire,
                    onSetTestedOneRM={onSetTestedOneRM(entry.id,it)},busy=busy,onQuickLog={quickLogId=entry.id},
                    onToggleFavorite={onSetExerciseFavorite(entry.id,!entry.isFavorite)},
                    exerciseSummary=exerciseSummary,
                    repRecords=repRecords,
                    exerciseSeries=exerciseSeries,onBack=close)
            })
        return
    }
    val listContent: @Composable ((String)->Unit)->Unit = {openExercise ->
    ReadableColumn {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = reperaScrollContentPadding(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            ReperaPageHeader(
                title = "Ejercicios",
                trailing = {
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.Tune,
                        contentDescription = "Filtrar y ordenar",
                        onClick = { showingExerciseFilters = true },
                        modifier = Modifier.testTag("library_filter_button")
                    )
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.Add,
                        contentDescription = "Nuevo ejercicio",
                        onClick = onCreateExercise,
                        enabled = !busy,
                        modifier = Modifier.testTag("new_exercise_button")
                    )
                }
            )
        }
        item {
            ReperaSearchField(
                value = exerciseSearch,
                onValueChange = {
                    exerciseSearch = it
                    if (it.isNotBlank()) {
                        ReperaAnalytics.track(
                            ReperaAnalytics.Event.EXERCISE_SEARCH_USED,
                            mapOf("feature_area" to "exercises", "result" to "success")
                        )
                    }
                },
                placeholder = "Nombre, músculo o equipo"
            )
        }
        val entries = filteredExerciseEntries
        // R5 P2.4: iOS no muestra «N ejercicios» encima de la lista.
        if (exerciseFilter == "Hyrox") {
            item {
                Text(
                    "Movimientos útiles para Hyrox presentes en el catálogo; " +
                        "no equivale al listado oficial completo de estaciones.",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
        if (entries.isEmpty()) item {
            ReperaEmptyState(
                title = "Sin ejercicios coincidentes",
                subtitle = "Prueba otro filtro o busca por nombre"
            )
        }
        // iOS: una tarjeta agrupada con divisores (no cards sueltas por fila).
        // Búsqueda plana; sin búsqueda, Músculo/Material agrupan por sección.
        if (exerciseSections != null) {
            exerciseSections.forEach { (groupKey, groupEntries) ->
                item(key = "hdr-" + exerciseSort + "-" + groupKey) {
                    Text(groupKey, style = MaterialTheme.typography.titleSmall,
                        modifier = Modifier.padding(top = 4.dp))
                }
                item(key = "grp-" + exerciseSort + "-" + groupKey) {
                    ReperaCard(modifier = Modifier.fillMaxWidth()) {
                        Column {
                            groupEntries.forEachIndexed { index, entry ->
                                if (index > 0) {
                                    androidx.compose.material3.HorizontalDivider(
                                        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                                    )
                                }
                                ExerciseLibraryRow(
                                    entry = entry,
                                    aliases = englishAliases,
                                    selected = selectedExerciseId == entry.id,
                                    onClick = { openExercise(entry.id) }
                                )
                            }
                        }
                    }
                }
            }
        } else {
            // Un único bloque con líneas entre filas (paridad WOD/favoritos).
            item(key = "flat-list") {
                ReperaInsetGroupedList {
                    entries.forEachIndexed { index, entry ->
                        if (index > 0) {
                            HorizontalDivider(
                                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                            )
                        }
                        ExerciseLibraryRow(
                            entry = entry,
                            aliases = englishAliases,
                            selected = selectedExerciseId == entry.id,
                            onClick = { openExercise(entry.id) }
                        )
                    }
                }
            }
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
                            competitionSex=overview?.trainingSettings?.competitionSex,
                            birthYear=overview?.trainingSettings?.birthYear,
                            bodyWeightKg=overview?.bodyWeightHistory?.firstOrNull()?.kg,
                            strengthReferenceFrame=overview?.trainingSettings?.strengthReferenceFrame
                                ?: StrengthReferenceFrame.AMATEUR.wire,
                            onSetTestedOneRM={onSetTestedOneRM(selected.id,it)},busy=busy,
                            onQuickLog={quickLogId=selected.id},exerciseSummary=exerciseSummary,repRecords=repRecords,exerciseSeries=exerciseSeries,
                            onToggleFavorite={onSetExerciseFavorite(selected.id,!selected.isFavorite)},
                            onBack={selectedExerciseId=null})
                    }
                }
            }
        } else listContent(onOpenExercise)
    }

}

@Composable
private fun ExerciseLibraryRow(
    entry: ExerciseEntry,
    aliases: Map<String, String>,
    selected: Boolean,
    onClick: () -> Unit,
) {
    LibraryExerciseListRow(
        title = entry.displayName,
        subtitle = libraryExerciseSubtitle(entry),
        name = entry.name,
        sportTag = entry.sportTag,
        aliases = aliases,
        selected = selected,
        onClick = onClick,
        modifier = Modifier
            .testTag("library_exercise_${entry.id}")
            .semantics { this.selected = selected }
    )
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
