package dev.repera.mobile

import androidx.compose.ui.res.stringResource
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
// background used for selected tab capsule fill
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.outlined.AddCircle
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import androidx.annotation.StringRes
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics

/** Sombra corta y clara para chrome flotante (menú, FABs, cards glass). */
internal val ReperaChromeAmbientShadow = Color.Black.copy(alpha = 0.05f)
internal val ReperaChromeSpotShadow = Color.Black.copy(alpha = 0.08f)
internal val ReperaChromeShadowElevation = 1.5.dp

internal fun Modifier.reperaChromeShadow(shape: Shape): Modifier =
    shadow(
        elevation = ReperaChromeShadowElevation,
        shape = shape,
        clip = false,
        ambientColor = ReperaChromeAmbientShadow,
        spotColor = ReperaChromeSpotShadow,
    )

/**
 * Altura del chrome inferior (tab bar + Continuar + nav bars) cuando está visible.
 * El contenido dibuja detrás del menú; los scrolls usan este inset para que el
 * último ítem acabe encima del menú al llegar al final.
 */
internal val LocalReperaTabBarInset = compositionLocalOf { 0.dp }

/** Gutter horizontal de página (paridad `OG.pad` iOS / default de listas). */
internal val ReperaPageGutter = 16.dp

/**
 * Rompe el `contentPadding` horizontal del LazyColumn anfitrión para que un
 * carrusel horizontal llegue al borde físico de pantalla. El inset de lectura
 * debe ir en el *contenido* scrolleable (padding interior / Spacers), como
 * `contentMargins` + padding del HStack en iOS — no en el viewport.
 */
internal fun Modifier.reperaFullBleedHorizontal(
    gutter: Dp = ReperaPageGutter
): Modifier = this.then(
    Modifier.layout { measurable, constraints ->
        val gutterPx = gutter.roundToPx()
        val wide = (constraints.maxWidth + gutterPx * 2).coerceAtLeast(0)
        val placeable = measurable.measure(
            constraints.copy(minWidth = wide, maxWidth = wide)
        )
        layout(constraints.maxWidth, placeable.height) {
            placeable.placeRelative(-gutterPx, 0)
        }
    }
)

/** Padding de listas con tab bar: horizontal/top fijos + bottom = inset medido. */
@Composable
internal fun reperaScrollContentPadding(
    horizontal: Dp = ReperaPageGutter,
    top: Dp = 16.dp,
    extraBottom: Dp = 12.dp
): PaddingValues = PaddingValues(
    start = horizontal,
    end = horizontal,
    top = top,
    bottom = LocalReperaTabBarInset.current + extraBottom
)

internal data class ReperaTabSpec(
    val route: String,
    val label: String,
    val icon: ImageVector,
    val selectedIcon: ImageVector = icon,
    @param:StringRes val labelRes: Int = 0
) {
    fun iconFor(selected: Boolean): ImageVector = if (selected) selectedIcon else icon

    // La pestaña central muestra solo su círculo «+»; las demás conservan el texto.
    val visibleLabel: String? get() = label.takeUnless { route == "plus" }
    val accessibilityLabel: String get() = if (route == "plus") "Clases y centro" else label
    @get:StringRes val accessibilityLabelRes: Int get() = if (route == "plus") R.string.tab_plus_a11y else labelRes
}

/** Cinco pestañas principales (paridad iOS: Inicio · Comenzar · + · Progreso · Ejercicios). */
internal val reperaMainTabs = listOf(
    ReperaTabSpec("inicio", "Inicio", Icons.Outlined.Home, Icons.Filled.Home, R.string.tab_home),
    ReperaTabSpec("en-vivo", "Comenzar", Icons.Outlined.PlayCircle, Icons.Filled.PlayCircle, R.string.tab_start),
    ReperaTabSpec("plus", "+", Icons.Outlined.AddCircle, Icons.Filled.AddCircle, R.string.tab_plus_a11y),
    ReperaTabSpec("progreso", "Progreso", Icons.Outlined.BarChart, Icons.Filled.BarChart, R.string.tab_progress),
    // SF `dumbbell` horizontal (no FitnessCenter diagonal / «⤡»).
    ReperaTabSpec("ejercicios", "Ejercicios", ReperaIcons.Dumbbell, ReperaIcons.Dumbbell, R.string.tab_exercises)
)

/** La navegación de clases/centro aparece únicamente con vínculo de cliente activo. */
internal fun reperaTabsForCenter(hasLinkedCenter: Boolean): List<ReperaTabSpec> =
    if (hasLinkedCenter) reperaMainTabs else reperaMainTabs.filterNot { it.route == "plus" }

