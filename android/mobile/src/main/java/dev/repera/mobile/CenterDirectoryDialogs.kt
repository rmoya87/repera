package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

@Composable
internal fun CenterDirectoryDialog(connected:Boolean,rows:List<BusinessCenterStore.Organization>,searching:Boolean,submitting:Boolean,
 linked:Set<String>,onSearch:(String)->Unit,onRequest:(BusinessCenterStore.Organization,String,String?)->Unit,onClose:()->Unit,error:String?=null,accountId:String="") {
 fun scope(field:String)=org.json.JSONArray(listOf(accountId,"center-directory",field)).toString()
 fun textSaver(field:String)=androidx.compose.runtime.saveable.Saver<String,String>(save={saveScopedEditorValue(scope(field),it)},restore={restoreScopedEditorValue(scope(field),it)})
 fun nullableSaver(field:String)=androidx.compose.runtime.saveable.Saver<String?,String>(save={saveScopedEditorValue(scope(field),it)},restore={restoreScopedEditorValue(scope(field),it)})
 var query by rememberSaveable(accountId,stateSaver=textSaver("query")) {mutableStateOf("")}
 // Id restorable; the object is kept in memory so a changing search result does not close the confirm dialog.
 var selectedId by rememberSaveable(accountId,stateSaver=nullableSaver("selected")) {mutableStateOf<String?>(null)}
 var selectedObj by remember {mutableStateOf<BusinessCenterStore.Organization?>(null)}
 val selected=selectedObj?.takeIf {it.id==selectedId} ?: rows.firstOrNull {it.id==selectedId}
 fun clearSelection() {selectedId=null;selectedObj=null}
 var passKind by rememberSaveable(accountId,stateSaver=textSaver("passKind")) {mutableStateOf("class")}
 var note by rememberSaveable(accountId,stateSaver=textSaver("note")) {mutableStateOf("")}
 LaunchedEffect(linked) {if(selectedId in linked) {clearSelection();note=""}}
 LaunchedEffect(query,connected) {if(connected) {delay(350);onSearch(query)}}
 AlertDialog(onDismissRequest=onClose,title={Text("Buscar centro o entrenador")},
  text={Column(Modifier.verticalScroll(rememberScrollState())) {
   ReperaMetaTextField(caption="Nombre del centro o entrenador",value=query,onValueChange={query=it},testTag="center_directory_query")
   if(!connected) Text("La búsqueda estará disponible al recuperar la conexión.")
   else if(searching) CircularProgressIndicator()
   else if(rows.isEmpty()) ReperaEmptyState(
     title = "No hay resultados",
     subtitle = "Prueba otro nombre o pide invitación a tu centro"
   )
   else rows.forEach {org ->TextButton(enabled=org.id !in linked && !submitting,onClick={selectedObj=org;selectedId=org.id;note=""}) {
    Column {Text(org.name);Text(if(org.id in linked) "Vinculado" else org.tagline ?: org.kind)}
   }}
  }},confirmButton={TextButton(onClick=onClose) {Text("Cerrar")}})
 selected?.let {org -> AlertDialog(onDismissRequest={clearSelection()},title={Text(org.name)},
  text={Column {
   Text("Qué quieres contratar")
   listOf("class" to "Clases / bono de sesiones","appointment" to "Entrenador personal","unlimited" to "Acceso ilimitado").forEach {(kind,label) ->
    Row {RadioButton(passKind==kind,{passKind=kind});TextButton(onClick={passKind=kind}) {Text(label)}}
   }
   ReperaMetaTextField(caption="Nota para el centro (opcional)",value=note,onValueChange={note=it})
   Text("El centro confirmará el bono solicitado.")
   error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
  }},confirmButton={TextButton(enabled=!submitting,onClick={onRequest(org,passKind,note.takeIf {it.isNotBlank()})}) {Text("Enviar solicitud")}},
  dismissButton={TextButton(onClick={clearSelection()}) {Text("Cancelar")}})}
}
@Composable
internal fun LinkedCenterDialog(org:BusinessCenterStore.Organization,snapshot:BusinessCenterStore.Snapshot?,submitting:Boolean,
 onLeave:(BusinessCenterStore.Organization)->Unit,onClose:()->Unit,sharing:Boolean=false,sharingBusy:Boolean=false,onSharing:(Boolean)->Unit={},error:String?=null) {
 var confirm by remember {mutableStateOf(false)}
 var requestedLeave by remember {mutableStateOf(false)}
 LaunchedEffect(snapshot?.athleteCenterIds) {if(requestedLeave && snapshot!=null && org.id !in snapshot.athleteCenterIds) onClose()}
 AlertDialog(onDismissRequest=onClose,title={Text(org.name)},text={Column(Modifier.verticalScroll(rememberScrollState()),verticalArrangement=Arrangement.spacedBy(10.dp)) {
  Text(org.tagline ?: org.kind, style=MaterialTheme.typography.bodySmall)
  Text("Historial de pagos", style=MaterialTheme.typography.titleSmall, fontWeight=FontWeight.SemiBold)
  val passes=snapshot?.passes.orEmpty().filter {it.orgId==org.id}
  if(passes.isEmpty()) Text("Todavía no hay pagos registrados con este centro.", style=MaterialTheme.typography.bodySmall)
  passes.forEach {pass ->
   val offer=snapshot?.offerName(pass)
   Text(offer ?: if(pass.kind=="appointment") "Plan de citas" else "Plan de clases", fontWeight=FontWeight.SemiBold)
   val method=when {
    pass.issuanceType=="complimentary" || pass.paymentMethod=="complimentary" -> "Cortesía"
    pass.paymentMethod=="cash" -> "Efectivo"
    pass.paymentMethod=="transfer" -> "Transferencia"
    pass.paymentMethod=="card" -> "Tarjeta"
    else -> "Plan"
   }
   val amount=pass.paidAmountCents?.let { String.format("%.2f €", it / 100.0) }
   Text(listOfNotNull(method, amount).joinToString(" · "), style=MaterialTheme.typography.bodySmall)
   (pass.paidAt ?: pass.validFrom)?.let {date ->
    val formatted=runCatching {java.time.Instant.parse(date).atZone(java.time.ZoneId.systemDefault()).toLocalDate().format(reperaDayFormatter)}.getOrDefault(date)
    Text(formatted, style=MaterialTheme.typography.labelSmall)
   }
  }
  Text("Historial de clases", style=MaterialTheme.typography.titleSmall, fontWeight=FontWeight.SemiBold)
  val past=snapshot?.bookings.orEmpty().filter {it.orgId==org.id}.take(20)
  if(past.isEmpty()) Text("Aún no has asistido ni reservado clases con este centro.", style=MaterialTheme.typography.bodySmall)
  past.forEach {booking ->
   val occ=snapshot?.occurrences?.firstOrNull {it.id==booking.occurrenceId}
   val title=occ?.title ?: "Clase"
   val status=when(booking.status){
    "attended"->"Asististe"; "booked"->"Reservada"; "waitlist"->"Lista de espera"
    "cancelled"->"Cancelada"; "no_show"->"No presentado"; else -> booking.status
   }
   Text("$title · $status", style=MaterialTheme.typography.bodySmall)
  }
  error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
  TextButton(enabled=!submitting,onClick={confirm=true}) {Text("Desvincularme como cliente")}
 }},confirmButton={TextButton(onClick=onClose) {Text("Cerrar")}})
 if(confirm) AlertDialog(onDismissRequest={confirm=false},title={Text("¿Dejar de ser cliente de ${org.name}?")},
  text={Text("Se cancelarán tus reservas futuras y bonos activos, pero se conservará tu historial personal. Si administras el centro, no perderás tus permisos de gestión.")},
  confirmButton={TextButton(enabled=!submitting,onClick={confirm=false;requestedLeave=true;onLeave(org)}) {Text("Desvincularme")}},
  dismissButton={TextButton(onClick={confirm=false}) {Text("Cancelar")}})
}
