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
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Surface
import androidx.compose.material3.Button
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
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.DialogWindowProvider
import androidx.compose.foundation.Image
import androidx.compose.runtime.produceState
import androidx.compose.runtime.getValue
import androidx.compose.ui.draw.clip
import androidx.core.view.WindowCompat

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

/** Colores tipo UISwitch iOS: pista verde #30D158 / gris, knob blanco. */
@Composable
fun reperaSwitchColors() = SwitchDefaults.colors(
    checkedTrackColor = brandGreen,
    checkedThumbColor = Color.White,
    checkedBorderColor = Color.Transparent,
    uncheckedTrackColor = Color(0xFFE9E9EB),
    uncheckedThumbColor = Color.White,
    uncheckedBorderColor = Color(0xFFE9E9EB),
    disabledCheckedTrackColor = brandGreen.copy(alpha = 0.4f),
    disabledCheckedThumbColor = Color.White,
    disabledUncheckedTrackColor = Color(0xFFE9E9EB).copy(alpha = 0.5f),
    disabledUncheckedThumbColor = Color.White
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
        // Sin outline: cajas blancas limpias (superficie + radio).
        border = null,
        content = content
    )
}

/** Variante clicable con los mismos colores que [ReperaCard]. */
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
        border = null,
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
        // Sin fillMaxWidth: en filas con métrica a la derecha (p. ej. «7/10»)
        // el título no debe comprimir el valor a una columna de caracteres.
        maxLines = 2,
        overflow = TextOverflow.Ellipsis,
        modifier = modifier
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

/**
 * ✓ de confirmación («Listo»): círculo [brandGreen], icono blanco en día / negro en noche.
 * Usar en toda la app donde antes había un botón de texto «Listo».
 */
@Composable
fun ReperaDoneCheckButton(
    onClick: () -> Unit,
    contentDescription: String = "Listo",
    enabled: Boolean = true,
    modifier: Modifier = Modifier,
    testTag: String? = null
) {
    val dark = androidx.compose.foundation.isSystemInDarkTheme()
    val iconTint = if (dark) Color.Black else Color.White
    IconButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .size(44.dp)
            .background(
                if (enabled) brandGreen else brandGreen.copy(alpha = 0.4f),
                CircleShape
            )
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier)
    ) {
        Icon(
            Icons.Outlined.Check,
            contentDescription = contentDescription,
            tint = iconTint
        )
    }
}

/** Toolbar del editor de entreno (paridad DayEditorChromeModifier): ← glass + ✓ verde. */
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
        ReperaToolbarGlassIconButton(
            icon = Icons.AutoMirrored.Outlined.ArrowBack,
            contentDescription = "Volver",
            onClick = onBack,
            enabled = !busy,
            modifier = Modifier.testTag("editor_back")
        )
        Spacer(Modifier.weight(1f))
        ReperaDoneCheckButton(
            onClick = onConfirm,
            contentDescription = confirmContentDescription,
            enabled = confirmEnabled && !busy,
            testTag = "editor_confirm"
        )
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

/**
 * Fila con swipe dcha→izq que revela círculo rojo + basura (paridad OGSetSwipeDeleteRow).
 * Al pulsar la papelera se elimina; no hay icono X permanente.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReperaSwipeDeleteRow(
    canDelete: Boolean,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    if (!canDelete) {
        Box(modifier) { content() }
        return
    }
    val dismissState = androidx.compose.material3.rememberSwipeToDismissBoxState(
        // Permite revelar la papelera; el borrado es al pulsar el círculo rojo.
        confirmValueChange = { true }
    )
    androidx.compose.material3.SwipeToDismissBox(
        state = dismissState,
        modifier = modifier,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Box(
                Modifier
                    .fillMaxSize()
                    .padding(end = 8.dp),
                contentAlignment = Alignment.CenterEnd
            ) {
                Surface(
                    onClick = onDelete,
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.size(44.dp)
                ) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Icon(
                            Icons.Outlined.Delete,
                            contentDescription = "Eliminar",
                            tint = Color.White,
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }
            }
        }
    ) {
        Surface(color = MaterialTheme.colorScheme.surface) {
            content()
        }
    }
}

/**
 * Dialog a pantalla completa sin bandas negras en status/nav
 * (edge-to-edge; paridad Reordenar / Elegir ejercicio / Escanear pizarra).
 */
@Composable
fun ReperaFullscreenDialog(
    onDismissRequest: () -> Unit,
    content: @Composable () -> Unit
) {
    Dialog(
        onDismissRequest = onDismissRequest,
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false
        )
    ) {
        val dialogView = LocalView.current
        SideEffect {
            (dialogView.parent as? DialogWindowProvider)?.window?.let { w ->
                WindowCompat.setDecorFitsSystemWindows(w, false)
                w.statusBarColor = android.graphics.Color.TRANSPARENT
                w.navigationBarColor = android.graphics.Color.TRANSPARENT
            }
        }
        content()
    }
}

/**
 * Botón circular toolbar.
 * Touch target 48 dp; círculo 44 dp; icono 24 dp M3.
 * Día: blanco. Noche: negro. [active] tine el icono de acento (filtro activo).
 */