internal val reperaTabRoutes: Set<String> = reperaMainTabs.map { it.route }.toSet()

/** Push / subpáginas: sin TopAppBar «repera»+gear (R5 P1-7). */
internal fun reperaRouteHidesAppShell(route: String?): Boolean {
    if (route.isNullOrBlank()) return false
    return when {
        route.startsWith("rutina/") -> true
        route.startsWith("rutina-nueva") -> true
        route.startsWith("escaner") -> true
        route.startsWith("favoritos") -> true
        route.startsWith("temporizador") -> true
        route.startsWith("ajustes-") -> true
        route.startsWith("ejercicio") -> true
        route.startsWith("preview/") -> true
        route.startsWith("historial-detalle") -> true
        route.startsWith("historial-editar") -> true
        route.startsWith("formato-bloque") -> true
        route in setOf(
            "entreno-libre",
            "entreno-activo",
            "entreno-activo-editar",
            "favorito-nuevo",
            "ajustes",
            "reloj",
            // R6 P0-2: peso/historial/center/ia ocultan chrome repera+gear
            // pero llevan Volver propio y mantienen tab bar (keepsTabBar).
            "historial",
            "acceso-ia",
            "peso-corporal",
            "center",
            "mensajes",
            "programas-ia",
            "deportes"
        ) -> true
        else -> false
    }
}

/** Push que mantienen la tab bar. Crear/editar/play y Ajustes la ocultan. */
internal fun reperaRouteKeepsTabBar(route: String?): Boolean {
    if (route.isNullOrBlank()) return false
    return when {
        // Ajustes y subpáginas: menú baja (paridad iOS SettingsView.toolbar tabBar).
        route == "ajustes" || route.startsWith("ajustes-") -> false
        route == "acceso-ia" || route == "programas-ia" -> false
        // Crear / editar / play: sin menú principal (solo ← y ✓).
        route.startsWith("rutina-nueva") -> false
        route.startsWith("rutina/") -> false
        route.startsWith("historial-editar") -> false
        // Detalle hecho / preview pendiente: sin menú (paridad iOS WorkoutDetailView).
        route.startsWith("historial-detalle") -> false
        route.startsWith("preview/") -> false
        route == "entreno-activo" || route == "entreno-activo-editar" ||
            route == "entreno-libre" || route == "favorito-nuevo" -> false
        route.startsWith("ejercicio") -> true
        route == "peso-corporal" -> true
        route == "historial" -> true
        route == "center" -> true
        route.startsWith("temporizador") -> true
        else -> false
    }
}

/**
 * Barra de pestañas flotante tipo píldora (§1.4 / §1.6): inset horizontal,
 * elevación suave y selección con cápsula detrás del icono.
 */
