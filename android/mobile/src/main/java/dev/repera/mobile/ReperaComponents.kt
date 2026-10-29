package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Check
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

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
 * footnote semibold, secondary, UPPERCASE, pad h4 / top12.
 */
@Composable
fun ReperaSectionTitle(
    title: String,
    modifier: Modifier = Modifier
) {
    Text(
        text = title.uppercase(),
        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
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
