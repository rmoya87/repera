package dev.repera.mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.health.connect.client.PermissionController
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import dev.repera.mobile.monetization.PaywallMode
import dev.repera.mobile.monetization.PaywallScreen
import dev.repera.mobile.monetization.SubscriptionManager
import kotlinx.coroutines.launch

/**
 * Wizard obligatorio de primer acceso. Port 1:1 de OnboardingFlowView.swift:
 * signIn → permissions → choosePlan (flowVersion 2) → done.
 * Fila «Ubicación» incluida: la función existe (WorkoutLocationTracker
 * portado: pin del gym + ruta GPS outdoor).
 */
@Composable
fun OnboardingFlow(
    store: OnboardingStore,
    subscriptions: SubscriptionManager,
    isSignedIn: Boolean,
    signInBusy: Boolean,
    signInError: String?,
    onGoogleSignIn: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Misma regla que iOS: con sesión completa el wizard avanza; sin sesión,
    // reconcile no toca el paso (evita pantalla en blanco al reconectar).
    LaunchedEffect(isSignedIn, store.step) {
        if (isSignedIn) store.reconcile(isSignedIn = true)
    }
    // ReperaTheme por si el host de prueba no envuelve la raíz (MainActivity sí).
    ReperaTheme {
        Surface(modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
            when (store.step) {
                OnboardingStep.SignIn, OnboardingStep.Done ->
                    // Done no debería renderizarse (la puerta está fuera); si falta
                    // sesión, iOS vuelve al login — nunca un spinner eterno.
                    OnboardingSignInStep(signInBusy, signInError, onGoogleSignIn)
                OnboardingStep.Permissions -> OnboardingPermissionsStep(store)
                OnboardingStep.ChoosePlan ->
                    PaywallScreen(
                        subscriptions = subscriptions,
                        mode = PaywallMode.ONBOARDING,
                        onContinueFree = { store.finishPrices() },
                        onPurchaseSuccess = { store.finishPrices() }
                    )
            }
        }
    }
}

// MARK: - Sign in

