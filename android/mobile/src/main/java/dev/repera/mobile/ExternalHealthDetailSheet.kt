package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.time.*
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag

@OptIn(ExperimentalMaterial3Api::class)
@Composable internal fun ExternalHealthDetailSheet(entry:ExternalHealthHistoryEntry,
 provider:suspend(ExternalHealthHistoryEntry)->ExternalHealthDetail?,
 ownerKey:String = "",
 routeReader:(suspend (String)->ExternalRouteRead)? = null,
 onConsentLaunch:((String)->Unit)? = null,
 onClose:()->Unit) {
 var loading by remember(entry.id) {mutableStateOf(true)}
 var detail by remember(entry.id) {mutableStateOf<ExternalHealthDetail?>(null)}
 LaunchedEffect(entry.id) {detail=runCatching {provider(entry)}.getOrNull();loading=false}
 // Ruta GPS de la fuente externa (paridad 6826b9a7): lectura pasiva; el
 // consentimiento por sesion lo lanza el usuario con el boton, nunca solo.
 val ctx=LocalContext.current
 val effectiveRouteReader=routeReader ?: ({ id:String -> HealthConnectReader(ctx).readExternalRoute(id) })
 // ownerKey (cuenta vigente) invalida lectura y consentimiento: si cambia el
 // usuario, todo lo pendiente de la cuenta anterior se descarta.
 var routeRead by remember(entry.id, ownerKey) {mutableStateOf<ExternalRouteRead?>(null)}
 LaunchedEffect(entry.id, ownerKey) {routeRead=runCatching {effectiveRouteReader(entry.id)}.getOrNull()}
 // Guardia de identidad: la ruta consentida solo se pinta si el registro que
 // la pidio sigue siendo el mostrado; si la hoja cambio de entrada (o se
 // recompuso con otra sesion) mientras el sistema mostraba el dialogo, la ruta
 // se descarta, nunca se pinta sobre otra sesion.
 var consentRequestedFor by remember(entry.id) {mutableStateOf<String?>(null)}
 val consentLauncher=androidx.activity.compose.rememberLauncherForActivityResult(
  androidx.health.connect.client.contracts.ExerciseRouteRequestContract()) { route:androidx.health.connect.client.records.ExerciseRoute? ->
  // Cancelar NO es error: sin ruta nueva se conserva el estado previo (el
  // boton sigue disponible); nunca se sustituye por una ruta anterior.
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
      RouteMapView(points=presented.points,isInteractive=interactive,modifier=mapModifier)
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
