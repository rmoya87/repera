package dev.repera.mobile
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
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
 onUpdate:(String,WorkoutRepository.FinishedWorkoutEdit)->Unit,heartSeries:suspend(String)->List<Pair<Long,Int>>,
 externalProvider:suspend(ExternalHealthHistoryEntry)->ExternalHealthDetail? = {null},
 onOpenExercise:(String,String,String)->Unit,
 onOpenSports: () -> Unit = {},
 onBack: (() -> Unit)? = null) {
 val rows=remember(overview) {CompleteHistoryOrder.rows(overview?.completeHistory.orEmpty(),overview?.externalHealthHistory.orEmpty())}
 var selectedWorkoutId by remember(accountId) { mutableStateOf<String?>(null) }
 var external by remember(accountId) {mutableStateOf<ExternalHealthHistoryEntry?>(null)}
 val selectedWorkout = selectedWorkoutId?.let { id ->
  overview?.completeHistory.orEmpty().firstOrNull { it.id == id }
 }
 var editingWorkoutId by remember(accountId) { mutableStateOf<String?>(null) }
 val editingWorkout = editingWorkoutId?.let { id ->
  overview?.completeHistory.orEmpty().firstOrNull { it.id == id }
 }
 if (editingWorkout != null) {
  BackHandler { editingWorkoutId = null }
  FinishedWorkoutEditorScreen(
   workout = editingWorkout,
   accountId = accountId,
   busy = busy,
   exerciseCatalog = overview?.exerciseEntries.orEmpty(),
   effortUnit = overview?.trainingSettings?.effortUnit ?: "rir",
   onBack = { editingWorkoutId = null },
   onSave = { edit ->
    onUpdate(editingWorkout.id, edit)
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
   onToggleFavorite = { fav ->
    onUpdate(
     selectedWorkout.id,
     WorkoutRepository.FinishedWorkoutEdit(
      title = selectedWorkout.title,
      startedAtIso = selectedWorkout.startedAtIso,
      finishedAtIso = selectedWorkout.finishedAtIso,
      notes = selectedWorkout.notes,
      pinEdited = false,
      pin = selectedWorkout.locationPin,
      saveAsFavorite = fav
     )
    )
   }
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
 onUpdate: (String, WorkoutRepository.FinishedWorkoutEdit) -> Unit,
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
 val volumeLabel = remember(workout) {
  val fromLines = workout.movements.flatMap { m ->
   m.registered + m.editableSets.map { it.line }
  }
  val kg = fromLines.mapNotNull { line ->
   Regex("""([\d.,]+)\s*kg""", RegexOption.IGNORE_CASE).find(line)
    ?.groupValues?.getOrNull(1)
    ?.let { dev.repera.domain.ReperaNumberFormat.parse(it) }
  }.sum()
  when {
   kg >= 1000 -> "${dev.repera.domain.ReperaNumberFormat.decimal(kg / 1000)} t"
   kg > 0 -> "%,d".format(Locale("es", "ES"), kg.toInt()).replace(',', '.')
   else -> "—"
  }
 }

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
  item {
   Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
    Text(
     navTitle,
     style = MaterialTheme.typography.headlineSmall,
     fontWeight = FontWeight.Bold
    )
    if (subtitle.isNotBlank()) {
     Text(
      subtitle,
      style = MaterialTheme.typography.bodyMedium,
      color = MaterialTheme.colorScheme.onSurfaceVariant
     )
    }
   }
  }
  item {
   Row(
    Modifier.fillMaxWidth(),
    horizontalArrangement = Arrangement.spacedBy(8.dp)
   ) {
    WorkoutSummaryTile(
     title = "Tiempo",
     value = mins?.let { "$it′" } ?: "—",
     icon = Icons.Outlined.AccessTime,
     modifier = Modifier.weight(1f),
     iconTint = Color(0xFF0A84FF)
    )
    WorkoutSummaryTile(
     title = "Kcal",
     value = "—",
     icon = Icons.Outlined.LocalFireDepartment,
     modifier = Modifier.weight(1f),
     iconTint = Color(0xFFFF9F0A)
    )
    WorkoutSummaryTile(
     title = "Volumen",
     value = volumeLabel,
     icon = Icons.Outlined.FitnessCenter,
     modifier = Modifier.weight(1f),
     iconTint = brandGreen
    )
   }
  }
  workout.review?.let { item { SessionReviewCard(it) } }
  item {
   // Sección «Entreno» + FC (iOS HealthSessionMetricsCard); vacío si no hay muestras.
   Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
    ReperaSectionTitle("Entreno")
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
     Column(Modifier.padding(16.dp)) {
      HeartRateCurveSection(workout.id, heartSeries)
     }
    }
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
  if (workout.routePoints.size >= 2) {
   item {
    CardioRouteSection(
     workout.routePoints,
     showComputedSplits = workout.liveKilometerSplitsSeconds.isEmpty(),
     waterSport = workout.liveSportID?.let(dev.repera.domain.LiveSport::byId)?.isWaterSport == true,
     workoutEpochMs = workoutEpochMs(workout)
    )
   }
  }
 }
 }
