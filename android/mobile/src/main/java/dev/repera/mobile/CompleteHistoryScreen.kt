package dev.repera.mobile
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.time.*
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

internal object CompleteHistoryOrder {
 data class Row(val local:WorkoutHistoryEntry?=null,val external:ExternalHealthHistoryEntry?=null) {
  val id:String get()=local?.let {"local-${it.id}"} ?: "health-${external!!.id}"
  val millis:Long get()=external?.startMillis ?: runCatching {Instant.parse(local!!.finishedAtIso ?: local.startedAtIso).toEpochMilli()}.getOrDefault(0L)
 }
 fun rows(local:List<WorkoutHistoryEntry>,external:List<ExternalHealthHistoryEntry>):List<Row> =
  (local.filter {it.finishedAtIso!=null}.map {Row(local=it)}+external.map {Row(external=it)}).sortedByDescending {it.millis}
}

@Composable
internal fun CompleteHistoryScreen(overview:StateOverview?,busy:Boolean,accountId:String,
 onRevise:(String,String,String,Int,Double?,Int?)->Unit,onDeleteSet:(String,String,String)->Unit,onDelete:(String)->Unit,
 onUpdate:(String,WorkoutRepository.FinishedWorkoutEdit,List<RoutineBlockDraft>?)->Unit,heartSeries:suspend(String)->List<Pair<Long,Int>>,
 externalProvider:suspend(ExternalHealthHistoryEntry)->ExternalHealthDetail? = {null},
 onOpenExercise:(String,String,String)->Unit,
 onOpenSports: () -> Unit = {},
 onBack: (() -> Unit)? = null,
 onToggleWorkoutFavorite: (String) -> Unit = {},
 isWorkoutFavorite: (String) -> Boolean = { false },
) {
 val rows=remember(overview) {CompleteHistoryOrder.rows(overview?.completeHistory.orEmpty(),overview?.externalHealthHistory.orEmpty())}
 var selectedWorkoutId by remember(accountId) { mutableStateOf<String?>(null) }
 var external by remember(accountId) {mutableStateOf<ExternalHealthHistoryEntry?>(null)}
 val selectedWorkout = selectedWorkoutId?.let { id ->
  overview?.completeHistory.orEmpty().firstOrNull { it.id == id }
 }
 var editingWorkoutId by remember(accountId) { mutableStateOf<String?>(null) }
 val cachedEditing = rememberCachedHistoryWorkout(editingWorkoutId.orEmpty(), overview)
 val editingWorkout = if (editingWorkoutId != null) cachedEditing else null
 if (editingWorkout != null) {
  BackHandler { editingWorkoutId = null }
  FinishedWorkoutEditorScreen(
   workout = editingWorkout,
   accountId = accountId,
   busy = busy,
   exerciseCatalog = overview?.exerciseEntries.orEmpty(),
   effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
   importableRoutines = overview?.routineEntries.orEmpty(),
   onBack = { editingWorkoutId = null },
   onSave = { edit, drafts ->
    onUpdate(editingWorkout.id, edit, drafts)
    editingWorkoutId = null
   }
  )
  return
 }
 if (selectedWorkout != null) {
  BackHandler { selectedWorkoutId = null }
  WorkoutHistoryDetailScreen(
   workout = selectedWorkout,
   busy = busy,
   accountId = accountId,
   exerciseCatalog = overview?.exerciseEntries.orEmpty(),
   effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
   onBack = { selectedWorkoutId = null },
   onRevise = onRevise,
   onDeleteSet = onDeleteSet,
   onDelete = {
    onDelete(it)
    selectedWorkoutId = null
   },
   onUpdate = onUpdate,
   onOpenExercise = onOpenExercise,
   heartSeries = heartSeries,
   onEditFinished = { editingWorkoutId = selectedWorkout.id },
   onToggleFavorite = { onToggleWorkoutFavorite(selectedWorkout.id) },
   isFavorite = isWorkoutFavorite(selectedWorkout.id)
  )
  return
 }
 LazyColumn(
  Modifier.fillMaxSize().testTag("complete_history"),
  contentPadding = reperaScrollContentPadding(),
  verticalArrangement = Arrangement.spacedBy(10.dp)
 ) {
  item {
   Row(verticalAlignment = Alignment.CenterVertically) {
    if (onBack != null) {
     ReperaToolbarGlassIconButton(
      icon = Icons.AutoMirrored.Outlined.ArrowBack,
      contentDescription = "Volver",
      onClick = onBack
     )
     Spacer(Modifier.width(8.dp))
    }
    ReperaPageHeader(title = "Historial")
   }
  }
  if (rows.isEmpty()) {
   item {
    ReperaEmptyState(
     title = "Sin entrenos",
     subtitle = "Los entrenos terminados aparecerán aquí."
    )
   }
  }
  items(rows.size) { i ->
   val row = rows[i]
   val workout = row.local
   val ext = row.external
   if (workout != null) {
    val mins = workout.displayDurationMinutes().takeIf { it > 0 }?.let { kotlin.math.round(it).toInt() }
    ReperaCard(
     onClick = { selectedWorkoutId = workout.id },
     modifier = Modifier.fillMaxWidth().testTag("history_row_${workout.id}")
    ) {
     Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
      Text(workout.title.ifBlank { "Entreno" }, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
      Text(
       listOfNotNull(
        workout.startedAt.takeIf { it.isNotBlank() },
        mins?.let { "$it′" }
       ).joinToString(" · "),
       style = MaterialTheme.typography.bodySmall,
       color = MaterialTheme.colorScheme.onSurfaceVariant
      )
     }
    }
   } else if (ext != null) {
    ReperaCard(
     onClick = { external = ext },
     modifier = Modifier.fillMaxWidth()
    ) {
     Column(Modifier.padding(16.dp)) {
      Text(ext.title, style = MaterialTheme.typography.titleMedium)
      Text("${ext.minutes.toInt()} min", style = MaterialTheme.typography.bodySmall)
     }
    }
   }
  }
 }
 external?.let {entry ->ExternalHealthDetailSheet(entry,externalProvider,ownerKey=accountId) {external=null}}
}

