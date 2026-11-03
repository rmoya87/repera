package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.LiveHeartRateZones

/**
 * Segmented FC indicator for Comenzar. Five solid colors, no gradient.
 * Only measured values may select/expand a zone.
 */
@Composable
internal fun LiveHeartRateZoneBar(
    bpm: Int?,
    modifier: Modifier = Modifier
) {
    val zone = LiveHeartRateZones.zone(bpm)
    val colors = listOf(
        Color(0xFF408CFF), Color(0xFF33D966), Color(0xFFF2D926),
        Color(0xFFFF8C1A), Color(0xFFF23333)
    )
    val announcement = if (zone != null) {
        "Frecuencia cardíaca ${bpm ?: 0} pulsaciones, zona $zone de 5"
    } else {
        "Frecuencia cardíaca no disponible"
    }
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clearAndSetSemantics { contentDescription = announcement }
            .testTag("live_heart_zone_bar"),
        verticalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().height(44.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            colors.forEachIndexed { index, color ->
                val level = index + 1
                val active = zone == level
                Box(
                    modifier = Modifier
                        .weight(if (active) 3f else 1f)
                        .height(if (active) 42.dp else 12.dp)
                        .clip(RoundedCornerShape(24.dp))
                        .background(color.copy(alpha = if (zone == null) 0.30f else if (active) 1f else 0.38f)),
                    contentAlignment = Alignment.Center
                ) {
                    if (active) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "Zona $level",
                                color = Color.Black,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                maxLines = 1
                            )
                            Text(
                                text = "$bpm lpm",
                                color = Color.Black,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                maxLines = 1
                            )
                        }
                    }
                }
            }
        }
        if (zone == null) {
            Text(
                "Sin lectura de FC",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
