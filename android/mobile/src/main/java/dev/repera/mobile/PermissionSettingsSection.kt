package dev.repera.mobile

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.*
import androidx.compose.material3.*
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationManagerCompat

/** Reads real grants; only explicit button taps request a permission. */
@Composable internal fun PermissionSettingsSection(onHealthConnect:()->Unit) {
    val context=LocalContext.current
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
            if(!reader.available()) "No disponible" else if(reader.hasPermissions()) "Autorizada" else "Sin autorización completa"
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
    OutlinedButton(onClick=::openSettings) {Text("Abrir Ajustes del sistema")}
}
