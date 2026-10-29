package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.Surface
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardColors
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SheetState
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.foundation.Image
import androidx.compose.runtime.produceState
import androidx.compose.runtime.getValue
import androidx.compose.ui.draw.clip

/**
 * Defaults M3 alineados con OG iOS: cards blancas/surface sobre bg gris,
 * chips/switches/botones en verde Repera (nunca púrpura Material).
 */

@Composable
fun reperaCardColors(): CardColors = CardDefaults.cardColors(
    containerColor = MaterialTheme.colorScheme.surface,
    contentColor = MaterialTheme.colorScheme.onSurface
)

@Composable
fun reperaSelectedCardColors(): CardColors = CardDefaults.cardColors(
    containerColor = MaterialTheme.colorScheme.primaryContainer,
    contentColor = MaterialTheme.colorScheme.onPrimaryContainer
)

@Composable
fun reperaCardBorder(): BorderStroke =
    BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)

@Composable
fun reperaPrimaryButtonColors() = ButtonDefaults.buttonColors(
    containerColor = MaterialTheme.colorScheme.primary,
    contentColor = MaterialTheme.colorScheme.onPrimary
)

@Composable
fun reperaSwitchColors() = SwitchDefaults.colors(
    checkedTrackColor = MaterialTheme.colorScheme.primary,
    checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
    checkedBorderColor = MaterialTheme.colorScheme.primary,
    uncheckedTrackColor = MaterialTheme.colorScheme.surfaceVariant,
    uncheckedThumbColor = MaterialTheme.colorScheme.outline,
    uncheckedBorderColor = MaterialTheme.colorScheme.outline
)

@Composable
fun reperaFilterChipColors() = FilterChipDefaults.filterChipColors(
    containerColor = MaterialTheme.colorScheme.surface,
    labelColor = MaterialTheme.colorScheme.onSurface,
    iconColor = MaterialTheme.colorScheme.onSurfaceVariant,
    selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
    selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer,
    selectedLeadingIconColor = MaterialTheme.colorScheme.onPrimaryContainer,
    selectedTrailingIconColor = MaterialTheme.colorScheme.onPrimaryContainer,
    disabledContainerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.6f),
    disabledLabelColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f),
    disabledSelectedContainerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun reperaSegmentedButtonColors() = SegmentedButtonDefaults.colors(
    activeContainerColor = MaterialTheme.colorScheme.primaryContainer,
    activeContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
    activeBorderColor = MaterialTheme.colorScheme.outlineVariant,
    inactiveContainerColor = MaterialTheme.colorScheme.surface,
    inactiveContentColor = MaterialTheme.colorScheme.onSurface,
    inactiveBorderColor = MaterialTheme.colorScheme.outlineVariant
)

/** Chip de filtro con colores Repera (primaryContainer seleccionado). */
@Composable
fun ReperaFilterChip(
    selected: Boolean,
    onClick: () -> Unit,
    label: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: @Composable (() -> Unit)? = null
) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = label,
        modifier = modifier,
        enabled = enabled,
        leadingIcon = leadingIcon,
        colors = reperaFilterChipColors(),
        border = FilterChipDefaults.filterChipBorder(
            enabled = enabled,
            selected = selected,
            borderColor = MaterialTheme.colorScheme.outlineVariant,
            selectedBorderColor = MaterialTheme.colorScheme.primary,
            disabledBorderColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f),
            disabledSelectedBorderColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
        )
    )
}

/**
 * Card estilo lista iOS (`OGCard`): surface opaca, radio 14 (`shapes.medium`),
 * borde fino, sin elevación tonal (evita tintes violeta del surfaceTint).
 */
@Composable
fun ReperaCard(
    modifier: Modifier = Modifier,
    selected: Boolean = false,
    shape: Shape = MaterialTheme.shapes.medium,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = modifier,
        shape = shape,
        colors = if (selected) reperaSelectedCardColors() else reperaCardColors(),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = if (selected) null else reperaCardBorder(),
        content = content
    )
}

/** Variante clicable con los mismos colores/borde que [ReperaCard]. */
@Composable
fun ReperaCard(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    selected: Boolean = false,
    shape: Shape = MaterialTheme.shapes.medium,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        onClick = onClick,
        modifier = modifier,
        shape = shape,
        colors = if (selected) reperaSelectedCardColors() else reperaCardColors(),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = if (selected) null else reperaCardBorder(),
        content = content
    )
}

/**
 * Título de sección encima de cards — paridad `OGCardSectionTitle`:
 * footnote semibold, secondary; por defecto UPPERCASE (Ajustes iOS usa title case → `uppercase = false`).
 */
@Composable
fun ReperaSectionTitle(
    title: String,
    modifier: Modifier = Modifier,
    /** iOS OGCardSectionTitle: sentence case 17 gris (R4 #6 / #13). */
    uppercase: Boolean = false
) {
    Text(
        text = if (uppercase) title.uppercase() else title,
        style = MaterialTheme.typography.bodyLarge,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 0.dp)
            .padding(top = 12.dp)
    )
}

/**
 * Cabecera de pantalla root / sheet — paridad `OGFixedTopBar` / `OGPageHeader`
 * (título large bold + subtítulo secondary; acciones trailing en la misma fila).
 */
@Composable
fun ReperaPageHeader(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    trailing: @Composable RowScope.() -> Unit = {}
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 4.dp, bottom = 8.dp),
        verticalAlignment = Alignment.Top
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.headlineLarge,
                color = MaterialTheme.colorScheme.onBackground,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            if (!subtitle.isNullOrBlank()) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
            content = trailing
        )
    }
}

