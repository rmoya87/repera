package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.DragHandle
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Reordenar: **una tarjeta por bloque** (cabecera + ejercicios con divider fino).
 * DnD real sin menú «Mover a otro bloque»:
 * - Handle del bloque → mueve la caja entera (bloque + ejercicios).
 * - Handle del ejercicio → reordena dentro o suelta en otra caja.
 * Arrastre: esquinas redondeadas + sombra tenue (paridad iOS OGReorderDragPreview).
 */
@Composable
internal fun PlanReorderFullscreen(
    blocks: SnapshotStateList<BlockDraftUi>,
    nameById: Map<String, String>,
    exercises: List<ExerciseEntry>,
    onDone: () -> Unit,
    onMoveMessage: (String?) -> Unit = {}
) {
    Column(
        Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        PlanReorderTopBar(onBack = onDone, onDone = onDone)
        PlanReorderSheet(
            blocks = blocks,
            nameById = nameById,
            exercises = exercises,
            onDone = onDone,
            onMoveMessage = onMoveMessage,
            showToolbar = false
        )
    }
}

@Composable
private fun PlanReorderTopBar(onBack: () -> Unit, onDone: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ReperaToolbarGlassIconButton(
            icon = Icons.AutoMirrored.Outlined.ArrowBack,
            contentDescription = "Volver",
            onClick = onBack,
            modifier = Modifier.testTag("plan_reorder_back")
        )
        Text(
            "Reordenar",
            modifier = Modifier.weight(1f),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        ReperaDoneCheckButton(
            onClick = onDone,
            testTag = "plan_reorder_done"
        )
    }
}

