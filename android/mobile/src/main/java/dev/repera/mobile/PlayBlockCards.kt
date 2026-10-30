package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

/** Bloque agrupado en Play (navegación por blockId). */
internal data class PlayBlockGroup(
    val blockId: String,
    val title: String,
    val kind: String,
    val indexes: List<Int>
)

internal fun playBlockGroups(active: ActiveWorkout): List<PlayBlockGroup> {
    val groups = linkedMapOf<String, PlayBlockGroup>()
    active.navigationEntries.forEach { entry ->
        val id = entry.blockId.ifBlank { "ex-${entry.index}" }
        val existing = groups[id]
        if (existing == null) {
            groups[id] = PlayBlockGroup(
                blockId = id,
                title = if (entry.blockKind == "wod") {
                    active.wod?.title?.takeIf { it.isNotBlank() } ?: "WOD"
                } else {
                    "Bloque"
                },
                kind = entry.blockKind.ifBlank { "strength" },
                indexes = listOf(entry.index)
            )
        } else {
            groups[id] = existing.copy(indexes = existing.indexes + entry.index)
        }
    }
    return groups.values.toList()
}

/** Botón circular outline (timer / ⋯) alineado con Crear/Editar. */
@Composable
internal fun PlayCircleIconButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    testTag: String = ""
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        color = Color.White,
        border = BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.85f)
        ),
        modifier = modifier
            .size(34.dp)
            .then(if (testTag.isNotEmpty()) Modifier.testTag(testTag) else Modifier)
    ) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Icon(
                icon,
                contentDescription = contentDescription,
                modifier = Modifier.size(18.dp),
                tint = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}
