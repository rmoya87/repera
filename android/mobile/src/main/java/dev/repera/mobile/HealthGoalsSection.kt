package dev.repera.mobile
import androidx.compose.runtime.*
import androidx.compose.material3.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

@Composable internal fun HealthGoalsSection(value:HealthGoals,busy:Boolean,onChange:(HealthGoals)->Unit) {
    var steps by remember(value) {mutableStateOf(value.steps?.toString().orEmpty())}
    var energy by remember(value) {mutableStateOf(value.energyKcal?.toString().orEmpty())}
    var minutes by remember(value) {mutableStateOf(value.minutes?.toString().orEmpty())}
    var weekly by remember(value) {mutableStateOf(value.weeklyWorkouts?.toString().orEmpty())}
    var weight by remember(value) {mutableStateOf(value.weightKg?.toString().orEmpty())}
    var error by remember {mutableStateOf<String?>(null)}
    ReperaSectionTitle("Objetivos")
    Text("Vacío = sin objetivo. No se inventa progreso.",style=MaterialTheme.typography.bodySmall,color=MaterialTheme.colorScheme.onSurfaceVariant)
    Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
        listOf(Triple("Pasos",steps,{s:String->steps=s}),Triple("Calorías activas (kcal)",energy,{s:String->energy=s}),
            Triple("Tiempo de entreno (min)",minutes,{s:String->minutes=s}),Triple("Entrenamientos por semana",weekly,{s:String->weekly=s}),
            Triple("Peso objetivo (kg)",weight,{s:String->weight=s})).forEach {(label,text,change) ->
            OutlinedTextField(value=text,onValueChange=change,label={Text(label)},enabled=!busy,
                keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),singleLine=true,modifier=Modifier.fillMaxWidth())
        }
        error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
        OutlinedButton(enabled=!busy,onClick={
            try {
                fun int(s:String)=s.trim().takeIf {it.isNotEmpty()}?.toInt()
                val next=HealthGoals(int(steps),int(energy),int(minutes),int(weekly),weight.trim().takeIf {it.isNotEmpty()}?.replace(',','.')?.toDouble())
                HealthGoals.apply(org.json.JSONObject(),next)
                error=null;onChange(next)
            } catch(_:Exception) {error="Revisa los rangos: pasos100–100000, kcal10–10000, minutos1–1440, entrenamientos1–21, peso20–350kg."}
        }, modifier=Modifier.fillMaxWidth()) {Text("Guardar objetivos")}
    }
}
