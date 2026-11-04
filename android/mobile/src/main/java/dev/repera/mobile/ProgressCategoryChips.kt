package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material.icons.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.Eco
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.MonitorHeart
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/** Categorías del hub Progreso — iconos propios, sin anillos Activity ni set Salud. */
internal enum class ProgressCategory(
    val title: String,
    val icon: ImageVector,
    val accent: Color
) {
    TRAINING("Entreno", Icons.Outlined.Bolt, Color(0xFF30D158)),
    STRENGTH("Fuerza", Icons.Outlined.FitnessCenter, Color(0xFFFF9500)),
    FITNESS("Forma física", Icons.Outlined.DirectionsWalk, Color(0xFF5AC8FA)),
    HEART("Corazón", Icons.Outlined.MonitorHeart, Color(0xFFFF453A)),
    RECOVERY("Recuperación", Icons.Outlined.Eco, Color(0xFF33C6B8)),
    SPORTS("Deportes", Icons.Outlined.Flag, Color(0xFF8C73F2));
}

private val progressChipGreen = Color(0xFF30D158)

@Composable
internal fun ProgressCategoryChipBar(
    selected: ProgressCategory,
    glanceValue: (ProgressCategory) -> String,
    onSelected: (ProgressCategory) -> Unit,
    modifier: Modifier = Modifier
) {
    val scroll = rememberScrollState()
    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(scroll)
            .padding(horizontal = 4.dp, vertical = 4.dp)
            .testTag("progress_category_chips"),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        ProgressCategory.entries.forEach { category ->
            ProgressCategoryChip(
                category = category,
                value = glanceValue(category),
                selected = selected == category,
                onClick = { onSelected(category) }
            )
        }
    }
}

@Composable
private fun ProgressCategoryChip(
    category: ProgressCategory,
    value: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    val shape = RoundedCornerShape(16.dp)
    val bg = if (selected) progressChipGreen else MaterialTheme.colorScheme.surface.copy(alpha = 0.55f)
    val fg = if (selected) Color.Black else MaterialTheme.colorScheme.onSurface
    val secondary = if (selected) Color.Black.copy(alpha = 0.72f) else MaterialTheme.colorScheme.onSurfaceVariant
    val iconTint = if (selected) Color.Black else category.accent
    Column(
        modifier = Modifier
            .widthIn(min = 88.dp)
            .clip(shape)
            .background(bg, shape)
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 10.dp)
            .testTag("progress_chip_${category.name}"),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = category.icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.padding(0.dp)
            )
            Text(
                category.title,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold,
                color = secondary,
                maxLines = 1
            )
        }
        Text(
            value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = fg,
            maxLines = 1
        )
    }
}
