package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
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
 onOpenSports: () -> Unit = {}) {
 val rows=remember(overview) {CompleteHistoryOrder.rows(overview?.completeHistory.orEmpty(),overview?.externalHealthHistory.orEmpty())}
 // Al cambiar de cuenta la hoja se cierra: nada de la cuenta anterior persiste.
 var external by remember(accountId) {mutableStateOf<ExternalHealthHistoryEntry?>(null)}
 LazyColumn(Modifier.fillMaxSize().testTag("complete_history_list"),contentPadding=PaddingValues(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
  item { ReperaPageHeader(title = "Historial de entrenamientos") }
  // I-13: fila Deportes → I-24
  if (overview?.liveSportSessions.orEmpty().isNotEmpty()) item {
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
  rows.groupBy {Instant.ofEpochMilli(it.millis).atZone(ZoneId.systemDefault()).toLocalDate()}.forEach {(day,entries) ->
   item(key="day-$day") {ReperaSectionTitle(day.format(reperaDayFormatter))}
   entries.forEach {row ->item(key=row.id) {
    row.local?.let {WorkoutHistoryCard(it,busy,onRevise,onDeleteSet,onDelete,onOpenExercise,accountId,overview?.exerciseEntries.orEmpty(),onUpdate,heartSeries,
        effortUnit=overview?.trainingSettings?.effortUnit ?: "rir")}
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
