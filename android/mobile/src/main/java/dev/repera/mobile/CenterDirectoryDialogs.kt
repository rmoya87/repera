package dev.repera.mobile

import androidx.compose.ui.res.stringResource
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
 AlertDialog(onDismissRequest=onClose,title={Text(stringResource(R.string.center_directory_dialogs_buscar_centro_o_entrenador))},
  text={Column(Modifier.verticalScroll(rememberScrollState())) {
   ReperaMetaTextField(caption="Nombre del centro o entrenador",value=query,onValueChange={query=it},testTag="center_directory_query")
   if(!connected) Text(stringResource(R.string.center_directory_dialogs_la_busqueda_estara_disponible_al_recuperar))
   else if(searching) CircularProgressIndicator()
   else if(rows.isEmpty()) ReperaEmptyState(
     title = stringResource(R.string.center_directory_dialogs_no_hay_resultados),
     subtitle = stringResource(R.string.center_directory_dialogs_prueba_otro_nombre_o_pide_invitacion)
   )
   else rows.forEach {org ->TextButton(enabled=org.id !in linked && !submitting,onClick={selectedObj=org;selectedId=org.id;note=""}) {
    Column {Text(org.name);Text(if(org.id in linked) "Vinculado" else org.tagline ?: org.kind)}
   }}
  }},confirmButton={TextButton(onClick=onClose) {Text(stringResource(R.string.action_close))}})
 selected?.let {org -> AlertDialog(onDismissRequest={clearSelection()},title={Text(org.name)},
  text={Column {
   Text(stringResource(R.string.center_directory_dialogs_que_quieres_contratar))
   listOf("class" to "Clases / bono de sesiones","appointment" to "Entrenador personal","unlimited" to "Acceso ilimitado").forEach {(kind,label) ->
    Row {RadioButton(passKind==kind,{passKind=kind});TextButton(onClick={passKind=kind}) {Text(label)}}
   }
   ReperaMetaTextField(caption="Nota para el centro (opcional)",value=note,onValueChange={note=it})
   Text(stringResource(R.string.center_directory_dialogs_el_centro_confirmara_el_bono_solicitado))
   error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
  }},confirmButton={TextButton(enabled=!submitting,onClick={onRequest(org,passKind,note.takeIf {it.isNotBlank()})}) {Text(stringResource(R.string.center_directory_dialogs_enviar_solicitud))}},
  dismissButton={TextButton(onClick={clearSelection()}) {Text(stringResource(R.string.action_cancel))}})}
}
@Composable
internal fun LinkedCenterDialog(org:BusinessCenterStore.Organization,snapshot:BusinessCenterStore.Snapshot?,submitting:Boolean,
 onLeave:(BusinessCenterStore.Organization)->Unit,onClose:()->Unit,sharing:Boolean=false,sharingBusy:Boolean=false,onSharing:(Boolean)->Unit={},error:String?=null) {
 var confirm by remember {mutableStateOf(false)}
 var requestedLeave by remember {mutableStateOf(false)}
 LaunchedEffect(snapshot?.athleteCenterIds) {if(requestedLeave && snapshot!=null && org.id !in snapshot.athleteCenterIds) onClose()}
 AlertDialog(onDismissRequest=onClose,title={Text(org.name)},text={Column(Modifier.verticalScroll(rememberScrollState()),verticalArrangement=Arrangement.spacedBy(10.dp)) {
  Text(org.tagline ?: org.kind, style=MaterialTheme.typography.bodySmall)
  Text(stringResource(R.string.center_directory_dialogs_historial_de_pagos), style=MaterialTheme.typography.titleSmall, fontWeight=FontWeight.SemiBold)
  val passes=snapshot?.passes.orEmpty().filter {it.orgId==org.id}
  if(passes.isEmpty()) Text(stringResource(R.string.plus_hub_tab_todavia_no_hay_pagos_registrados_con), style=MaterialTheme.typography.bodySmall)
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
   val amount=pass.paidAmountCents?.let { String.format(dev.repera.domain.ReperaNumberFormat.displayLocale, "%.2f €", it / 100.0) }
   Text(listOfNotNull(method, amount).joinToString(" · "), style=MaterialTheme.typography.bodySmall)
   (pass.paidAt ?: pass.validFrom)?.let {date ->
    val formatted=runCatching {java.time.Instant.parse(date).atZone(java.time.ZoneId.systemDefault()).toLocalDate().format(reperaDayFormatter)}.getOrDefault(date)
    Text(formatted, style=MaterialTheme.typography.labelSmall)
   }
  }
  Text(stringResource(R.string.plus_hub_tab_historial_de_clases), style=MaterialTheme.typography.titleSmall, fontWeight=FontWeight.SemiBold)
  val past=snapshot?.bookings.orEmpty().filter {it.orgId==org.id}.take(20)
  if(past.isEmpty()) Text(stringResource(R.string.plus_hub_tab_aun_no_has_asistido_ni_reservado), style=MaterialTheme.typography.bodySmall)
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
  TextButton(enabled=!submitting,onClick={confirm=true}) {Text(stringResource(R.string.center_directory_dialogs_desvincularme_como_cliente))}
 }},confirmButton={TextButton(onClick=onClose) {Text(stringResource(R.string.action_close))}})
 if(confirm) AlertDialog(onDismissRequest={confirm=false},title={Text("¿Dejar de ser cliente de ${org.name}?")},
  text={Text(stringResource(R.string.center_directory_dialogs_se_cancelaran_tus_reservas_futuras_y))},
  confirmButton={TextButton(enabled=!submitting,onClick={confirm=false;requestedLeave=true;onLeave(org)}) {Text(stringResource(R.string.center_directory_dialogs_desvincularme))}},
  dismissButton={TextButton(onClick={confirm=false}) {Text(stringResource(R.string.action_cancel))}})
}