@Composable
fun ReperaToolbarGlassIconButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    active: Boolean = false,
    /** Tint cuando [active] (favoritos ★ → [brandAmber], no verde). */
    activeTint: Color = brandAmber,
) {
    val dark = androidx.compose.foundation.isSystemInDarkTheme()
    val circle = if (dark) Color.Black else Color.White
    val iconTint = when {
        active -> activeTint
        dark -> Color.White
        else -> Color.Black
    }
    val interaction = remember {
        androidx.compose.foundation.interaction.MutableInteractionSource()
    }
    Box(
        modifier = modifier
            .size(48.dp)
            .clip(CircleShape)
            .clickable(
                enabled = enabled,
                interactionSource = interaction,
                indication = androidx.compose.material3.ripple(
                    bounded = true,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.10f)
                ),
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Surface(
            shape = CircleShape,
            color = circle,
            tonalElevation = 0.dp,
            shadowElevation = 0.dp,
            border = BorderStroke(
                1.dp,
                MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.55f)
            ),
            modifier = Modifier.size(44.dp)
        ) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = icon,
                    contentDescription = contentDescription,
                    modifier = Modifier.size(24.dp),
                    tint = if (enabled) iconTint else iconTint.copy(alpha = 0.38f)
                )
            }
        }
    }
}

/**
 * Buscador píldora compartido (ejercicios / centro / deportes).
 */
@Composable
fun ReperaSearchField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier,
    leadingIcon: ImageVector = Icons.Outlined.Search,
    enabled: Boolean = true,
) {
    val dark = androidx.compose.foundation.isSystemInDarkTheme()
    val searchBg = if (dark) MaterialTheme.colorScheme.surface else Color.White
    androidx.compose.material3.OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier.fillMaxWidth(),
        enabled = enabled,
        singleLine = true,
        shape = RoundedCornerShape(999.dp),
        placeholder = { Text(placeholder) },
        leadingIcon = { Icon(leadingIcon, contentDescription = null) },
        colors = androidx.compose.material3.OutlinedTextFieldDefaults.colors(
            unfocusedContainerColor = searchBg,
            focusedContainerColor = searchBg,
            disabledContainerColor = searchBg,
            unfocusedBorderColor = MaterialTheme.colorScheme.outlineVariant,
            focusedBorderColor = MaterialTheme.colorScheme.primary
        )
    )
}

/**
 * Tabs full-width estilo Android (SecondaryTabRow M3).
 * Fondo transparente por defecto (sin franja gris dentro de cards blancas).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReperaTopicSegmentedPicker(
    options: List<String>,
    selected: String,
    onSelected: (String) -> Unit,
    modifier: Modifier = Modifier,
    optionTestTag: (index: Int, label: String) -> String = { index, _ -> "progress_topic_$index" },
    containerColor: Color = Color.Transparent,
) {
    if (options.isEmpty()) return
    val selectedIndex = options.indexOf(selected).coerceAtLeast(0)
    androidx.compose.material3.SecondaryTabRow(
        selectedTabIndex = selectedIndex,
        modifier = modifier.fillMaxWidth().testTag("repera_segmented_tabs"),
        containerColor = containerColor,
        contentColor = MaterialTheme.colorScheme.onSurface,
        divider = {}
    ) {
        options.forEachIndexed { index, label ->
            androidx.compose.material3.Tab(
                selected = index == selectedIndex,
                onClick = { onSelected(label) },
                modifier = Modifier.testTag(optionTestTag(index, label)),
                text = {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = if (index == selectedIndex) FontWeight.SemiBold
                        else FontWeight.Medium,
                        maxLines = 1,
                        textAlign = TextAlign.Center
                    )
                }
            )
        }
    }
}

/** Subtítulo de biblioteca (paridad LibraryView.librarySubtitle iOS).
 *  Filtra el literal JSON «null» de optString y deduplica etiquetas
 *  (p. ej. muscleGroup Cardio + discipline Cardio). */
internal fun libraryExerciseSubtitle(entry: ExerciseEntry): String {
    fun clean(raw: String?): String? =
        raw?.trim()?.takeIf { it.isNotEmpty() && !it.equals("null", ignoreCase = true) }
    val parts = LinkedHashSet<String>()
    clean(entry.muscleGroup)?.let { parts += it }
    // R7 P2: sportTag (p. ej. Movilidad) + disciplineTags (LinkedHashSet dedupe).
    clean(entry.sportTag)?.let { parts += it }
    entry.disciplineTags.mapNotNull { clean(it) }.forEach { parts += it }
    clean(entry.equipment)?.let { parts += it }
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

/**
 * Fila de biblioteca dentro de una tarjeta agrupada (iOS List/OGCard).
 * No envuelve en card propia — el contenedor aporta borde/divisores.
 */
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
    val bg = if (selected) MaterialTheme.colorScheme.primaryContainer
    else Color.Transparent
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(bg)
            .clickable(onClick = onClick)
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

/**
 * Half-sheet de confirmación destructiva (paridad OGConfirmSheet iOS):
 * icono grande, título, mensaje, botón rojo a todo el ancho + Cancelar.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReperaConfirmSheet(
    title: String,
    message: String,
    confirmTitle: String,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector = Icons.Outlined.Delete,
    confirmDestructive: Boolean = true,
) {
    ReperaModalBottomSheet(
        onDismissRequest = onCancel,
        modifier = modifier.testTag("repera_confirm_sheet")
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = if (confirmDestructive) Color(0xFFFF453A)
                    else MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(44.dp)
                )
                Text(
                    title,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    message,
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(
                    onClick = onConfirm,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                        .testTag("confirm_sheet_confirm"),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (confirmDestructive) Color(0xFFFF453A)
                        else brandGreen,
                        contentColor = Color.White
                    ),
                    shape = RoundedCornerShape(999.dp)
                ) {
                    Text(confirmTitle, fontWeight = FontWeight.Bold)
                }
                TextButton(
                    onClick = onCancel,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(44.dp)
                        .testTag("confirm_sheet_cancel"),
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = Color.Black
                    )
                ) {
                    Text("Cancelar", fontWeight = FontWeight.SemiBold)
                }
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
