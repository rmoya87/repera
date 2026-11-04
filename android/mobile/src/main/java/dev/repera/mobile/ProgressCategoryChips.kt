package dev.repera.mobile

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
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
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
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
            .padding(horizontal = 4.dp, vertical = 2.dp)
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
    val shape = RoundedCornerShape(14.dp)
    val borderColor = if (selected) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.outlineVariant
    }
    Surface(
        shape = shape,
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .width(96.dp)
            .border(if (selected) 2.dp else 1.dp, borderColor, shape)
            .clickable(onClick = onClick)
            .testTag("progress_chip_${category.name}")
    ) {
        Column(
            Modifier.padding(horizontal = 10.dp, vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                imageVector = category.icon,
                contentDescription = null,
                tint = category.accent,
                modifier = Modifier.padding(bottom = 2.dp)
            )
            Text(
                value,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                maxLines = 1
            )
            Text(
                category.title,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1
            )
        }
    }
}
