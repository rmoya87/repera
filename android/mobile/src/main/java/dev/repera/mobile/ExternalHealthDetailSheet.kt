package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.time.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable internal fun ExternalHealthDetailSheet(entry:ExternalHealthHistoryEntry,
 provider:suspend(ExternalHealthHistoryEntry)->ExternalHealthDetail?,onClose:()->Unit) {
 var loading by remember(entry.id) {mutableStateOf(true)}
 var detail by remember(entry.id) {mutableStateOf<ExternalHealthDetail?>(null)}
 LaunchedEffect(entry.id) {detail=runCatching {provider(entry)}.getOrNull();loading=false}
 ModalBottomSheet(onDismissRequest=onClose) {
  Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(20.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
   Text(entry.title,style=MaterialTheme.typography.titleLarge)
   Text(Instant.ofEpochMilli(entry.startMillis).atZone(ZoneId.systemDefault()).toLocalDate().format(reperaDayFormatter))
   Text("${entry.minutes.toInt()} min registrados · Health Connect")
   Text("Fuente: ${entry.sourcePackage}",style=MaterialTheme.typography.bodySmall)
   if(loading) CircularProgressIndicator()
   else if(detail==null) Text("No se pudo verificar el registro de Salud. Puede haber cambiado o faltar permiso.")
   else {
    val current=detail!!
    current.activeKcal?.let {Text("Energía activa medida: ${formatWeight(it)} kcal")}
    if(current.heart.isEmpty()) Text("Sin pulso autorizado de esta fuente") else {
     Text("Pulso medido · media ${current.heart.map {it.second}.average().toInt()} lpm")
     Text("Mín ${current.heart.minOf {it.second}} · Máx ${current.heart.maxOf {it.second}} lpm")
     HeartRateCurveSection(entry.id) {current.heart}
    }
    Text("Solo mediciones de la fuente del registro. No se estima energía ni pulso.",style=MaterialTheme.typography.bodySmall)
   }
   TextButton(onClick=onClose) {Text("Cerrar")}
   Spacer(Modifier.height(20.dp))
  }
 }
}
