package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
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
 onOpenExercise:(String,String,String)->Unit) {
 val rows=remember(overview) {CompleteHistoryOrder.rows(overview?.completeHistory.orEmpty(),overview?.externalHealthHistory.orEmpty())}
 // Al cambiar de cuenta la hoja se cierra: nada de la cuenta anterior persiste.
 var external by remember(accountId) {mutableStateOf<ExternalHealthHistoryEntry?>(null)}
 LazyColumn(Modifier.fillMaxSize().testTag("complete_history_list"),contentPadding=PaddingValues(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
  item {Text("Historial de entrenamientos",style=MaterialTheme.typography.headlineMedium)}
  if(rows.isEmpty()) item {Text("Sin entrenos. Las sesiones de Repera y Health Connect aparecerán aquí.")}
  rows.groupBy {Instant.ofEpochMilli(it.millis).atZone(ZoneId.systemDefault()).toLocalDate()}.forEach {(day,entries) ->
   item(key="day-$day") {Text(day.format(reperaDayFormatter),style=MaterialTheme.typography.titleMedium)}
   entries.forEach {row ->item(key=row.id) {
    row.local?.let {WorkoutHistoryCard(it,busy,onRevise,onDeleteSet,onDelete,onOpenExercise,accountId,overview?.exerciseEntries.orEmpty(),onUpdate,heartSeries)}
    row.external?.let {entry ->Card(Modifier.fillMaxWidth()) {TextButton(onClick={external=entry}) {Row(horizontalArrangement=Arrangement.spacedBy(10.dp),verticalAlignment=androidx.compose.ui.Alignment.CenterVertically) {
     ExternalHealthActivityIcon(entry.exerciseTypeKey)
     Column {Text(entry.title);Text("Health Connect · ${entry.minutes.toInt()} min")}
    }}}}
   }}
  }
 }
 external?.let {entry ->ExternalHealthDetailSheet(entry,externalProvider,ownerKey=accountId) {external=null}}
}
