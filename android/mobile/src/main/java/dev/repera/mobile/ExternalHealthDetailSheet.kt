package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.time.*
import dev.repera.domain.AdaptiveRoutePace
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag

@OptIn(ExperimentalMaterial3Api::class)
@Composable internal fun ExternalHealthDetailSheet(entry:ExternalHealthHistoryEntry,
 provider:suspend(ExternalHealthHistoryEntry)->ExternalHealthDetail?,
 ownerKey:String = "",
 routeReader:(suspend (String)->ExternalRouteRead)? = null,
 onConsentLaunch:((String)->Unit)? = null,
 onClose:()->Unit) {
 val ctx=LocalContext.current
 // Each sheet instance binds owner + record + durable login revision. Closing
 // invalidates the instance even if a non-cooperative provider returns later.
 val revision=SessionStore(ctx).identityRevision()
 val readGate=remember(ownerKey,entry.id,revision) {
  ExternalHealthReadGate(ownerKey,entry.id,revision)
 }
 DisposableEffect(readGate) {onDispose {readGate.invalidate()}}
 var loading by remember(readGate) {mutableStateOf(true)}
 var detail by remember(readGate) {mutableStateOf<ExternalHealthDetail?>(null)}
 LaunchedEffect(readGate) {
  val result=runCatching {provider(entry)}.getOrNull()
  if(readGate.accepts(ownerKey,entry.id,SessionStore(ctx).identityRevision())) {
   detail=result;loading=false
  }
 }
 val effectiveRouteReader=routeReader ?: ({ id:String -> HealthConnectReader(ctx).readExternalRoute(id) })
 var routeRead by remember(readGate) {mutableStateOf<ExternalRouteRead?>(null)}
 LaunchedEffect(readGate) {
  val result=runCatching {effectiveRouteReader(entry.id)}.getOrNull()
  if(readGate.accepts(ownerKey,entry.id,SessionStore(ctx).identityRevision())) routeRead=result
 }
 var consentRequestedFor by remember(readGate) {mutableStateOf<String?>(null)}
 val consentLauncher=androidx.activity.compose.rememberLauncherForActivityResult(
  androidx.health.connect.client.contracts.ExerciseRouteRequestContract()) { route:androidx.health.connect.client.records.ExerciseRoute? ->
  // Cancelar NO es error: sin ruta nueva se conserva el estado previo (el
  // boton sigue disponible); nunca se sustituye por una ruta anterior.
  if(readGate.accepts(ownerKey,entry.id,SessionStore(ctx).identityRevision()))
   ExternalRouteSheetModel.applyConsentResult(consentRequestedFor,
   ExternalRouteSheetModel.consentKey(ownerKey, entry.id),
   route?.toWorkoutRoutePoints())?.let { routeRead = it }
  consentRequestedFor=null
 }
 ModalBottomSheet(onDismissRequest=onClose) {
  ExternalHealthDetailColumn(entry,detail,loading,routeRead,
   onConsentLaunch ?: {id:String -> consentLauncher.launch(id)},
   consentRequestedFor,{consentRequestedFor=ExternalRouteSheetModel.consentKey(ownerKey,it)},onClose)
 }
}

/** Contenido de la hoja, separado del Modal para renders/tests headless. */
@Composable internal fun ExternalHealthDetailColumn(
 entry:ExternalHealthHistoryEntry,
 detail:ExternalHealthDetail?,
 loading:Boolean,
 routeRead:ExternalRouteRead?,
 onConsentLaunch:(String)->Unit,
 consentRequestedFor:String?,
 onConsentRequested:(String)->Unit,
 onClose:()->Unit) {
  Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(20.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
   Row(horizontalArrangement=Arrangement.spacedBy(10.dp),verticalAlignment=androidx.compose.ui.Alignment.CenterVertically) {
    ExternalHealthActivityIcon(entry.exerciseTypeKey)
    Text(entry.title,style=MaterialTheme.typography.titleLarge)
   }
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
   when(val presented=ExternalRouteSheetModel.present(routeRead)) {
    is ExternalRouteSheetModel.State.Shown -> {
     Text("Recorrido GPS de la fuente",style=MaterialTheme.typography.titleSmall)
     RouteMapTapTarget(label="Ampliar recorrido de Salud",
      modifier=Modifier.fillMaxWidth().height(200.dp)) { interactive,mapModifier ->
      RouteMapView(points=presented.points,isInteractive=interactive,modifier=mapModifier,
       paceMode=AdaptiveRoutePace.modeForSport(entry.exerciseTypeKey))
     }
    }
    ExternalRouteSheetModel.State.ConsentNeeded -> {
     TextButton(modifier=Modifier.testTag("external_route_consent"),
      onClick={onConsentRequested(entry.id)
       ;onConsentLaunch(entry.id)}) {
      Text("Ver recorrido GPS (permiso de Salud por sesión)")
     }
    }
    else -> {}
   }
   TextButton(onClick=onClose) {Text("Cerrar")}
   Spacer(Modifier.height(20.dp))
  }
}
