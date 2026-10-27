package dev.repera.mobile
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
internal fun ProgressExercisesCard(exercises:List<ProgressExerciseRow>,onExercise:(String)->Unit) {
 var all by remember {mutableStateOf(false)}
 @Composable fun row(e:ProgressExerciseRow) {
  TextButton(onClick={onExercise(e.id)}) {Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
   Text(e.name,modifier=Modifier.weight(1f));e.topWeight?.let {Text("${formatWeight(it)} kg")}
  }}
 }
 Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
  Text("Progreso por ejercicio",style=MaterialTheme.typography.titleMedium)
  if(exercises.isEmpty()) Text("Sin ejercicios aún. Cuando registres series, verás el progreso aquí.")
  exercises.take(5).forEach {row(it)}
  if(exercises.size>5) TextButton(onClick={all=true},modifier=Modifier.semantics {contentDescription="Ver todos los ejercicios"}) {Text("Ver más")}
 }}
 if(all) AlertDialog(onDismissRequest={all=false},title={Text("Todos los ejercicios del periodo")},
  text={Column(Modifier.verticalScroll(rememberScrollState())) {exercises.forEach {row(it)}}},
  confirmButton={TextButton(onClick={all=false}) {Text("Cerrar")}})
}

/** Apple mobilityProgressCard: recorded time, sessions and (Pro) links to the first 3 mobility exercises. */
@Composable
internal fun ProgressMobilityCard(sessions:Int,seconds:Int,proLinks:List<ProgressExerciseRow>,onExercise:(String)->Unit) {
 Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
  Text("Movilidad",style=MaterialTheme.typography.titleMedium)
  Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {Text("Tiempo registrado");Text(ProgressTilesModel.mobilityDuration(seconds))}
  Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {Text("Sesiones con movilidad");Text("$sessions")}
  proLinks.forEach {e -> TextButton(onClick={onExercise(e.id)}) {Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {Text(e.name,modifier=Modifier.weight(1f));Text("›")}}}
 }}
}

/** Apple freeExerciseTrendPreview: fixed fictitious weights, never reads user data. */
@Composable
internal fun ProgressExerciseTrendPreview(today:java.time.LocalDate) {
 val weights=listOf(42.0,45.0,44.0,49.0,47.0,52.0,55.0)
 Card(Modifier.fillMaxWidth().semantics {contentDescription="Ejemplo de evolución por ejercicio, datos simulados."}) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
  Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {Text("Evolución por ejercicio",style=MaterialTheme.typography.titleMedium);Text("Ejemplo",style=MaterialTheme.typography.labelMedium)}
  Text("Evolución de carga · datos ficticios",style=MaterialTheme.typography.bodySmall)
  DayPointLineChart(weights.mapIndexed {i,w ->dev.repera.domain.ProgressDayPoint(today.minusDays(6L-i),w)},bounds=35.0..65.0,interactive=false)
 }}
}
