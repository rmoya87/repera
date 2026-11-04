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
import androidx.annotation.StringRes
import androidx.compose.foundation.selection.selectable
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics

/** Categorías del hub Progreso — iconos propios, sin anillos Activity ni set Salud. */
internal enum class ProgressCategory(
    val title: String,
    val icon: ImageVector,
    val accent: Color,
    @StringRes val titleRes: Int
) {
    TRAINING("Entreno", Icons.Outlined.Bolt, ReperaAccents.training, R.string.progress_category_training),
    STRENGTH("Fuerza", Icons.Outlined.FitnessCenter, ReperaAccents.strength, R.string.progress_category_strength),
    FITNESS("Forma física", Icons.Outlined.DirectionsWalk, ReperaAccents.fitness, R.string.progress_category_fitness),
    HEART("Corazón", Icons.Outlined.MonitorHeart, ReperaAccents.heart, R.string.progress_category_heart),
    RECOVERY("Recuperación", Icons.Outlined.Eco, ReperaAccents.recovery, R.string.progress_category_recovery),
    SPORTS("Deportes", Icons.Outlined.Flag, ReperaAccents.sports, R.string.progress_category_sports);
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
    val bg = if (selected) brandGreen else MaterialTheme.colorScheme.surface.copy(alpha = 0.55f)
    val fg = if (selected) Color.Black else MaterialTheme.colorScheme.onSurface
    val secondary = if (selected) Color.Black.copy(alpha = 0.72f) else MaterialTheme.colorScheme.onSurfaceVariant
    val iconTint = if (selected) Color.Black else category.accent
    Column(
        modifier = Modifier
            .widthIn(min = 88.dp)
            .clip(shape)
            .background(bg, shape)
            .selectable(selected = selected, role = Role.Tab, onClick = onClick)
            .semantics(mergeDescendants = true) {}
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
                stringResource(category.titleRes),
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
