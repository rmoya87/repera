package dev.repera.mobile
import androidx.activity.compose.BackHandler
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import java.time.*

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
  )
  return
 }
 if (onBack != null) BackHandler(onBack = onBack)
 LazyColumn(Modifier.fillMaxSize().testTag("complete_history_list"),contentPadding=PaddingValues(16.dp),verticalArrangement= Arrangement.spacedBy(12.dp)) {
  item {
   if (onBack != null) {
    // R7 P2: mismo círculo glass 48/44/24 que el resto de toolbars.
    ReperaToolbarGlassIconButton(
     icon = Icons.AutoMirrored.Outlined.ArrowBack,
     contentDescription = "Volver",
     onClick = onBack,
     enabled = !busy,
     modifier = Modifier.testTag("complete_history_back")
    )
   }
   ReperaPageHeader(title = "Historial")
  }
  // iOS HistoryView: fila Deportes siempre visible.
  item {
   ReperaCard(
    onClick = onOpenSports,
    modifier = Modifier.fillMaxWidth().testTag("history_sports_link")
   ) {
    Row(
     Modifier.padding(16.dp).fillMaxWidth(),
     horizontalArrangement = Arrangement.SpaceBetween,
     verticalAlignment = Alignment.CenterVertically
    ) {
     Text("Deportes · evolución y récords")
     Icon(
      Icons.AutoMirrored.Outlined.KeyboardArrowRight,
      contentDescription = null,
      tint = MaterialTheme.colorScheme.onSurfaceVariant
     )
    }
   }
  }
  if(rows.isEmpty()) item {
    ReperaEmptyState(
      title = "Sin entrenos",
      subtitle = "Las sesiones de Repera y Health Connect aparecerán aquí"
    )
  }
  val today = LocalDate.now()
  rows.groupBy {Instant.ofEpochMilli(it.millis).atZone(ZoneId.systemDefault()).toLocalDate()}.forEach {(day,entries) ->
   item(key="day-$day") {
    ReperaSectionTitle(if (day == today) "Hoy" else day.format(reperaDayFormatter))
   }
   entries.forEach {row ->item(key=row.id) {
    row.local?.let { workout ->
     val mins = workout.displayDurationMinutes().takeIf { it > 0 }?.let { kotlin.math.round(it).toInt() }
     val prs = overview?.prCountBySessionId?.get(workout.id) ?: 0
     ReperaCard(
      onClick = { selectedWorkoutId = workout.id },
      modifier = Modifier.fillMaxWidth().testTag("history_workout_row_${workout.id}")
     ) {
      Row(
       Modifier.padding(16.dp).fillMaxWidth(),
       horizontalArrangement = Arrangement.spacedBy(12.dp),
       verticalAlignment = Alignment.CenterVertically
      ) {
       Surface(
        shape = androidx.compose.foundation.shape.RoundedCornerShape(10.dp),
        color = MaterialTheme.colorScheme.primaryContainer,
        modifier = Modifier.size(40.dp)
       ) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
         Icon(
          Icons.Outlined.FitnessCenter,
          contentDescription = null,
          tint = MaterialTheme.colorScheme.primary,
          modifier = Modifier.size(22.dp)
         )
        }
       }
       Column(modifier = Modifier.weight(1f)) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
         Text(workout.title, style = MaterialTheme.typography.titleMedium)
         if (workout.startedAt.isNotBlank()) {
          Text(
           workout.startedAt,
           style = MaterialTheme.typography.bodySmall,
           color = MaterialTheme.colorScheme.onSurfaceVariant
          )
         }
        }
        val meta = buildList {
         if (mins != null && mins > 0) add("$mins min")
         if (prs > 0) add("$prs PR")
        }.joinToString(" · ")
        if (meta.isNotEmpty()) {
         Text(
          meta,
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
    row.external?.let {entry ->ReperaCard(onClick={external=entry},modifier=Modifier.fillMaxWidth()) {
     Row(Modifier.padding(16.dp),horizontalArrangement=Arrangement.spacedBy(10.dp),verticalAlignment=androidx.compose.ui.Alignment.CenterVertically) {
      ExternalHealthActivityIcon(entry.exerciseTypeKey)
      Column {Text(entry.title);Text("Health Connect · ${entry.minutes.toInt()} min",style=MaterialTheme.typography.bodySmall,color=MaterialTheme.colorScheme.onSurfaceVariant)}
     }
    }}
   }}
  }
 }
 external?.let {entry ->ExternalHealthDetailSheet(entry,externalProvider,ownerKey=accountId) {external=null}}
}

/** Detalle a pantalla completa (paridad HistoryView → WorkoutDetailView). */
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
) {
 LazyColumn(
  Modifier.fillMaxSize().testTag("workout_history_detail"),
  contentPadding = PaddingValues(16.dp),
  verticalArrangement = Arrangement.spacedBy(12.dp)
 ) {
  item {
   ReperaToolbarGlassIconButton(
    icon = Icons.AutoMirrored.Outlined.ArrowBack,
    contentDescription = "Volver",
    onClick = onBack,
    modifier = Modifier.testTag("workout_history_detail_back")
   )
  }
  item {
   WorkoutHistoryCard(
    workout,
    busy,
    onRevise,
    onDeleteSet,
    onDelete,
    onOpenExercise,
    accountId,
    exerciseCatalog,
    onUpdate,
    heartSeries,
    effortUnit = effortUnit,
    startsExpanded = true,
   )
  }
 }
}
