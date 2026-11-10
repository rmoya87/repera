package dev.repera.mobile

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Popup
import androidx.compose.ui.window.PopupProperties
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.delay

internal enum class ForegroundNotificationDecision { START, REQUEST, SETTINGS }

/** A first install also reports rationale=false; do not treat it as permanently denied. */
internal fun foregroundNotificationDecision(
    sdk: Int, granted: Boolean, requests: Int, rationale: Boolean
): ForegroundNotificationDecision = when {
    sdk < 33 || granted -> ForegroundNotificationDecision.START
    requests >= 2 && !rationale -> ForegroundNotificationDecision.SETTINGS
    else -> ForegroundNotificationDecision.REQUEST
}

private fun Context.permissionActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.permissionActivity()
    else -> null
}

/**
 * Request only on a user initiated start, and always continue the requested activity.
 * A denial hides the drawer notification on Android 13+, not the foreground service itself.
 */
@Composable
internal fun rememberForegroundNotificationPermission(): ((() -> Unit) -> Unit) {
    val context = LocalContext.current
    val prefs = remember(context) {
        context.getSharedPreferences("repera.fgs.notification.permission", Context.MODE_PRIVATE)
    }
    var showAdvice by remember { mutableStateOf(false) }
    var pending by remember { mutableStateOf<(() -> Unit)?>(null) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        val continuation = pending
        pending = null
        continuation?.invoke()
        if (!granted) showAdvice = true
    }

    LaunchedEffect(showAdvice) {
        if (showAdvice) {
            delay(8_000)
            showAdvice = false
        }
    }
    if (showAdvice) {
        Popup(
            alignment = Alignment.BottomCenter,
            properties = PopupProperties(focusable = false)
        ) {
            Surface(
                modifier = androidx.compose.ui.Modifier.padding(16.dp),
                shape = MaterialTheme.shapes.medium,
                shadowElevation = 6.dp,
                tonalElevation = 3.dp
            ) {
                Column(modifier = androidx.compose.ui.Modifier.padding(16.dp)) {
                    Text("Sin notificaciones no verás los controles en la barra ni en la pantalla de bloqueo.")
                    TextButton(
                        modifier = androidx.compose.ui.Modifier.align(Alignment.End),
                        onClick = {
                            showAdvice = false
                            context.startActivity(
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                    Uri.parse("package:${context.packageName}"))
                            )
                        }
                    ) { Text("Abrir ajustes") }
                }
            }
        }
    }
    return { start ->
        val granted = Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        val activity = context.permissionActivity()
        val rationale = activity?.let {
            ActivityCompat.shouldShowRequestPermissionRationale(
                it, Manifest.permission.POST_NOTIFICATIONS)
        } ?: false
        val count = prefs.getInt("requests", 0)
        when (foregroundNotificationDecision(Build.VERSION.SDK_INT, granted, count, rationale)) {
            ForegroundNotificationDecision.START -> start()
            ForegroundNotificationDecision.SETTINGS -> {
                start()
                showAdvice = true
            }
            ForegroundNotificationDecision.REQUEST -> {
                pending = start
                prefs.edit().putInt("requests", (count + 1).coerceAtMost(2)).apply()
                launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }
}
