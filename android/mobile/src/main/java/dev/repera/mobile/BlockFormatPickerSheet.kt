package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.RemoveCircleOutline
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import dev.repera.domain.WodFormat

/** I-62 página «Formato del bloque» con nombre + descripción. */
internal data class BlockFormatOption(
    val wire: String,
    val title: String,
    val description: String
)

internal object BlockFormatCatalog {
    /** Paridad iOS `WODFormat.allCases` + nombres/descripciones canónicos. */
    val options: List<BlockFormatOption> = WodFormat.entries.map { format ->
        BlockFormatOption(format.wireName, format.displayName, format.detail)
    }

    fun title(wire: String): String {
        if (wire.isBlank()) return "Sin formato · libre"
        return options.firstOrNull { it.wire == wire }?.title
            ?: WodFormat.fromWire(wire)?.displayName
            ?: wire
    }
}

/** Formato a pantalla completa (paridad Elegir ejercicio). */
@Composable
internal fun BlockFormatPickerSheet(
    current: String,
    onPick: (String) -> Unit,
    onDismiss: () -> Unit
) {
    ReperaFullscreenDialog(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .statusBarsPadding()
                .navigationBarsPadding()
                .testTag("block_format_fullscreen")
        ) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                ReperaToolbarGlassIconButton(
                    icon = Icons.AutoMirrored.Outlined.ArrowBack,
                    contentDescription = "Volver",
                    onClick = onDismiss
                )
                Text(
                    "Formato del bloque",
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                androidx.compose.foundation.layout.Spacer(Modifier.padding(24.dp))
            }
            LazyColumn(
                Modifier.fillMaxSize().testTag("block_format_list"),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
            ) {
                // Una sola card redondeada (arriba y abajo): evita esquinas
                // cuadradas en «Sin formato» como en iOS insetGrouped + Section.
                item(key = "format-group") {
                    val shape = MaterialTheme.shapes.medium
                    ReperaCard(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(shape)
                            .testTag("block_format_group"),
                        shape = shape
                    ) {
                        FormatRow(
                            title = "Sin formato · libre",
                            description = "Bloque libre sin reloj de formato. Añade ejercicios y configura después si hace falta.",
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
                        BlockFormatCatalog.options.forEach { opt ->
                            HorizontalDivider(
                                modifier = Modifier.padding(start = 16.dp),
                                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                            )
                            FormatRow(
                                title = opt.title,
                                description = opt.description,
                                selected = current == opt.wire,
                                onClick = { onPick(opt.wire) }
                            )
                        }
                    }
                }
            }
        }
    }
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
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .testTag("block_format_${title.take(12)}"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        leading?.invoke()
        Column(Modifier.weight(1f)) {
            Text(
                title,
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
        if (selected) {
            Icon(
                Icons.Outlined.Check,
                contentDescription = "Seleccionado",
                tint = brandGreen
            )
        } else {
            Icon(
                Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
