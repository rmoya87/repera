package dev.repera.mobile

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.*
import androidx.compose.foundation.layout.Row
import androidx.compose.ui.platform.testTag
import androidx.compose.material3.*
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationManagerCompat

/** Reads real grants; only explicit button taps request a permission. */
@Composable internal fun PermissionSettingsSection(onHealthConnect:()->Unit,onSleepChanged:(Boolean)->Unit = {},onCycleChanged:(Boolean)->Unit = {}) {
    val context=LocalContext.current
    val privateRecovery=remember {PrivateRecoverySettings(context)}
    var sleepEnabled by remember {mutableStateOf(privateRecovery.sleepEnabled())}
    var cycleEnabled by remember {mutableStateOf(privateRecovery.cycleEnabled())}
    var cycleDecided by remember {mutableStateOf(privateRecovery.cycleDecisionMade())}
    var privateError by remember {mutableStateOf<String?>(null)}
    var sleepDecided by remember {mutableStateOf(privateRecovery.sleepDecisionMade())}
    var healthStatus by remember {mutableStateOf("Comprobando")}

    var revision by remember { mutableIntStateOf(0) }
    val owner=androidx.lifecycle.compose.LocalLifecycleOwner.current
    DisposableEffect(owner) {
        val observer=androidx.lifecycle.LifecycleEventObserver { _,event ->
            if(event==androidx.lifecycle.Lifecycle.Event.ON_RESUME) revision++
        }
        owner.lifecycle.addObserver(observer)
        onDispose {owner.lifecycle.removeObserver(observer)}
    }
    LaunchedEffect(revision) {
        healthStatus=runCatching {
            val reader=HealthConnectReader(context)
            if(!reader.available()) "No disponible" else if(reader.hasPermissions()) "Con lecturas autorizadas" else "Sin lecturas autorizadas"
        }.getOrDefault("No se pudo comprobar")
    }
    fun openSettings() {context.startActivity(Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:${context.packageName}")))}
    val location=rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {revision++}
    val notifications=rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {revision++}
    @Suppress("UNUSED_VARIABLE") val observed=revision
    val locationGranted=ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(context,Manifest.permission.ACCESS_COARSE_LOCATION)==PackageManager.PERMISSION_GRANTED
    val notificationsGranted=NotificationManagerCompat.from(context).areNotificationsEnabled()
    Text("Salud y permisos",style=MaterialTheme.typography.titleMedium)
    OutlinedButton(onClick={
        if(Build.VERSION.SDK_INT>=33 && !notificationsGranted) notifications.launch(Manifest.permission.POST_NOTIFICATIONS) else openSettings()
    }) {Text("Notificaciones: ${if(notificationsGranted) "Permitidas" else "No permitidas"}")}
    OutlinedButton(onClick={
        location.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION))
    }) {Text("Ubicación: ${if(locationGranted) "Permitida" else "No permitida"}")}
    Text("Salud: $healthStatus")
    OutlinedButton(onClick=onHealthConnect) {Text("Conectar con Salud")}
    Text("Recuperación privada",style=MaterialTheme.typography.titleMedium)
    Row(verticalAlignment=androidx.compose.ui.Alignment.CenterVertically) {
        Switch(checked=sleepEnabled,onCheckedChange={enabled ->
            runCatching {privateRecovery.setSleep(enabled)}.onSuccess {
                privateError=null;sleepEnabled=enabled;sleepDecided=true;onSleepChanged(enabled)
            }.onFailure {privateError="No se pudo guardar la decisión de sueño"}
        },modifier=androidx.compose.ui.Modifier.testTag("private_sleep_enabled"))
        Text("Analizar descanso (sueño)")
    }
    Row(verticalAlignment=androidx.compose.ui.Alignment.CenterVertically) {
        Switch(checked=cycleEnabled,onCheckedChange={enabled ->
            runCatching {privateRecovery.setCycle(enabled)}.onSuccess {
                privateError=null;cycleEnabled=enabled;cycleDecided=true;onCycleChanged(enabled)
            }.onFailure {privateError="No se pudo guardar la decisión del ciclo"}
        },modifier=androidx.compose.ui.Modifier.testTag("private_cycle_enabled"))
        Text("Seguimiento del ciclo")
    }
    Text(if(cycleDecided) "Decisión del ciclo guardada solo en este dispositivo." else "Ciclo pendiente de tu decisión. No se lee hasta que lo actives.")
    privateError?.let {Text(it,color=MaterialTheme.colorScheme.error)}
    Text(if(sleepDecided) "Decisión guardada solo en este dispositivo. Al desactivar se dejan de leer y mostrar tus noches de sueño."
        else "Pendiente de tu decisión. No leeremos sueño hasta que lo actives.")
    Text("No se incluye en copias, Drive ni datos compartidos con centros.")
    OutlinedButton(onClick=::openSettings) {Text("Abrir Ajustes del sistema")}
}
