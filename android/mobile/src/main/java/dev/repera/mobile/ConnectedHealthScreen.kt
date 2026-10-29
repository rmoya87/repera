package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

/**
 * Paridad iOS `ConnectedHealthSettingsView` («Salud conectada»):
 * página propia con fila Health Connect + privacidad; el permiso del sistema
 * se pide al tocar la fila (no al entrar en Ajustes).
 */
@Composable
internal fun ConnectedHealthScreen(
    healthAccess: HealthAccessState,
    todayKcal: Double?,
    busy: Boolean,
    onBack: () -> Unit,
    onManagePermissions: () -> Unit
) {
    val scroll = rememberScrollState()
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(scroll)
            .padding(16.dp)
            .testTag("connected_health_screen"),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        IconButton(
            onClick = onBack,
            enabled = !busy,
            modifier = Modifier
                .size(44.dp)
                .background(MaterialTheme.colorScheme.surfaceVariant, CircleShape)
                .testTag("health_back")
        ) {
            Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Volver")
        }
        ReperaPageHeader(title = "Salud conectada")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                SettingsListRow(
                    title = "Health Connect",
                    trailing = when (healthAccess) {
                        HealthAccessState.GRANTED -> "Conectada"
                        HealthAccessState.NOT_GRANTED -> "No concedida"
                        HealthAccessState.UNAVAILABLE -> "No disponible"
                        HealthAccessState.UNKNOWN -> null
                    },
                    leadingIcon = Icons.Outlined.FavoriteBorder,
                    enabled = !busy && healthAccess != HealthAccessState.UNAVAILABLE,
                    onClick = onManagePermissions
                )
                if (todayKcal != null && todayKcal.isFinite() && todayKcal > 0) {
                    SettingsCardDivider()
                    SettingsListRow(
                        title = "kcal hoy",
                        trailing = "${todayKcal.toInt()}",
                        showChevron = false,
                        enabled = false,
                        onClick = null
                    )
                }
                if (busy) {
                    SettingsCardDivider()
                    CircularProgressIndicator(
                        modifier = Modifier
                            .padding(16.dp)
                            .size(22.dp),
                        strokeWidth = 2.dp
                    )
                }
            }
        }
        ReperaSectionTitle("Privacidad", uppercase = false)
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                SettingsListRow(
                    title = "Tus datos de salud solo en tu móvil",
                    leadingIcon = Icons.Outlined.PhoneAndroid,
                    showChevron = false,
                    enabled = false,
                    onClick = null
                )
                SettingsCardDivider()
                SettingsListRow(
                    title = "Sin compartir el ciclo ni el sueño",
                    leadingIcon = Icons.Outlined.Lock,
                    showChevron = false,
                    enabled = false,
                    onClick = null
                )
            }
        }
        Text(
            "Para cambiar permisos ya decididos: Ajustes del sistema → Apps → Repera → Permisos / Health Connect.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
        )
    }
}
