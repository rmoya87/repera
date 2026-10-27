package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

@Composable
internal fun BodyWeightHistoryScreen(entries:List<BodyWeightHistoryEntry>,busy:Boolean,
    onAdd:(Double)->Unit,onDelete:(String)->Unit,accountId:String="") {
    var kgText by rememberSaveable(accountId) {mutableStateOf("")}
    var pendingDelete by remember {mutableStateOf<BodyWeightHistoryEntry?>(null)}
    val parsed=kgText.replace(',','.').toDoubleOrNull()?.takeIf {it.isFinite() && it in 20.0..400.0}
    LazyColumn(Modifier.fillMaxSize().testTag("weight_history_list"),contentPadding=PaddingValues(18.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item {Text("Peso corporal",style=MaterialTheme.typography.headlineMedium)}
        item {
            Row(horizontalArrangement=Arrangement.spacedBy(8.dp),verticalAlignment=Alignment.CenterVertically) {
                OutlinedTextField(kgText,{kgText=it},label={Text("Peso en kilogramos")},singleLine=true,
                    keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),modifier=Modifier.weight(1f).testTag("weight_history_input"))
                TextButton(enabled=!busy && parsed!=null,onClick={parsed?.let(onAdd);kgText=""}) {Text("Añadir")}
            }
            Text("Un peso por día. Si ya hay uno hoy, se actualiza.",style=MaterialTheme.typography.bodySmall)
        }
        item {Text("Historial",style=MaterialTheme.typography.titleMedium)}
        if(entries.isEmpty()) item {Text("Aún no hay pesos registrados.")}
        items(entries,key={it.id}) {entry ->
            Card(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth().padding(12.dp),verticalAlignment=Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(entry.day.format(reperaDayFormatter))
                        Text(if(entry.source=="health") "Salud" else "Propio",style=MaterialTheme.typography.bodySmall)
                    }
                    Text("${dev.repera.domain.ReperaNumberFormat.decimal(entry.kg)} kg")
                    TextButton(enabled=!busy,onClick={pendingDelete=entry},modifier=Modifier.testTag("delete_weight_${entry.id}")) {Text("Borrar")}
                }
            }
        }
        item {Text("Propio = guardado en Repera. Salud = importado de Health Connect.",style=MaterialTheme.typography.bodySmall)}
    }
    pendingDelete?.let {entry -> AlertDialog(onDismissRequest={pendingDelete=null},
        title={Text("¿Borrar este peso?")},text={Text("Se quitará del historial de Repera. No se borra de Health Connect.")},
        confirmButton={TextButton(enabled=!busy,onClick={pendingDelete=null;onDelete(entry.id)}) {Text("Borrar")}},
        dismissButton={TextButton(onClick={pendingDelete=null}) {Text("Cancelar")}})}
}
