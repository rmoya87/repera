package dev.repera.mobile

import dev.repera.mobile.monetization.LocalSubscriptions
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

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
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp)) {
            Text("Añadir entreno", style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold)
            Text(dayName, fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text("ENTRENO", fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 14.dp, bottom = 4.dp))
            DayPlusRow("＋", "Crear entreno", "Bloques de fuerza y WODs",
                "day_plus_create", onCreateWorkout)
            DayPlusDivider()
            DayPlusRow("★", "Favoritos", favoritesSubtitle,
                "day_plus_favorites", onOpenFavorites)
            DayPlusDivider()
            DayPlusRow("⏱", "Temporizador", "Arriba, abajo o intervalos · reloj digital",
                "day_plus_timer", onOpenTimer)
            DayPlusDivider()
            DayPlusRow("▣", "Escanear pizarra o TV", "Cámara o galería",
                "day_plus_scan", onScanBoard)
            // Caption de cuota gratuita, paridad DayPlusSheet iOS
            // (subscriptions.policy.boardScanUsageCaption; solo plan Gratis).
            LocalSubscriptions.current?.policy?.boardScanUsageCaption?.let { caption ->
                Text(caption, fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 4.dp, top = 2.dp))
            }
            Spacer(modifier = Modifier.padding(bottom = 24.dp))
        }
    }
}

@Composable
private fun DayPlusRow(
    icon: String, title: String, subtitle: String, tag: String, onClick: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth().testTag(tag)
            .clickable(onClick = onClick).padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(icon, fontSize = 20.sp, color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.width(28.dp))
        Column {
            Text(title, fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurface)
            Text(subtitle, fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun DayPlusDivider() {
    HorizontalDivider(modifier = Modifier.padding(start = 52.dp),
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
}
