package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Desglose de plan estilo Apple (historial / preview): etiqueta de formato
 * encima y una sola caja con ejercicios (thumb + nombre + detalle).
 */
@Composable
internal fun RoutinePlanBreakdown(
    blocks: List<RoutineBlockInfo>,
    exerciseCatalog: List<ExerciseEntry>,
    onOpenExercise: (String) -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        blocks.forEach { block ->
            val formatLabel = blockFormatLabelForBreakdown(block)
            if (formatLabel.isNotBlank()) {
                ReperaSectionTitle(formatLabel)
            } else if (block.title.isNotBlank()) {
                ReperaSectionTitle(block.title)
            }
            if (block.entries.isEmpty()) return@forEach
            ReperaInsetGroupedList {
                block.entries.forEachIndexed { index, entry ->
                    if (index > 0) {
                        HorizontalDivider(
                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                        )
                    }
                    val tappable = entry.exerciseId.isNotBlank()
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .then(
                                if (tappable) Modifier.clickable { onOpenExercise(entry.exerciseId) }
                                else Modifier
                            )
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        val resolved = remember(entry.exerciseId, entry.name, exerciseCatalog) {
                            if (entry.exerciseId.isNotBlank()) {
                                exerciseCatalog.firstOrNull { it.id == entry.exerciseId }
                                    ?: resolveWodExercise(
                                        entry.name, exerciseCatalog, aliases,
                                        exerciseId = entry.exerciseId
                                    )
                            } else {
                                resolveWodExercise(entry.name, exerciseCatalog, aliases)
                            }
                        }
                        WodExerciseThumbnail(resolved, aliases, size = 44.dp)
                        Column(Modifier.weight(1f)) {
                            Text(
                                entry.name.ifBlank { "Ejercicio" },
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            val detail = buildString {
                                val unitLabel = when (entry.quantityUnit) {
                                    "meters" -> " m"
                                    "calories" -> " cal"
                                    else -> ""
                                }
                                if (entry.sets > 0 && entry.quantity > 0) {
                                    if (unitLabel.isNotEmpty()) {
                                        append("${entry.sets}×${entry.quantity}$unitLabel")
                                    } else {
                                        append("${entry.sets}×${entry.quantity}")
                                    }
                                } else if (entry.quantity > 0) {
                                    append("${entry.quantity}$unitLabel")
                                }
                                entry.weightKg?.let { w ->
                                    if (isNotEmpty()) append(" · ")
                                    append("${dev.repera.domain.ReperaNumberFormat.decimal(w)} kg")
                                }
                            }
                            if (detail.isNotBlank()) {
                                Text(
                                    detail,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                        if (tappable) {
                            Icon(
                                Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
    }
}

internal fun blockFormatLabelForBreakdown(block: RoutineBlockInfo): String = when (block.format) {
    "" -> block.title
    "strength" -> block.title.ifBlank { "Fuerza" }
    "amrap" -> "AMRAP ${block.timeCapMinutes}'"
    "emom" -> "EMOM ${block.timeCapMinutes}'"
    "fortime", "forTime" -> "For Time · cap ${block.timeCapMinutes}'"
    "tabata" -> "Tabata ${block.workSeconds}/${block.restSeconds}s × ${block.rounds}"
    else -> BlockFormatCatalog.title(block.format).ifBlank { block.title }
}