/** Toolbar del editor de entreno (paridad DayEditorChromeModifier): ← circular + ✓ verde. */
@Composable
fun DayEditorTopBar(
    onBack: () -> Unit,
    onConfirm: () -> Unit,
    confirmEnabled: Boolean,
    confirmContentDescription: String,
    busy: Boolean,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(
            onClick = onBack,
            enabled = !busy,
            modifier = Modifier
                .size(44.dp)
                .background(MaterialTheme.colorScheme.surfaceVariant, CircleShape)
                .testTag("editor_back")
        ) {
            Icon(
                Icons.AutoMirrored.Outlined.ArrowBack,
                contentDescription = "Volver",
                tint = MaterialTheme.colorScheme.onSurface
            )
        }
        Spacer(Modifier.weight(1f))
        IconButton(
            onClick = onConfirm,
            enabled = confirmEnabled && !busy,
            modifier = Modifier
                .size(44.dp)
                .background(
                    if (confirmEnabled && !busy) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.primary.copy(alpha = 0.4f),
                    CircleShape
                )
                .testTag("editor_confirm")
        ) {
            Icon(
                Icons.Outlined.Check,
                contentDescription = confirmContentDescription,
                tint = MaterialTheme.colorScheme.onPrimary
            )
        }
    }
}

/**
 * Empty state estructurado (icono + título + subtítulo) dentro de [ReperaCard],
 * alineado a las cards de registro vacías de iOS Home / ContentUnavailable.
 */
@Composable
fun ReperaEmptyState(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    icon: ImageVector? = null,
    contentDescription: String? = null
) {
    ReperaCard(modifier = modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = contentDescription,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(28.dp)
                )
                Spacer(Modifier.height(2.dp))
            }
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            if (!subtitle.isNullOrBlank()) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/** Botón circular estilo `OGToolbarGlassButton` (surfaceVariant + borde fino). */
@Composable
fun ReperaToolbarGlassIconButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
        border = BorderStroke(
            0.7.dp,
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.75f)
        ),
        modifier = modifier.size(40.dp)
    ) {
        Box(Modifier.size(40.dp), contentAlignment = Alignment.Center) {
            Icon(
                imageVector = icon,
                contentDescription = contentDescription,
                modifier = Modifier.size(22.dp),
                tint = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

/** Picker segmentado en píldora (track gris, selección en cápsula blanca). */
@Composable
fun ReperaTopicSegmentedPicker(
    options: List<String>,
    selected: String,
    onSelected: (String) -> Unit,
    modifier: Modifier = Modifier,
    optionTestTag: (index: Int, label: String) -> String = { index, _ -> "progress_topic_$index" },
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(999.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
        border = reperaCardBorder()
    ) {
        Row(
            modifier = Modifier.padding(4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            options.forEachIndexed { index, label ->
                val isSelected = selected == label
                Surface(
                    onClick = { onSelected(label) },
                    modifier = Modifier
                        .weight(1f)
                        .testTag(optionTestTag(index, label)),
                    shape = RoundedCornerShape(999.dp),
                    color = if (isSelected) MaterialTheme.colorScheme.surface else Color.Transparent,
                    shadowElevation = if (isSelected) 1.dp else 0.dp
                ) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelMedium.copy(
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium
                        ),
                        color = MaterialTheme.colorScheme.onSurface,
                        textAlign = TextAlign.Center,
                        maxLines = 2,
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 10.dp)
                    )
                }
            }
        }
    }
}

internal fun libraryExerciseSubtitle(entry: ExerciseEntry): String {
    val parts = buildList {
        if (entry.muscleGroup.isNotBlank()) add(entry.muscleGroup)
        addAll(entry.disciplineTags.filter { it.isNotEmpty() })
        if (entry.equipment.isNotBlank()) add(entry.equipment)
    }
    return parts.joinToString(" · ")
}

@Composable
internal fun ExerciseListThumb(
    name: String,
    sportTag: String?,
    aliases: Map<String, String>,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val stem = remember(name, sportTag) {
        ExerciseArtImages.carouselStems(
            context,
            name,
            sportTag == "Movilidad",
            aliases,
            captionCount = 1
        ).firstOrNull()
    }
    val bitmap by produceState<androidx.compose.ui.graphics.ImageBitmap?>(null, stem) {
        value = stem?.let { ExerciseArtImages.load(context, it) }
    }
    if (bitmap != null) {
        Image(
            bitmap = bitmap!!,
            contentDescription = null,
            modifier = modifier
                .size(44.dp)
                .clip(RoundedCornerShape(10.dp)),
            contentScale = ContentScale.Crop
        )
    } else {
        Spacer(modifier.size(44.dp))
    }
}

/** Fila de biblioteca — paridad `LibraryExerciseRowLabel` + chevron iOS. */
@Composable
internal fun LibraryExerciseListRow(
    title: String,
    subtitle: String,
    name: String,
    sportTag: String?,
    aliases: Map<String, String>,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    selected: Boolean = false,
) {
    ReperaCard(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        selected = selected
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            ExerciseListThumb(name, sportTag, aliases)
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                if (subtitle.isNotBlank()) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
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
}

/** Sheet M3 con surface Repera y radio extraLarge (≈ sheet iOS, no 44 literal). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReperaModalBottomSheet(
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    sheetState: SheetState = rememberModalBottomSheetState(),
    content: @Composable ColumnScope.() -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface,
        contentColor = MaterialTheme.colorScheme.onSurface,
        shape = MaterialTheme.shapes.extraLarge,
        tonalElevation = 0.dp,
        content = content
    )
}
