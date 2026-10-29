package dev.repera.mobile

import dev.repera.mobile.monetization.LocalSubscriptions
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DocumentScanner
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val brandOrange = Color(0xFFFF9F0A)
private val brandYellow = Color(0xFFFFD60A)

/**
 * Menú «＋» de un día concreto del diario (port de DayPlusSheet iOS): alta de
 * entreno suelto con fecha, favoritos, temporizador y escaneo de pizarra.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun DayPlusSheet(
    dayName: String,
    favoriteRoutines: Int,
    favoriteTimers: Int,
    onCreateWorkout: () -> Unit,
    onOpenFavorites: () -> Unit,
    onOpenTimer: () -> Unit,
    onScanBoard: () -> Unit,
    onDismiss: () -> Unit
) {
    val favoritesSubtitle = if (favoriteRoutines + favoriteTimers == 0) {
        "Entrenos y temporizadores habituales"
    } else {
        listOfNotNull(
            if (favoriteRoutines > 0) "$favoriteRoutines entreno" +
                (if (favoriteRoutines == 1) "" else "s") else null,
            if (favoriteTimers > 0) "$favoriteTimers tempo" else null
        ).joinToString(" · ")
    }
    ReperaModalBottomSheet(onDismissRequest = onDismiss) {
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp)) {
            ReperaPageHeader(
                title = "Añadir entreno",
                trailing = {
                    ReperaToolbarGlassIconButton(
                        icon = Icons.Outlined.Close,
                        contentDescription = "Cerrar",
                        onClick = onDismiss,
                        modifier = Modifier.size(44.dp)
                    )
                }
            )
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Column {
                    DayPlusRow(
                        Icons.Outlined.Add,
                        "Crear entreno",
                        "Bloques de fuerza y WODs",
                        MaterialTheme.colorScheme.primary,
                        "day_plus_create",
                        onCreateWorkout
                    )
                    DayPlusDivider()
                    DayPlusRow(
                        Icons.Outlined.Timer,
                        "Temporizador",
                        "Arriba, abajo o intervalos · reloj digital",
                        brandOrange,
                        "day_plus_timer",
                        onOpenTimer
                    )
                    DayPlusDivider()
                    DayPlusRow(
                        Icons.Outlined.DocumentScanner,
                        "Escanear entreno",
                        "Cámara o galería",
                        MaterialTheme.colorScheme.tertiary,
                        "day_plus_scan",
                        onScanBoard
                    )
                    DayPlusDivider()
                    DayPlusRow(
                        Icons.Outlined.StarBorder,
                        "Favoritos",
                        favoritesSubtitle,
                        brandYellow,
                        "day_plus_favorites",
                        onOpenFavorites
                    )
                }
            }
            LocalSubscriptions.current?.policy?.boardScanUsageCaption?.let { caption ->
                Text(
                    caption,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 4.dp, top = 8.dp)
                )
            }
            Spacer(modifier = Modifier.padding(bottom = 24.dp))
        }
    }
}

@Composable
private fun DayPlusRow(
    icon: ImageVector,
    title: String,
    subtitle: String,
    iconTint: Color,
    tag: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .testTag(tag)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = iconTint,
            modifier = Modifier.size(28.dp)
        )
        Spacer(Modifier.width(14.dp))
        Column {
            Text(title, style = MaterialTheme.typography.bodyLarge)
            Text(
                subtitle,
                style = MaterialTheme.typography.bodySmall.copy(fontSize = 12.sp),
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun DayPlusDivider() {
    HorizontalDivider(
        modifier = Modifier.padding(start = 52.dp),
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
    )
}
