package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/** Bloque agrupado en Play (paridad WorkoutView.workoutBlocks iOS). */
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
                title = active.blockTitleFor(entry),
                kind = entry.blockKind.ifBlank { "strength" },
                indexes = listOf(entry.index)
            )
        } else {
            groups[id] = existing.copy(indexes = existing.indexes + entry.index)
        }
    }
    return groups.values.toList()
}

private fun ActiveWorkout.blockTitleFor(entry: ActiveExerciseNavigation): String {
    if (entry.blockKind == "wod") {
        return wod?.title?.takeIf { it.isNotBlank() } ?: "WOD"
    }
    return "Bloque"
}

/**
 * Cabecera de bloque en Play: título · círculo timer · círculo ⋯
 * (misma maqueta que crear/editar + timer a la izquierda de los puntos).
 */
@Composable
internal fun PlayBlockHeaderCard(
    title: String,
    subtitle: String?,
    exerciseLines: List<String>,
    current: Boolean,
    busy: Boolean,
    onTimer: () -> Unit,
    onReorder: () -> Unit,
    onSelectExercise: (Int) -> Unit,
    exerciseIndexes: List<Int>,
    modifier: Modifier = Modifier
) {
    var menuOpen by remember { mutableStateOf(false) }
    ReperaCard(
        modifier = modifier
            .fillMaxWidth()
            .testTag("play_block_card")
    ) {
        Column(
            Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = if (current) brandGreen else MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.weight(1f)
                )
                PlayCircleIconButton(
                    icon = Icons.Outlined.Timer,
                    contentDescription = "Temporizador del bloque",
                    enabled = !busy,
                    testTag = "play_block_timer",
                    onClick = onTimer
                )
                Spacer(Modifier.size(8.dp))
                Box {
                    PlayCircleIconButton(
                        icon = Icons.Outlined.MoreHoriz,
                        contentDescription = "Opciones del bloque",
                        enabled = !busy,
                        testTag = "play_block_menu",
                        onClick = { menuOpen = true }
                    )
                    DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                        DropdownMenuItem(
                            text = { Text("Reordenar") },
                            onClick = { menuOpen = false; onReorder() }
                        )
                    }
                }
            }
            if (!subtitle.isNullOrBlank()) {
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            exerciseLines.forEachIndexed { i, line ->
                HorizontalDivider(
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
                )
                val idx = exerciseIndexes.getOrNull(i)
                Text(
                    line,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier
                        .fillMaxWidth()
                        .then(
                            if (idx != null) Modifier.testTag("play_block_ex_$idx")
                            else Modifier
                        )
                        .padding(vertical = 4.dp)
                )
            }
        }
    }
}

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
