package dev.repera.mobile
import androidx.compose.runtime.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable internal fun CenterMessagesScreen(connected:Boolean,loading:Boolean,submitting:Boolean,error:String?,snapshot:BusinessCenterStore.Snapshot?,onRefresh:()->Unit,onSend:(String,String,String)->Unit) {
    var compose by remember {mutableStateOf(false)}
    var title by remember {mutableStateOf("")};var body by remember {mutableStateOf("")}
    val linked=snapshot?.centers.orEmpty().filter {it.id in snapshot?.athleteCenterIds.orEmpty()}
    var target by remember {mutableStateOf<String?>(null)}
    var awaited by remember {mutableStateOf(false)}
    var sawSubmitting by remember {mutableStateOf(false)}
    LaunchedEffect(submitting,error) {
        if(awaited && submitting) sawSubmitting=true
        if(awaited && sawSubmitting && !submitting) {
            if(error==null) {compose=false;body="";title=""}
            awaited=false;sawSubmitting=false
        }
    }
    LazyColumn(Modifier.fillMaxSize(),contentPadding=PaddingValues(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item {Text("Mensajes",style=MaterialTheme.typography.headlineMedium)}
        if(!connected || linked.isEmpty()) item {Text("Vincúlate a un centro o entrenador en Ajustes para enviar y recibir mensajes.")}
        item {OutlinedButton(onClick=onRefresh,enabled=!loading) {Text("Actualizar")}}
        error?.let {item {Text(it,color=MaterialTheme.colorScheme.error)}}
        if(connected && linked.isNotEmpty() && snapshot?.notices.orEmpty().isEmpty()) item {Text("Todavía no hay mensajes.")}
        items(snapshot?.notices.orEmpty()) {n -> Card {Column(Modifier.padding(12.dp)) {
            Text(n.title,style=MaterialTheme.typography.titleMedium);Text(n.body)
            Text("${snapshot?.centerName(n.orgId)} · ${noticeTime(n.createdAt)}",style=MaterialTheme.typography.bodySmall)
        }}}
        if(linked.isNotEmpty()) item {OutlinedButton(onClick={target=linked.first().id;title="";body="";compose=true}) {Text("Escribir mensaje")}}
    }
    if(compose) AlertDialog(onDismissRequest={if(!submitting) compose=false},title={Text("Nuevo mensaje")},text={Column {
        Text("Para")
        linked.forEach {org -> ReperaFilterChip(selected=target==org.id,enabled=!submitting,onClick={target=org.id},label={Text(org.name)})}
        OutlinedTextField(value=title,onValueChange={title=it},label={Text("Asunto")},enabled=!submitting)
        OutlinedTextField(value=body,onValueChange={body=it},label={Text("Mensaje")},enabled=!submitting,minLines=3)
        error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
    }},confirmButton={TextButton(enabled=!submitting && body.trim().length>=2 && target in linked.map {it.id},onClick={target?.let {awaited=true;sawSubmitting=false;onSend(it,title,body)}}) {Text(if(submitting) "Enviando" else "Enviar")}},dismissButton={TextButton(enabled=!submitting,onClick={compose=false}) {Text("Cancelar")}})
}

private fun noticeTime(raw:String):String = runCatching {
    java.time.Instant.parse(raw).atZone(java.time.ZoneId.systemDefault()).format(
        java.time.format.DateTimeFormatter.ofPattern("d MMM yyyy, HH:mm",java.util.Locale("es")))
}.getOrElse {raw}
