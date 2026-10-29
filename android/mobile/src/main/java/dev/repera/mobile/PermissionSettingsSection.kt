package dev.repera.mobile

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/** Reads real grants; only explicit button taps request a permission. */
@Composable internal fun PermissionSettingsSection(
    onHealthConnect: () -> Unit,
    onSleepChanged: (Boolean) -> Unit = {},
    onCycleChanged: (Boolean) -> Unit = {}
) {
    val context = LocalContext.current
    val privateRecovery = remember { PrivateRecoverySettings(context) }
    var sleepEnabled by remember { mutableStateOf(privateRecovery.sleepEnabled()) }
    var cycleEnabled by remember { mutableStateOf(privateRecovery.cycleEnabled()) }
    var cycleDecided by remember { mutableStateOf(privateRecovery.cycleDecisionMade()) }
    var privateError by remember { mutableStateOf<String?>(null) }
    var sleepDecided by remember { mutableStateOf(privateRecovery.sleepDecisionMade()) }
    var healthStatus by remember { mutableStateOf("Comprobando") }

    var revision by remember { mutableIntStateOf(0) }
    val owner = androidx.lifecycle.compose.LocalLifecycleOwner.current
    DisposableEffect(owner) {
        val observer = androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_RESUME) revision++
        }
        owner.lifecycle.addObserver(observer)
        onDispose { owner.lifecycle.removeObserver(observer) }
    }
    LaunchedEffect(revision) {
        healthStatus = runCatching {
            val reader = HealthConnectReader(context)
            if (!reader.available()) "No disponible"
            else if (reader.hasPermissions()) "Con lecturas autorizadas"
            else "Sin lecturas autorizadas"
        }.getOrDefault("No se pudo comprobar")
    }
    fun openSettings() {
        context.startActivity(
            Intent(
                android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${context.packageName}")
            )
        )
    }
    val location = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { revision++ }
    val notifications = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { revision++ }
    @Suppress("UNUSED_VARIABLE") val observed = revision
    val locationGranted =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    val notificationsGranted = NotificationManagerCompat.from(context).areNotificationsEnabled()

    PermissionSettingsRow(
        icon = Icons.Outlined.Notifications,
        title = "Notificaciones",
        status = if (notificationsGranted) "Permitidas" else "No permitidas",
        actionLabel = if (notificationsGranted) "Gestionar" else "Permitir",
        onAction = {
            if (Build.VERSION.SDK_INT >= 33 && !notificationsGranted) {
                notifications.launch(Manifest.permission.POST_NOTIFICATIONS)
            } else openSettings()
        }
    )
    Spacer(Modifier.height(8.dp))
    PermissionSettingsRow(
        icon = Icons.Outlined.LocationOn,
        title = "Ubicación",
        status = if (locationGranted) "Permitida" else "No permitida",
        actionLabel = if (locationGranted) "Gestionar" else "Permitir",
        onAction = {
            location.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        }
    )
    Spacer(Modifier.height(8.dp))
    PermissionSettingsRow(
        icon = Icons.Outlined.FavoriteBorder,
        title = "Health Connect",
        status = healthStatus,
        actionLabel = "Conectar con Salud",
        onAction = onHealthConnect
    )

    Spacer(Modifier.height(16.dp))
    ReperaSectionTitle("Recuperación privada")
    Spacer(Modifier.height(4.dp))
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Switch(
                    checked = sleepEnabled,
                    onCheckedChange = { enabled ->
                        runCatching { privateRecovery.setSleep(enabled) }.onSuccess {
                            privateError = null
                            sleepEnabled = enabled
                            sleepDecided = true
                            onSleepChanged(enabled)
                        }.onFailure {
                            privateError = "No se pudo guardar la decisión de sueño"
                        }
                    },
                    colors = reperaSwitchColors(),
                    modifier = Modifier.testTag("private_sleep_enabled")
                )
                Spacer(Modifier.width(12.dp))
                Text("Analizar descanso (sueño)", style = MaterialTheme.typography.bodyLarge)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Switch(
                    checked = cycleEnabled,
                    onCheckedChange = { enabled ->
                        runCatching { privateRecovery.setCycle(enabled) }.onSuccess {
                            privateError = null
                            cycleEnabled = enabled
                            cycleDecided = true
                            onCycleChanged(enabled)
                        }.onFailure {
                            privateError = "No se pudo guardar la decisión del ciclo"
                        }
                    },
                    colors = reperaSwitchColors(),
                    modifier = Modifier.testTag("private_cycle_enabled")
                )
                Spacer(Modifier.width(12.dp))
                Text("Seguimiento del ciclo", style = MaterialTheme.typography.bodyLarge)
            }
            Text(
                if (cycleDecided) "Decisión del ciclo guardada solo en este dispositivo."
                else "Ciclo pendiente de tu decisión. No se lee hasta que lo actives.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            privateError?.let {
                Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            }
            Text(
                if (sleepDecided) {
                    "Decisión guardada solo en este dispositivo. Al desactivar se dejan de leer y mostrar tus noches de sueño."
                } else {
                    "Pendiente de tu decisión. No leeremos sueño hasta que lo actives."
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                "No se incluye en copias, Drive ni datos compartidos con centros.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
    Spacer(Modifier.height(12.dp))
    OutlinedButton(onClick = ::openSettings, modifier = Modifier.fillMaxWidth()) {
        Icon(Icons.Outlined.Settings, contentDescription = null, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(8.dp))
        Text("Abrir Ajustes del sistema")
    }
}

@Composable
private fun PermissionSettingsRow(
    icon: ImageVector,
    title: String,
    status: String,
    actionLabel: String,
    onAction: () -> Unit
) {
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimaryContainer,
                    modifier = Modifier.size(20.dp)
                )
            }
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                Text(
                    status,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            TextButton(onClick = onAction) {
                Text(
                    actionLabel,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}
