package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import kotlinx.coroutines.delay

@Composable
internal fun CenterDirectoryDialog(connected:Boolean,rows:List<BusinessCenterStore.Organization>,searching:Boolean,submitting:Boolean,
 linked:Set<String>,onSearch:(String)->Unit,onRequest:(BusinessCenterStore.Organization,String,String?)->Unit,onClose:()->Unit,error:String?=null) {
 var query by rememberSaveable {mutableStateOf("")}
 var selected by remember {mutableStateOf<BusinessCenterStore.Organization?>(null)}
 var passKind by rememberSaveable {mutableStateOf("class")}
 var note by rememberSaveable {mutableStateOf("")}
 LaunchedEffect(linked) {if(selected?.id in linked) {selected=null;note=""}}
 LaunchedEffect(query,connected) {if(connected) {delay(350);onSearch(query)}}
 AlertDialog(onDismissRequest=onClose,title={Text("Buscar centro o entrenador")},
  text={Column(Modifier.verticalScroll(rememberScrollState())) {
   OutlinedTextField(query,{query=it},label={Text("Nombre del centro o entrenador")},modifier=Modifier.testTag("center_directory_query"))
   if(!connected) Text("La búsqueda estará disponible al recuperar la conexión.")
   else if(searching) CircularProgressIndicator()
   else if(rows.isEmpty()) Text("No hay resultados. Prueba otro nombre o pide invitación a tu centro.")
   else rows.forEach {org ->TextButton(enabled=org.id !in linked && !submitting,onClick={selected=org;note=""}) {
    Column {Text(org.name);Text(if(org.id in linked) "Vinculado" else org.tagline ?: org.kind)}
   }}
  }},confirmButton={TextButton(onClick=onClose) {Text("Cerrar")}})
 selected?.let {org -> AlertDialog(onDismissRequest={selected=null},title={Text(org.name)},
  text={Column {
   Text("Qué quieres contratar")
   listOf("class" to "Clases / bono de sesiones","appointment" to "Entrenador personal","unlimited" to "Acceso ilimitado").forEach {(kind,label) ->
    Row {RadioButton(passKind==kind,{passKind=kind});TextButton(onClick={passKind=kind}) {Text(label)}}
   }
   OutlinedTextField(note,{note=it},label={Text("Nota para el centro (opcional)")})
   Text("El centro confirmará el bono solicitado.")
   error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
  }},confirmButton={TextButton(enabled=!submitting,onClick={onRequest(org,passKind,note.takeIf {it.isNotBlank()})}) {Text("Vincularme y continuar")}},
  dismissButton={TextButton(onClick={selected=null}) {Text("Cancelar")}})}
}
@Composable
internal fun LinkedCenterDialog(org:BusinessCenterStore.Organization,snapshot:BusinessCenterStore.Snapshot?,submitting:Boolean,
 onLeave:(BusinessCenterStore.Organization)->Unit,onClose:()->Unit,sharing:Boolean=false,sharingBusy:Boolean=false,onSharing:(Boolean)->Unit={},error:String?=null) {
 var confirm by remember {mutableStateOf(false)}
 var requestedLeave by remember {mutableStateOf(false)}
 LaunchedEffect(snapshot?.athleteCenterIds) {if(requestedLeave && snapshot!=null && org.id !in snapshot.athleteCenterIds) onClose()}
 AlertDialog(onDismissRequest=onClose,title={Text(org.name)},text={Column(Modifier.verticalScroll(rememberScrollState())) {
  Text(org.tagline ?: org.kind)
  Text("Bonos y sesiones")
  val passes=snapshot?.passes.orEmpty().filter {it.orgId==org.id}
  if(passes.isEmpty()) Text("Sin bonos activos. El centro confirmará tu bono solicitado.")
  passes.forEach {pass ->
   Text(if(pass.kind=="appointment") "Sesiones personales" else if(pass.kind=="unlimited") "Acceso ilimitado" else "Clases")
   Text("${pass.remainingCredits} de ${pass.totalCredits} disponibles")
   pass.validUntil?.let {date ->
    val formatted=runCatching {java.time.Instant.parse(date).atZone(java.time.ZoneId.systemDefault()).toLocalDate().format(reperaDayFormatter)}.getOrDefault(date)
    Text("Caduca: $formatted")
   }
  }
  snapshot?.trainingSessions.orEmpty().filter {it.orgId==org.id}.take(12).forEach {Text("${it.title} · ${it.scheduledDate}")}
  Row {
   Switch(sharing,onCheckedChange=onSharing,enabled=!sharingBusy && !submitting)
   Text("Compartir resultados")
  }
  Text("Series, repeticiones y marcas con el equipo. Puedes desactivarlo.")
  error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
  TextButton(enabled=!submitting,onClick={confirm=true}) {Text("Desvincularme")}
 }},confirmButton={TextButton(onClick=onClose) {Text("Cerrar")}})
 if(confirm) AlertDialog(onDismissRequest={confirm=false},title={Text("¿Desvincularte de ${org.name}?")},
  text={Text("Al desvincularte pierdes el acceso completo asociado a este centro, salvo que tengas Repera Pro.")},
  confirmButton={TextButton(enabled=!submitting,onClick={confirm=false;requestedLeave=true;onLeave(org)}) {Text("Desvincularme")}},
  dismissButton={TextButton(onClick={confirm=false}) {Text("Cancelar")}})
}
