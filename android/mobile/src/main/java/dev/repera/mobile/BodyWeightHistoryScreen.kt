package dev.repera.mobile

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
internal fun BodyWeightHistoryScreen(entries:List<BodyWeightHistoryEntry>,busy:Boolean,
    onAdd:(Double)->Unit,onDelete:(String)->Unit,accountId:String="",
    onBack:(()->Unit)? = null) {
    if (onBack != null) BackHandler(onBack = onBack)
    var kgText by rememberSaveable(accountId) {mutableStateOf("")}
    var pendingDelete by remember {mutableStateOf<BodyWeightHistoryEntry?>(null)}
    val parsed=dev.repera.domain.ReperaNumberFormat.parse(kgText)?.takeIf {it.isFinite() && it in 20.0..400.0}
    LazyColumn(Modifier.fillMaxSize().testTag("weight_history_list"),contentPadding=PaddingValues(18.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item {
            if (onBack != null) {
                IconButton(
                    onClick = onBack,
                    enabled = !busy,
                    modifier = Modifier
                        .size(44.dp)
                        .background(MaterialTheme.colorScheme.surfaceVariant, CircleShape)
                        .testTag("weight_history_back")
                ) {
                    Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Volver")
                }
            }
            ReperaPageHeader(title = "Peso corporal")
        }
        item {
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Row(
                    Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "Peso corporal",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.weight(1f)
                    )
                    ReperaNumericField(
                        value = kgText,
                        onValueChange = { kgText = it },
                        label = "kg",
                        modifier = Modifier
                            .widthIn(min = 88.dp, max = 120.dp)
                            .testTag("weight_history_input")
                    )
                    TextButton(
                        enabled = !busy && parsed != null,
                        onClick = { parsed?.let(onAdd); kgText = "" }
                    ) { Text("Añadir") }
                }
            }
        }
        item { ReperaSectionTitle("Historial") }
        if(entries.isEmpty()) item {
            ReperaEmptyState(
                title = "Aún no hay pesos registrados",
                subtitle = "Registra tu peso corporal para ver la evolución"
            )
        }
        items(entries,key={it.id}) {entry ->
            ReperaCard(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth().padding(12.dp),verticalAlignment=Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(entry.day.format(reperaDayFormatter))
                        Text(
                            if (entry.source == "health") "Salud" else "Propio",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Text("${dev.repera.domain.ReperaNumberFormat.decimal(entry.kg)} kg")
                    TextButton(
                        enabled = !busy,
                        onClick = { pendingDelete = entry },
                        modifier = Modifier.testTag("delete_weight_${entry.id}")
                    ) { Text("Borrar") }
                }
            }
        }
    }
    pendingDelete?.let {entry -> AlertDialog(onDismissRequest={pendingDelete=null},
        title={Text("¿Borrar este peso?")},text={Text("Se quitará del historial de Repera. No se borra de Health Connect.")},
        confirmButton={TextButton(enabled=!busy,onClick={pendingDelete=null;onDelete(entry.id)}) {Text("Borrar")}},
        dismissButton={TextButton(onClick={pendingDelete=null}) {Text("Cancelar")}})}
}
