package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.repera.domain.PersonalRecord
import java.time.Instant
import java.time.ZoneId

@Composable
internal fun ProgressRecordsCard(records:List<PersonalRecord>,onExercise:(String)->Unit) {
 var all by remember {mutableStateOf(false)}
 val recent=remember(records) {records.sortedWith(compareByDescending<PersonalRecord> {it.epochMillis}.thenByDescending {it.estimatedOneRM})}
 @Composable fun record(r:PersonalRecord) {
  TextButton(onClick={onExercise(r.exerciseId)}) {Column {
   Text(r.exerciseName)
   Text("${formatWeight(r.weightKg)} kg × ${r.reps} · e1RM ${formatWeight(r.estimatedOneRM)} kg")
   Text(Instant.ofEpochMilli(r.epochMillis).atZone(ZoneId.systemDefault()).toLocalDate().format(reperaDayFormatter),style=MaterialTheme.typography.bodySmall)
  }}
 }
 ReperaCard(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
  Text("Récords del periodo",style=MaterialTheme.typography.titleMedium)
  if(recent.isEmpty()) Text("Sin récords en el periodo. Entrena y apunta pesos para ver e1RM.")
  recent.take(5).forEach {record(it)}
  if(recent.size>5) TextButton(onClick={all=true}) {Text("Ver todos los récords (${recent.size})")}
 }}
 if(all) AlertDialog(onDismissRequest={all=false},title={Text("Todos los récords")},
  text={Column(Modifier.verticalScroll(rememberScrollState())) {recent.forEach {record(it)}}},
  confirmButton={TextButton(onClick={all=false}) {Text("Cerrar")}})
}
