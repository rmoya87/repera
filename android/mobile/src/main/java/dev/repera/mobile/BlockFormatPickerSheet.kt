package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.RemoveCircleOutline
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.repera.domain.WodFormat

/** I-62 página «Formato del bloque» con nombre + descripción. */
internal data class BlockFormatOption(
    val wire: String,
    val title: String,
    val description: String
)

internal object BlockFormatCatalog {
    /** Orden iOS PlanView (Sin formato aparte): AMRAP… luego Fuerza/Skill, AFAP… */
    val options: List<BlockFormatOption> = listOf(
        BlockFormatOption(
            "amrap", "AMRAP",
            "Máximas rondas/reps en un tiempo fijo (AMRAP 12', AMRAP 10 min)."
        ),
        BlockFormatOption(
            "emom", "EMOM / Every X'",
            "Trabajo al inicio de cada intervalo (EMOM, EVERY 2'×4, E2MOM, ON THE MINUTE)."
        ),
        BlockFormatOption(
            "forTime", "For Time / RFT",
            "Termina lo antes posible: N RFT, FOR TIME, TC (time cap)."
        ),
        BlockFormatOption(
            "tabata", "Tabata",
            "Intervalos fijos clásicos 20\"/10\" × rondas (u otras proporciones)."
        ),
        BlockFormatOption(
            "chipper", "Chipper",
            "Lista larga en una sola pasada, lo más rápido posible."
        ),
        BlockFormatOption(
            "deathBy", "Muerte por",
            "Cada minuto sumas 1 rep (u otra progresión) hasta fallar."
        ),
        BlockFormatOption(
            "strength", "Fuerza / Skill",
            "Bloque de fuerza/técnica: 5×5, 3×8 @RPE, skill."
        ),
        BlockFormatOption(
            "afap", "AFAP",
            "Haz el trabajo lo más rápido posible (sin rondas fijas)."
        ),
        BlockFormatOption(
            "circuit", "Circuit",
            "Estaciones en circuito con intervalo fijo."
        ),
        BlockFormatOption(
            "ladder", "Ladder",
            "Esquema ascendente o descendente de repeticiones."
        ),
        BlockFormatOption(
            "partner", "Partner",
            "Trabajo en pareja por rondas o estaciones."
        ),
        BlockFormatOption(
            "roundsForQuality", "Rounds for Quality",
            "Rondas enfocadas en calidad técnica, no en velocidad."
        ),
        BlockFormatOption(
            "maxEffort", "Max Effort",
            "Esfuerzo máximo en un tiempo o serie limitada."
        ),
        BlockFormatOption(
            "buyInCashOut", "Buy-In / Cash-Out",
            "Trabajo de entrada y salida alrededor del bloque principal."
        )
    )

    fun title(wire: String): String {
        if (wire.isBlank()) return "Sin formato"
        return options.firstOrNull { it.wire == wire }?.title
            ?: WodFormat.fromWire(wire)?.displayName
            ?: wire
    }
}

@Composable
internal fun BlockFormatPickerSheet(
    current: String,
    onPick: (String) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Cerrar") }
        },
        title = { Text("Formato del bloque", fontWeight = FontWeight.Bold) },
        text = {
            LazyColumn(
                Modifier.heightIn(max = 420.dp).testTag("block_format_list"),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                item {
                    FormatRow(
                        title = "Sin formato",
                        description = null,
                        selected = current.isBlank(),
                        leading = {
                            Icon(
                                Icons.Outlined.RemoveCircleOutline,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        },
                        onClick = { onPick("") }
                    )
                }
                items(BlockFormatCatalog.options, key = { it.wire }) { opt ->
                    FormatRow(
                        title = opt.title,
                        description = opt.description,
                        selected = current == opt.wire,
                        onClick = { onPick(opt.wire) }
                    )
                }
            }
        }
    )
}

@Composable
private fun FormatRow(
    title: String,
    description: String?,
    selected: Boolean,
    leading: (@Composable () -> Unit)? = null,
    onClick: () -> Unit
) {
    Row(
        Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp)
            .testTag("block_format_${title.take(12)}"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        leading?.invoke()
        Column(Modifier.weight(1f)) {
            Text(
                title + if (selected) " ✓" else "",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = if (selected) FontWeight.Bold else FontWeight.SemiBold,
                color = if (selected) brandGreen else MaterialTheme.colorScheme.onSurface
            )
            if (!description.isNullOrBlank()) {
                Text(
                    description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Icon(
            Icons.AutoMirrored.Outlined.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
