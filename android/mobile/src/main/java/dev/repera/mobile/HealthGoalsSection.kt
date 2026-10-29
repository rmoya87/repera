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
    Text("Vacío = sin objetivo. No se inventa progreso.",style=MaterialTheme.typography.bodySmall,color=MaterialTheme.colorScheme.onSurfaceVariant)
    Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
        // I-11: tres secciones como iOS (diarios / semanal / corporal).
        ReperaSectionTitle("Objetivos diarios")
        GoalField("Pasos", steps, busy) { steps = it }
        GoalField("Calorías activas (kcal)", energy, busy) { energy = it }
        GoalField("Tiempo de entreno (min)", minutes, busy) { minutes = it }
        ReperaSectionTitle("Objetivo semanal")
        GoalField("Entrenamientos por semana", weekly, busy) { weekly = it }
        ReperaSectionTitle("Objetivo corporal")
        GoalField("Peso objetivo (kg)", weight, busy) { weight = it }
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

@Composable
private fun GoalField(label: String, text: String, busy: Boolean, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = text,
        onValueChange = onChange,
        label = { Text(label) },
        enabled = !busy,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
        singleLine = true,
        modifier = Modifier.fillMaxWidth()
    )
}
