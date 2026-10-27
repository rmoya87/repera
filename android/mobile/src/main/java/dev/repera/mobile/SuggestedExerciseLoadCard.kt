package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

@Composable
internal fun SuggestedExerciseLoadCard(tested:Double?,estimated:Double?,increment:Double) {
    var percent by rememberSaveable {mutableStateOf(70f)}
    val oneRM=tested ?: estimated
    val source=if(tested!=null) "1RM" else "e1RM"
    Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
        Text("Carga sugerida",style=MaterialTheme.typography.titleMedium)
        if(oneRM!=null && oneRM>0) {
            val kg=dev.repera.domain.LoadSuggestion.weightKg(oneRM,percent.toDouble(),increment)
            Text("${percent.toInt()}% $source · ${dev.repera.domain.ReperaNumberFormat.decimal(kg)} kg",modifier=Modifier.testTag("suggested_load_value"))
            Slider(percent,{percent=it},valueRange=50f..95f,steps=8,modifier=Modifier.testTag("suggested_load_percent"))
            Text("Pasos de 5% · sobre $source ${dev.repera.domain.ReperaNumberFormat.decimal(oneRM)} kg",style=MaterialTheme.typography.bodySmall)
        } else Text("Fija el Tope 1RM en Evolución (o entrena con peso) para calcular kg.")
    }}
}
@Composable
internal fun TestedOneRMEditor(tested:Double?,busy:Boolean,onSave:(Double?)->Unit) {
    var editing by remember {mutableStateOf(false)}
    var draft by remember(tested) {mutableStateOf(tested?.toString().orEmpty())}
    TextButton(enabled=!busy,onClick={draft=tested?.toString().orEmpty();editing=true},modifier=Modifier.testTag("tested_onerm_edit")) {
        Text("Tope 1RM · ${tested?.let {dev.repera.domain.ReperaNumberFormat.decimal(it) + " kg"} ?: "—"}")
    }
    val parsed=draft.replace(',','.').toDoubleOrNull()?.takeIf {it.isFinite() && it>0}
    if(editing) AlertDialog(onDismissRequest={editing=false},title={Text("Tope 1RM")},
        text={OutlinedTextField(draft,{draft=it},label={Text("Kilogramos (vacío para borrar)")},singleLine=true,
            keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),modifier=Modifier.testTag("tested_onerm_input"))},
        confirmButton={TextButton(enabled=!busy && (draft.isBlank() || parsed!=null),onClick={editing=false;onSave(parsed)}) {Text("Guardar tope")}},
        dismissButton={TextButton(onClick={editing=false}) {Text("Cancelar")}})
}
