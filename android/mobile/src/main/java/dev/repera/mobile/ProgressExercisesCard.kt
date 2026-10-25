package dev.repera.mobile
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
  if(exercises.size>5) TextButton(onClick={all=true}) {Text("Ver todos los ejercicios (${exercises.size})")}
 }}
 if(all) AlertDialog(onDismissRequest={all=false},title={Text("Todos los ejercicios del periodo")},
  text={Column(Modifier.verticalScroll(rememberScrollState())) {exercises.forEach {row(it)}}},
  confirmButton={TextButton(onClick={all=false}) {Text("Cerrar")}})
}