@Composable
private fun OnboardingSignInStep(
    busy: Boolean,
    errorText: String?,
    onGoogleSignIn: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        ReperaMascot(ReperaMascotPose.WELCOME, maxHeight = 220.dp)
        Spacer(Modifier.height(24.dp))
        Text(
            "Bienvenido a Repera",
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(10.dp))
        Text(
            "Todo tu entrenamiento. Cada vez mejor.",
            style = MaterialTheme.typography.headlineSmall,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(10.dp))
        Text(
            "Crea tus rutinas, escanea la pizarra y registra cada serie o WOD. " +
                "Supera tus marcas, sigue tu actividad y recuperación, y entrena " +
                "con tu reloj Wear OS y la ayuda de tu entrenador o la integración MCP.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(24.dp))
        // Botón Google con la marca oficial (paridad OnboardingFlowView iOS):
        // logo G multicolor 20dp, fondo/blanco según tema, borde 1dp y
        // colores de texto de las guías de marca de Google Sign-In.
        val dark = isSystemInDarkTheme()
        val googleBackground = if (dark) Color(0xFF131314) else Color.White
        val googleForeground = if (dark) Color(0xFFE3E3E3) else Color(0xFF1F1F1F)
        val googleBorder = if (dark) Color(0xFF8E918F) else Color(0xFF747775)
        Button(
            onClick = onGoogleSignIn,
            enabled = !busy,
            modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).height(52.dp),
            shape = RoundedCornerShape(12.dp),
            border = BorderStroke(1.dp, googleBorder),
            colors = ButtonDefaults.buttonColors(
                containerColor = googleBackground,
                contentColor = googleForeground
            )
        ) {
            if (busy) {
                CircularProgressIndicator(
                    modifier = Modifier.height(20.dp).width(20.dp),
                    strokeWidth = 2.dp
                )
                Spacer(Modifier.width(10.dp))
            } else {
                Image(
                    painter = painterResource(R.drawable.google_g),
                    contentDescription = null,
                    modifier = Modifier.height(20.dp).width(20.dp)
                )
                Spacer(Modifier.width(10.dp))
            }
            Text("Iniciar sesión con Google", fontWeight = FontWeight.SemiBold)
        }
        if (busy) {
            Spacer(Modifier.height(8.dp))
            Text(
                "Conectando con Google…",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        if (errorText != null) {
            Spacer(Modifier.height(8.dp))
            Text(
                errorText,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center
            )
        }
    }
}

// MARK: - Permissions

@Composable
private fun OnboardingPermissionsStep(store: OnboardingStore) {
    val context = LocalContext.current
    var notificationsGranted by remember { mutableStateOf(notificationsGranted(context)) }
    var healthGranted by remember { mutableStateOf<Boolean?>(null) }
    var locationGranted by remember { mutableStateOf(locationGranted(context)) }
    var showUI by remember { mutableStateOf(false) }

    suspend fun refreshHealth() {
        val reader = HealthConnectReader(context)
        healthGranted = runCatching { reader.hasPermissions() }.getOrDefault(false)
    }

    val notificationLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { notificationsGranted = notificationsGranted(context) }
    val healthLauncher = rememberLauncherForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { granted -> healthGranted = HealthConnectReader.hasReadablePermission(granted) }
    val locationLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { locationGranted = locationGranted(context) }

    // Comprobación inicial: si ya está todo concedido, avanzar sin mostrar
    // la pantalla (iOS evita el flash del paso de permisos).
    LaunchedEffect(Unit) {
        refreshHealth()
        val granted = healthGranted
        if (notificationsGranted && granted == true && locationGranted) {
            store.finishPermissions()
        } else if (granted != null) {
            showUI = true
        }
    }
    // Re-comprobar al volver de Ajustes del sistema.
    val scope = androidx.compose.runtime.rememberCoroutineScope()
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                notificationsGranted = notificationsGranted(context)
                locationGranted = locationGranted(context)
                scope.launch { refreshHealth() }
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    if (!showUI) return

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp)
            .padding(bottom = 28.dp)
    ) {
        Spacer(Modifier.height(4.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            ReperaMascot(ReperaMascotPose.PERMISSIONS, maxHeight = 140.dp)
        }
        Text(
            "Permisos",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(8.dp))
        Text(
            "Puedes activar notificaciones y Salud si los necesitas. Al autorizar " +
                "Salud, eliges qué datos compartir, incluidos sueño y ciclo.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.height(20.dp))

        PermissionRow(
            title = "Notificaciones",
            subtitle = "Aviso cuando termina el descanso",
            icon = Icons.Outlined.Notifications,
            statusText = if (notificationsGranted) "Permitidas" else "Pendiente",
            isDone = notificationsGranted,
            onAllow = {
                if (Build.VERSION.SDK_INT >= 33) {
                    notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                } else {
                    notificationsGranted = true
                }
            }
        )
        Spacer(Modifier.height(12.dp))
        val healthDone = healthGranted == true
        PermissionRow(
            title = "Salud",
            subtitle = "Entrenos, sueño, ciclo y constantes",
            icon = Icons.Outlined.FavoriteBorder,
            statusText = if (healthDone) "Conectado" else "Pendiente",
            isDone = healthDone,
            onAllow = { healthLauncher.launch(HealthConnectReader.permissions) }
        )
        Spacer(Modifier.height(12.dp))
        PermissionRow(
            title = "Ubicación",
            subtitle = "Pin del gym y ruta en entrenos outdoor",
            icon = Icons.Outlined.LocationOn,
            statusText = if (locationGranted) "Permitida" else "Pendiente",
            isDone = locationGranted,
            onAllow = {
                locationLauncher.launch(arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION))
            }
        )

        Spacer(Modifier.height(24.dp))
        Button(
            onClick = { store.finishPermissions() },
            modifier = Modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.medium,
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            )
        ) { Text("Continuar", fontWeight = FontWeight.SemiBold) }
        TextButton(
            onClick = {
                val intent = Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", context.packageName, null)
                )
                context.startActivity(intent)
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                "Abrir Ajustes del sistema",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun PermissionRow(
    title: String,
    subtitle: String,
    icon: ImageVector,
    statusText: String,
    isDone: Boolean,
    onAllow: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.large,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(
                        MaterialTheme.colorScheme.primaryContainer,
                        CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimaryContainer,
                    modifier = Modifier.size(22.dp)
                )
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    statusText,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isDone) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (isDone) {
                Icon(
                    imageVector = Icons.Outlined.CheckCircle,
                    contentDescription = "Hecho",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
            } else {
                TextButton(onClick = onAllow) {
                    Text(
                        "Permitir",
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}

private fun locationGranted(context: Context): Boolean =
    ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
        PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
        PackageManager.PERMISSION_GRANTED

private fun notificationsGranted(context: Context): Boolean =
    Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(
        context, Manifest.permission.POST_NOTIFICATIONS
    ) == PackageManager.PERMISSION_GRANTED