private val historyDayFmt: DateTimeFormatter =
 DateTimeFormatter.ofPattern("EEEE d MMMM", Locale("es", "ES"))
private val historyTimeFmt: DateTimeFormatter =
 DateTimeFormatter.ofPattern("H:mm")

/** Detalle a pantalla completa (paridad HistoryView → WorkoutDetailView iOS). */
@Composable
internal fun WorkoutHistoryDetailScreen(
 workout: WorkoutHistoryEntry,
 busy: Boolean,
 accountId: String,
 exerciseCatalog: List<ExerciseEntry>,
 effortUnit: String,
 onBack: () -> Unit,
 onRevise: (String, String, String, Int, Double?, Int?) -> Unit,
 onDeleteSet: (String, String, String) -> Unit,
 onDelete: (String) -> Unit,
 onUpdate: (String, WorkoutRepository.FinishedWorkoutEdit, List<RoutineBlockDraft>?) -> Unit,
 onOpenExercise: (String, String, String) -> Unit,
 heartSeries: suspend (String) -> List<Pair<Long, Int>>,
 onEditFinished: (() -> Unit)? = null,
 onToggleFavorite: (Boolean) -> Unit = {},
 isFavorite: Boolean = false,
) {
 val context = LocalContext.current
 val aliases = remember(context) { ExerciseSearchAssets.load(context) }
 var menuOpen by remember { mutableStateOf(false) }
 var confirmDelete by remember { mutableStateOf(false) }
 var favorite by remember(workout.id, isFavorite) { mutableStateOf(isFavorite) }

 val zone = ZoneId.systemDefault()
 val startZ = workout.startedAtIso?.let {
  runCatching { Instant.parse(it).atZone(zone) }.getOrNull()
 }
 val endZ = workout.finishedAtIso?.let {
  runCatching { Instant.parse(it).atZone(zone) }.getOrNull()
 }
 val subtitle = buildString {
  if (startZ != null) {
   append(startZ.format(historyDayFmt).replaceFirstChar {
    if (it.isLowerCase()) it.titlecase(Locale("es", "ES")) else it.toString()
   })
   append(" · ")
   append(startZ.format(historyTimeFmt))
   if (endZ != null) {
    append("–")
    append(endZ.format(historyTimeFmt))
   }
  } else if (workout.startedAt.isNotBlank()) {
   append(workout.startedAt)
  }
 }
 val navTitle = workout.title.ifBlank { "Entreno" }
 val mins = workout.displayDurationMinutes().takeIf { it > 0 }?.let { kotlin.math.round(it).toInt() }

 if (confirmDelete) {
  ReperaConfirmSheet(
   title = "¿Eliminar entreno?",
   message = "Se eliminará «${workout.title}» de este día.",
   confirmTitle = "Eliminar",
   onConfirm = { confirmDelete = false; onDelete(workout.id) },
   onCancel = { confirmDelete = false }
  )
 }

 LazyColumn(
  Modifier.fillMaxSize().testTag("workout_history_detail"),
  contentPadding = reperaScrollContentPadding(extraBottom = 16.dp),
  verticalArrangement = Arrangement.spacedBy(12.dp)
 ) {
  item {
   Row(
    Modifier.fillMaxWidth(),
    verticalAlignment = Alignment.CenterVertically
   ) {
    ReperaToolbarGlassIconButton(
     icon = Icons.AutoMirrored.Outlined.ArrowBack,
     contentDescription = "Volver",
     onClick = onBack,
     modifier = Modifier.testTag("workout_history_detail_back")
    )
    Spacer(Modifier.weight(1f))
    ReperaToolbarGlassIconButton(
     icon = if (favorite) Icons.Outlined.Star else Icons.Outlined.StarBorder,
     contentDescription = if (favorite) "Quitar de favoritos" else "Favorito",
     onClick = {
      favorite = !favorite
      onToggleFavorite(favorite)
     },
     enabled = !busy,
     active = favorite
    )
    Spacer(Modifier.width(4.dp))
    Box {
     ReperaToolbarGlassIconButton(
      icon = Icons.Outlined.MoreVert,
      contentDescription = "Más",
      onClick = { menuOpen = true }
     )
     DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
      if (onEditFinished != null) {
       DropdownMenuItem(
        text = { Text("Editar") },
        onClick = { menuOpen = false; onEditFinished() }
       )
      }
      DropdownMenuItem(
       text = { Text("Eliminar", color = MaterialTheme.colorScheme.error) },
       onClick = { menuOpen = false; confirmDelete = true }
      )
     }
    }
   }
  }
  // Título y fecha fuera del bloque de tiles (paridad iOS ogSessionDateListRow).
  item {
   Text(
    navTitle,
    style = MaterialTheme.typography.headlineSmall,
    fontWeight = FontWeight.Bold
   )
  }
  if (subtitle.isNotBlank()) {
   item {
    Text(
     subtitle,
     style = MaterialTheme.typography.bodyMedium,
     color = MaterialTheme.colorScheme.onSurfaceVariant,
     modifier = Modifier.padding(bottom = 2.dp)
    )
   }
  }
  item {
   val sport = workout.liveSportID?.let(dev.repera.domain.LiveSport::byId)
   val movementProvider = LocalSessionMovement.current
   val movement by produceState<dev.repera.domain.SessionMovement?>(null, workout.id) {
    value = runCatching { movementProvider(workout.id) }.getOrNull()
   }
   val volumeKg = remember(workout) {
    SessionSummaryTilesBuilder.volumeKgFromScoreSession(workout.scoreSessionJson)
   }
   val durationLabel = when {
    workout.timerDetails != null -> {
     val s = workout.timerDetails.configuredSeconds.coerceAtLeast(0)
     val h = s / 3600; val m = (s % 3600) / 60; val sec = s % 60
     if (h > 0) "%d:%02d:%02d".format(h, m, sec) else "%d:%02d".format(m, sec)
    }
    mins != null && mins > 0 -> "$mins′"
    else -> "—"
   }
   val activeSeconds = workout.activeDurationSeconds
    ?: mins?.takeIf { it > 0 }?.times(60.0)
   // Paridad iOS SessionSummaryTilesBuilder: kcal / FC / pasos reales.
   val specs = SessionSummaryTilesBuilder.tiles(
    durationLabel = durationLabel,
    sport = sport,
    kcal = workout.appleActiveEnergyKcal,
    steps = movement?.steps,
    averageHeartRateBpm = workout.appleAverageHeartRateBpm,
    distanceMeters = workout.recordedDistanceMeters
     ?: movement?.distanceMeters,
    paceOrSpeedLabel = SessionSummaryTilesBuilder.paceOrSpeedLabel(
     sport,
     workout.recordedDistanceMeters ?: movement?.distanceMeters,
     activeSeconds
    ),
    timerDetails = workout.timerDetails,
    volumeKg = volumeKg,
    scoreSessionJson = workout.scoreSessionJson,
    displayResults = workout.results,
    hasWodBlock = workout.movements.any { it.wod }
   )
   Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
    Row(
     Modifier.fillMaxWidth(),
     horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
     specs.forEach { spec ->
      WorkoutSummaryTile(
       title = spec.title,
       value = spec.value,
       icon = spec.icon,
       modifier = Modifier.weight(1f),
       iconTint = spec.tint
      )
     }
    }
    // Misma agrupación visual que iOS (tiles + review).
    workout.review?.let { SessionReviewCard(it) }
   }
  }
  // Métricas primero (sin título «Entreno»), como HistoryView iOS.
  // Solo card si hay algo que mostrar (evita el rectángulo vacío).
  item {
   val sport = workout.liveSportID?.let(dev.repera.domain.LiveSport::byId)
   val showGpsMetrics = sport?.usesGPS == true && (
    workout.routePoints.size >= 2
     || workout.liveKilometerSplitsSeconds.isNotEmpty()
     || ((workout.recordedDistanceMeters ?: 0.0) > 0
      && (workout.activeDurationSeconds ?: 0.0) > 0)
    )
   val showRouteGap = RouteUnavailable.applies(
    sport, workout.recordedDistanceMeters, workout.routePoints.size
   )
   // HeartRateCurveSection se auto-oculta sin series; el resto sí necesita gate.
   if (showGpsMetrics || workout.liveKilometerSplitsSeconds.isNotEmpty() || showRouteGap) {
    Column(
     Modifier
      .fillMaxWidth()
      .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(14.dp))
      .padding(14.dp),
     verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
     if (showGpsMetrics || workout.liveKilometerSplitsSeconds.isNotEmpty()) {
      SessionSportMetricRow(workout)
      LiveKilometerSplitsSection(
       workout.liveKilometerSplitsSeconds,
       sport?.displaysSpeed == true,
       workout.routePoints
      )
     }
     SessionMovementSection(workout.id)
     RouteUnavailableNotice(workout)
     HeartRateCurveSection(
      sessionId = workout.id,
      provider = heartSeries,
      sectionTitle = null
     )
    }
   } else {
    // Solo curva FC / pasos sin GPS: sin card vacía envolvente.
    SessionMovementSection(workout.id)
    HeartRateCurveSection(
     sessionId = workout.id,
     provider = heartSeries,
     sectionTitle = null
    )
   }
  }
  // GPS: mapa tras métricas (antes de ejercicios).
  val sportForMap = workout.liveSportID?.let(dev.repera.domain.LiveSport::byId)
  if (sportForMap?.usesGPS == true && workout.routePoints.size >= 2) {
   item {
    CardioRouteSection(
     workout.routePoints,
     showComputedSplits = workout.liveKilometerSplitsSeconds.isEmpty(),
     waterSport = sportForMap.isWaterSport,
     workoutEpochMs = workoutEpochMs(workout),
     liveSportId = workout.liveSportID,
     persistedConditions = workout.activityConditions
    )
   }
  }
  // Bloques / ejercicios con thumb (paridad iOS exerciseCard).
  val blockTitle = workout.results.firstOrNull()?.takeIf { it.isNotBlank() }
   ?: workout.title.takeIf { it.contains("EMOM", true) || it.contains("AMRAP", true) }
  if (workout.movements.isNotEmpty()) {
   item {
    if (!blockTitle.isNullOrBlank()) ReperaSectionTitle(blockTitle)
    ReperaInsetGroupedList {
     workout.movements.forEachIndexed { index, movement ->
      if (index > 0) {
       HorizontalDivider(
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
       )
      }
      val resolved = remember(movement.catalogExerciseId, movement.name, exerciseCatalog) {
       if (movement.catalogExerciseId.isNotBlank()) {
        exerciseCatalog.firstOrNull { it.id == movement.catalogExerciseId }
         ?: resolveWodExercise(movement.name, exerciseCatalog, aliases,
          exerciseId = movement.catalogExerciseId)
       } else resolveWodExercise(movement.name, exerciseCatalog, aliases)
      }
      Row(
       Modifier
        .fillMaxWidth()
        .clickable(enabled = movement.catalogExerciseId.isNotBlank() || movement.entryId.isNotBlank()) {
         val catalogId = movement.catalogExerciseId.ifBlank { movement.entryId }
         if (catalogId.isNotBlank()) {
          onOpenExercise(catalogId, workout.id, movement.entryId)
         }
        }
        .padding(horizontal = 14.dp, vertical = 12.dp),
       verticalAlignment = Alignment.CenterVertically,
       horizontalArrangement = Arrangement.spacedBy(12.dp)
      ) {
       WodExerciseThumbnail(resolved, aliases, size = 44.dp)
       Column(Modifier.weight(1f)) {
        Text(
         movement.name.ifBlank { "Ejercicio" },
         style = MaterialTheme.typography.titleMedium,
         fontWeight = FontWeight.SemiBold
        )
        val setLines = when {
         movement.editableSets.isNotEmpty() ->
          movement.editableSets.mapIndexed { i, s ->
           "S${i + 1} ${s.line}"
          }
         movement.registered.isNotEmpty() ->
          movement.registered.mapIndexed { i, line -> "S${i + 1} $line" }
         else -> emptyList()
        }
        if (setLines.isNotEmpty()) {
         Text(
          setLines.joinToString("  "),
          style = MaterialTheme.typography.bodySmall,
          color = MaterialTheme.colorScheme.onSurfaceVariant
         )
        }
       }
       Icon(
        Icons.AutoMirrored.Outlined.KeyboardArrowRight,
        contentDescription = null,
        tint = MaterialTheme.colorScheme.onSurfaceVariant
       )
      }
     }
    }
   }
  }
  if (!workout.notes.isNullOrBlank()) {
   item {
    ReperaSectionTitle("Notas")
    ReperaCard(Modifier.fillMaxWidth()) {
     Text(
      workout.notes.orEmpty(),
      style = MaterialTheme.typography.bodyMedium,
      modifier = Modifier.padding(16.dp)
     )
    }
   }
  }
  // No GPS: pin + clima al final (paridad iOS detailMapSections).
  if (sportForMap?.usesGPS != true) {
   val placeOnly = workout.locationPin?.takeIf { it.hasChosenPlace }
   if (placeOnly != null) {
    item {
     SessionMapWeatherCard(
      latitude = placeOnly.latitude,
      longitude = placeOnly.longitude,
      workoutEpochMs = workoutEpochMs(workout),
      placePin = placeOnly,
      modifier = Modifier.fillMaxWidth(),
      liveSportId = workout.liveSportID,
      persistedConditions = workout.activityConditions
     ) {
      PlacePinMap(
       placeOnly.latitude,
       placeOnly.longitude,
       isInteractive = false,
       modifier = Modifier
        .fillMaxWidth()
        .height(180.dp)
      )
     }
    }
   }
  }
 }
}