@Composable
internal fun PlanReorderSheet(
    blocks: SnapshotStateList<BlockDraftUi>,
    nameById: Map<String, String>,
    exercises: List<ExerciseEntry>,
    onDone: () -> Unit,
    onMoveMessage: (String?) -> Unit = {},
    showToolbar: Boolean = true
) {
    val scroll = rememberScrollState()
    val blockHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
    val geo = remember { EditorGeometry() }
    ProvideScrollDragAutoScroll(scroll) {
        Column(
            Modifier
                .fillMaxWidth()
                .verticalScroll(scroll)
                .padding(horizontal = 16.dp)
                .padding(bottom = 24.dp)
                .testTag("plan_reorder_sheet")
        ) {
            if (showToolbar) {
                PlanReorderTopBar(onBack = onDone, onDone = onDone)
            }

            blocks.forEachIndexed { blockIndex, block ->
                DragReorderItem(
                    index = blockIndex,
                    heights = blockHeights,
                    count = blocks.size,
                    onDrop = { _, t ->
                        if (t != blockIndex && t in blocks.indices) {
                            val moved = blocks.removeAt(blockIndex); blocks.add(t, moved)
                        }
                    },
                    onMoveTo = { t ->
                        if (t != blockIndex && t in blocks.indices) {
                            val moved = blocks.removeAt(blockIndex); blocks.add(t, moved)
                        }
                    },
                    onBounds = { top, bottom -> geo.blocks[blockIndex] = top to bottom }
                ) { blockHandle ->
                    ReorderBlockBox(
                        position = blockIndex,
                        block = block,
                        nameById = nameById,
                        blockHandle = blockHandle,
                        onEntryDrop = { entryIndex, centerY, sameTarget ->
                            val tb = EditorBlockOps.dropBlockIndex(centerY, geo.blockBounds(blocks.size))
                            if (tb == null) return@ReorderBlockBox
                            if (tb == blockIndex) {
                                if (sameTarget != entryIndex && sameTarget in block.entries.indices) {
                                    val moved = block.entries.removeAt(entryIndex)
                                    block.entries.add(sameTarget, moved)
                                }
                            } else {
                                val n = blocks[tb].entries.size
                                val before = EditorBlockOps.dropBeforeId(
                                    centerY,
                                    (geo.items[tb] ?: emptyMap()).filterKeys {
                                        (it.toIntOrNull() ?: Int.MAX_VALUE) < n
                                    }.toList()
                                )
                                val msg = PlanEntryMoves.move(
                                    blocks, blockIndex, entryIndex, tb,
                                    nameById, exercises, before?.toIntOrNull()
                                )
                                onMoveMessage(msg)
                            }
                        },
                        onEntryBounds = { ei, top, bottom ->
                            geo.items.getOrPut(blockIndex) { mutableMapOf() }[ei.toString()] = top to bottom
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun ReorderBlockBox(
    position: Int,
    block: BlockDraftUi,
    nameById: Map<String, String>,
    blockHandle: Modifier,
    onEntryDrop: (entryIndex: Int, centerY: Float, sameBlockTarget: Int) -> Unit,
    onEntryBounds: (Int, Float, Float) -> Unit
) {
    val entryHeights = remember(block) { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
    val shape = RoundedCornerShape(14.dp)
    // Misma card que el resto de la app: borde fino, sin sombra fuerte.
    Column(
        Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp)
            .clip(shape)
            .background(MaterialTheme.colorScheme.surface)
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, shape)
            .testTag("reorder_block_box")
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 12.dp),
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
                Text(
                    block.title.ifBlank { "Bloque ${position + 1}" },
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    blockFormatSubtitle(block),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Icon(
                Icons.Outlined.DragHandle,
                contentDescription = "Arrastrar bloque",
                modifier = blockHandle.testTag("reorder_block_drag"),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        if (block.entries.isEmpty()) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(40.dp)
                    .padding(horizontal = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Soltar ejercicio",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            block.entries.forEachIndexed { entryIndex, entry ->
                HorizontalDivider(
                    Modifier.padding(start = 14.dp),
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                )
                DragReorderItem(
                    index = entryIndex,
                    heights = entryHeights,
                    count = block.entries.size,
                    onDrop = { centerY, t -> onEntryDrop(entryIndex, centerY, t) },
                    onMoveTo = { t ->
                        if (t != entryIndex && t in block.entries.indices) {
                            val moved = block.entries.removeAt(entryIndex)
                            block.entries.add(t, moved)
                        }
                    },
                    onBounds = { top, bottom -> onEntryBounds(entryIndex, top, bottom) }
                ) { entryHandle ->
                    ReorderExerciseRow(
                        name = entryDisplayName(entry, nameById),
                        exerciseId = entry.exerciseId,
                        sourceJson = entry.sourceJson,
                        handle = entryHandle
                    )
                }
            }
        }
    }
}

@Composable
private fun ReorderExerciseRow(
    name: String,
    exerciseId: String,
    sourceJson: String?,
    handle: Modifier
) {
    val sportTag = sourceJson?.let {
        runCatching { org.json.JSONObject(it).optString("sportTag") }.getOrNull()
    }?.takeIf { it.isNotBlank() && !it.equals("null", ignoreCase = true) }
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        if (exerciseId.isNotBlank()) {
            ExerciseListThumb(
                name = name,
                sportTag = sportTag,
                aliases = emptyMap()
            )
        }
        Text(name, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
        Icon(
            Icons.Outlined.DragHandle,
            contentDescription = "Arrastrar ejercicio",
            modifier = handle.testTag("reorder_entry_drag"),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/** Hueco entre cajas (solo se ilumina al apuntar en iOS; en Android el drop es por geometría). */
@Composable
internal fun ReorderInsertionGap(visible: Boolean, label: String = "Soltar aquí") {
    if (!visible) return
    Box(
        Modifier
            .fillMaxWidth()
            .height(10.dp)
            .testTag("reorder_gap"),
        contentAlignment = Alignment.Center
    ) {
        // Reservado para tests; la UI pedida no muestra franjas verdes permanentes.
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0f),
            fontWeight = FontWeight.SemiBold
        )
    }
}

private fun blockFormatSubtitle(block: BlockDraftUi): String = when {
    block.format.isBlank() -> "Sin formato · libre"
    block.format == "strength" -> "Fuerza"
    block.format == "amrap" -> "AMRAP"
    block.format == "emom" -> "EMOM"
    block.format.equals("fortime", true) || block.format == "forTime" -> "For Time"
    block.format == "tabata" -> "Tabata"
    else -> BlockFormatCatalog.title(block.format)
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
