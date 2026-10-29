package dev.repera.mobile

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DragHandle
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Hoja «Reordenar» alineada con iOS post-#151: jerarquía Bloque→ejercicios,
 * títulos `ReperaSectionTitle` (= OGCardSectionTitle) y gaps de inserción.
 */
@Composable
internal fun PlanReorderSheet(
    blocks: SnapshotStateList<BlockDraftUi>,
    nameById: Map<String, String>,
    onDone: () -> Unit
) {
    val scroll = rememberScrollState()
    val blockHeights = remember { mutableStateMapOf<Int, Int>() }
    ProvideScrollDragAutoScroll(scroll) {
        Column(
            Modifier
                .fillMaxWidth()
                .verticalScroll(scroll)
                .padding(horizontal = 16.dp)
                .padding(bottom = 24.dp)
                .testTag("plan_reorder_sheet")
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "Reordenar",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                TextButton(onClick = onDone) { Text("Listo") }
                IconButton(onClick = onDone) {
                    Icon(Icons.Outlined.Close, contentDescription = "Cerrar")
                }
            }
            ReperaSectionTitle("Orden de bloques")
            ReorderInsertionGap(visible = false)
            blocks.forEachIndexed { index, block ->
                DragReorderItem(
                    index = index,
                    heights = blockHeights,
                    count = blocks.size,
                    onDrop = { _, t ->
                        if (t != index && t in blocks.indices) {
                            val moved = blocks.removeAt(index); blocks.add(t, moved)
                        }
                    },
                    onMoveTo = { t ->
                        if (t != index && t in blocks.indices) {
                            val moved = blocks.removeAt(index); blocks.add(t, moved)
                        }
                    }
                ) { handle ->
                    ReorderBlockCard(
                        position = index,
                        title = block.title.ifBlank { "Bloque ${index + 1}" },
                        subtitle = blockFormatSubtitle(block),
                        handle = handle
                    )
                }
                ReorderInsertionGap(visible = false)
            }

            blocks.forEachIndexed { blockIndex, block ->
                ReperaSectionTitle(block.title.ifBlank { "Bloque ${blockIndex + 1}" })
                val entryHeights = remember(block) { mutableStateMapOf<Int, Int>() }
                ReorderInsertionGap(visible = false)
                block.entries.forEachIndexed { entryIndex, entry ->
                    DragReorderItem(
                        index = entryIndex,
                        heights = entryHeights,
                        count = block.entries.size,
                        onDrop = { _, t ->
                            if (t != entryIndex && t in block.entries.indices) {
                                val moved = block.entries.removeAt(entryIndex)
                                block.entries.add(t, moved)
                            }
                        },
                        onMoveTo = { t ->
                            if (t != entryIndex && t in block.entries.indices) {
                                val moved = block.entries.removeAt(entryIndex)
                                block.entries.add(t, moved)
                            }
                        }
                    ) { handle ->
                        ReorderExerciseCard(
                            name = entryDisplayName(entry, nameById),
                            handle = handle
                        )
                    }
                    ReorderInsertionGap(visible = false)
                }
                // Mover ejercicio al final de otro bloque vía menú accesible ya
                // existe en el editor; aquí el gap final marca la zona iOS «Soltar».
                if (block.entries.isEmpty()) {
                    ReorderInsertionGap(visible = true, label = "Vacío · soltar aquí")
                }
            }
        }
    }
}

@Composable
internal fun ReorderInsertionGap(visible: Boolean, label: String = "Soltar aquí") {
    Box(
        Modifier
            .fillMaxWidth()
            .height(if (visible) 36.dp else 14.dp)
            .animateContentSize()
            .then(
                if (visible) Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(brandGreen.copy(alpha = 0.28f))
                else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        if (visible) {
            Text(
                label,
                style = MaterialTheme.typography.labelMedium,
                color = brandGreen,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
private fun ReorderBlockCard(
    position: Int,
    title: String,
    subtitle: String,
    handle: Modifier
) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp,
        modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp)
    ) {
        Row(
            Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                Modifier
                    .size(34.dp)
                    .clip(CircleShape)
                    .background(brandGreen.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "${position + 1}",
                    color = brandGreen,
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.labelLarge
                )
            }
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(subtitle, style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Icon(
                Icons.Outlined.DragHandle,
                contentDescription = "Reordenar bloque",
                modifier = handle.testTag("reorder_block_drag"),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ReorderExerciseCard(name: String, handle: Modifier) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp,
        modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp)
    ) {
        Row(
            Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(name, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
            Spacer(Modifier.width(8.dp))
            Icon(
                Icons.Outlined.DragHandle,
                contentDescription = "Reordenar ejercicio",
                modifier = handle.testTag("reorder_entry_drag"),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

private fun blockFormatSubtitle(block: BlockDraftUi): String = when (block.format) {
    "strength" -> "Fuerza"
    "amrap" -> "AMRAP"
    "emom" -> "EMOM"
    "fortime" -> "For Time"
    "tabata" -> "Tabata"
    else -> block.format.ifBlank { "Libre" }
}

private fun entryDisplayName(entry: EntryUi, nameById: Map<String, String>): String {
    val rest = entry.sourceJson?.let {
        runCatching { org.json.JSONObject(it).optBoolean("isRest") }.getOrNull()
    } == true
    if (rest || entry.exerciseId.isBlank() && entry.name.equals("Descanso", ignoreCase = true))
        return "Descanso"
    val raw = nameById[entry.exerciseId] ?: entry.name.ifBlank { "Ejercicio" }
    val sport = entry.sourceJson?.let {
        runCatching { org.json.JSONObject(it).optString("sportTag") }.getOrNull()
    }?.takeIf { it.isNotBlank() }
    return dev.repera.domain.SportExerciseNames.displayName(raw, sport)
}