@Composable
internal fun ReperaFloatingTabBar(
    tabs: List<ReperaTabSpec>,
    selectedRoute: String,
    onTabSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val pillShape = RoundedCornerShape(999.dp)
    // Fondo opaco (blanco en claro, gris elevado en oscuro); pestaña activa en verde.
    Surface(
        modifier = modifier
            .widthIn(max = REPERA_TAB_BAR_MAX_WIDTH)
            .fillMaxWidth()
            .reperaChromeShadow(pillShape)
            .selectableGroup()
            .testTag("floating_tab_bar"),
        shape = pillShape,
        color = MaterialTheme.reperaColors.chromeSurface,
        shadowElevation = 0.dp,
        tonalElevation = 0.dp,
        border = BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
        )
    ) {
        // NavigationBarItem gestiona el indicador y la transición de selección
        // con la animación Material 3, sin desplazamientos personalizados.
        androidx.compose.runtime.CompositionLocalProvider(
            androidx.compose.material3.LocalRippleConfiguration provides null
        ) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 6.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                tabs.forEach { tab ->
                    val selected = selectedRoute == tab.route
                    val label = stringResource(tab.accessibilityLabelRes)
                    NavigationBarItem(
                        selected = selected,
                        onClick = { onTabSelected(tab.route) },
                        icon = {
                            Icon(
                                imageVector = tab.iconFor(selected),
                                contentDescription = label,
                                modifier = Modifier.size(24.dp)
                            )
                        },
                        label = tab.visibleLabel?.let {
                            {
                                Text(
                                    text = label,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        },
                        alwaysShowLabel = true,
                        colors = androidx.compose.material3.NavigationBarItemDefaults.colors(
                            selectedIconColor = brandGreen,
                            selectedTextColor = brandGreen,
                            indicatorColor = MaterialTheme.reperaColors.tabSelectedFill,
                            unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                            unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
                        ),
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

/** Accesorio «Continuar» sobre la píldora (ContinueAccessory iOS): blanco, thumb + título. */
@Composable
internal fun ReperaContinueAccessory(
    title: String,
    progress: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    exercise: ExerciseEntry? = null,
    /** Comenzar: icono del deporte en círculo ámbar. */
    isLiveActivity: Boolean = false,
    liveSportIcon: ImageVector? = null,
) {
    val context = LocalContext.current
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    val thumbSize = 44.dp
    val accent = if (isLiveActivity) brandAmber else brandGreen
    val chrome = MaterialTheme.reperaColors
    val continueLabel = stringResource(R.string.continue_a11y, title)
    val continueShape = RoundedCornerShape(18.dp)
    Surface(
        color = chrome.chromeSurface,
        shape = continueShape,
        shadowElevation = 0.dp,
        tonalElevation = 0.dp,
        modifier = modifier
            .widthIn(max = REPERA_TAB_BAR_MAX_WIDTH)
            .fillMaxWidth()
            .reperaChromeShadow(continueShape)
            .clickable(onClickLabel = continueLabel, role = Role.Button, onClick = onClick)
            .semantics(mergeDescendants = true) {}
            .testTag("continuar_accessory")
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(start = 14.dp, end = 16.dp, top = 12.dp, bottom = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                Modifier
                    .size(thumbSize)
                    .clip(if (isLiveActivity) CircleShape else RoundedCornerShape(10.dp))
                    .background(
                        if (isLiveActivity) accent else chrome.chromeThumb
                    ),
                contentAlignment = Alignment.Center
            ) {
                when {
                    exercise != null && !isLiveActivity ->
                        WodExerciseThumbnail(exercise, aliases, size = thumbSize)
                    isLiveActivity -> Icon(
                        liveSportIcon ?: Icons.Filled.PlayArrow,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(22.dp)
                    )
                    else -> Icon(
                        Icons.Filled.PlayArrow,
                        contentDescription = null,
                        tint = accent,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
            Column(
                Modifier
                    .weight(1f)
                    .heightIn(min = thumbSize),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    stringResource(R.string.action_continue),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = chrome.onChromeSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            if (progress.isNotEmpty()) {
                val lines = progress.split('\n')
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        lines.first(),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = accent,
                        maxLines = 1
                    )
                    if (lines.size > 1) {
                        Text(
                            lines.drop(1).joinToString(" "),
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = accent,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
        }
    }
}

/** iPad / tablet: la píldora no se estira a todo el ancho (iPadOS mantiene la barra compacta). */
internal val REPERA_TAB_BAR_MAX_WIDTH = 560.dp

/** Columna inferior: Continuar sale por detrás de la píldora + menú. */
@Composable
internal fun ReperaTabBarChrome(
    showTabBar: Boolean,
    selectedRoute: String,
    onTabSelected: (String) -> Unit,
    showCenterTab: Boolean = true,
    continueTitle: String?,
    continueProgress: String,
    onContinue: () -> Unit,
    continueExercise: ExerciseEntry? = null,
    continueIsLive: Boolean = false,
    continueLiveIcon: ImageVector? = null,
) {
    androidx.compose.animation.AnimatedVisibility(
        visible = showTabBar,
        enter = androidx.compose.animation.slideInVertically(
            initialOffsetY = { it },
            animationSpec = androidx.compose.animation.core.tween(220)
        ) + androidx.compose.animation.fadeIn(
            animationSpec = androidx.compose.animation.core.tween(180)
        ),
        exit = androidx.compose.animation.slideOutVertically(
            targetOffsetY = { it },
            animationSpec = androidx.compose.animation.core.tween(220)
        ) + androidx.compose.animation.fadeOut(
            animationSpec = androidx.compose.animation.core.tween(160)
        )
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .background(Color.Transparent)
                .navigationBarsPadding()
                .padding(start = 16.dp, end = 16.dp, bottom = 10.dp, top = 4.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (continueTitle != null) {
                // Encima del menú (paridad iOS tabViewBottomAccessory), sin solapar texto.
                ReperaContinueAccessory(
                    title = continueTitle,
                    progress = continueProgress,
                    onClick = onContinue,
                    exercise = continueExercise,
                    isLiveActivity = continueIsLive,
                    liveSportIcon = continueLiveIcon,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
            }
            ReperaFloatingTabBar(
                tabs = reperaTabsForCenter(showCenterTab),
                selectedRoute = selectedRoute,
                onTabSelected = onTabSelected,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
