package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
// background used for selected tab capsule fill
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex

/**
 * Altura del chrome inferior (tab bar + Continuar + nav bars) cuando está visible.
 * El contenido dibuja detrás del menú; los scrolls usan este inset para que el
 * último ítem acabe encima del menú al llegar al final.
 */
internal val LocalReperaTabBarInset = compositionLocalOf { 0.dp }

/** Padding de listas con tab bar: horizontal/top fijos + bottom = inset medido. */
@Composable
internal fun reperaScrollContentPadding(
    horizontal: Dp = 16.dp,
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
    val selectedIcon: ImageVector = icon
) {
    fun iconFor(selected: Boolean): ImageVector = if (selected) selectedIcon else icon
}

/** Cuatro pestañas principales (paridad iOS Liquid Glass tab bar). */
internal val reperaMainTabs = listOf(
    ReperaTabSpec("inicio", "Inicio", Icons.Outlined.Home, Icons.Filled.Home),
    ReperaTabSpec("en-vivo", "Comenzar", Icons.Outlined.PlayCircle, Icons.Filled.PlayCircle),
    ReperaTabSpec("progreso", "Progreso", Icons.Outlined.BarChart, Icons.Filled.BarChart),
    // SF `dumbbell` horizontal (no FitnessCenter diagonal / «⤡»).
    ReperaTabSpec("ejercicios", "Ejercicios", ReperaIcons.Dumbbell, ReperaIcons.Dumbbell)
)

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

/** Push que mantienen la tab bar. Crear/editar/play entreno la ocultan. */
internal fun reperaRouteKeepsTabBar(route: String?): Boolean {
    if (route.isNullOrBlank()) return false
    return when {
        route == "ajustes" -> true
        // Crear / editar / play: sin menú principal (solo ← y ✓).
        route.startsWith("rutina-nueva") -> false
        route.startsWith("rutina/") -> false
        route.startsWith("historial-editar") -> false
        route == "entreno-activo" || route == "entreno-activo-editar" ||
            route == "entreno-libre" || route == "favorito-nuevo" -> false
        route.startsWith("ejercicio") -> true
        route == "peso-corporal" -> true
        route == "historial" -> true
        route == "center" -> true
        route == "acceso-ia" -> true
        route.startsWith("temporizador") -> true
        route.startsWith("ajustes-") -> true
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
    // Fondo blanco opaco; pestaña activa en verde (icono + texto).
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .testTag("floating_tab_bar"),
        shape = pillShape,
        color = Color.White,
        shadowElevation = 4.dp,
        tonalElevation = 0.dp,
        border = BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
        )
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 6.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            tabs.forEach { tab ->
                ReperaFloatingTabItem(
                    tab = tab,
                    selected = selectedRoute == tab.route,
                    onClick = { onTabSelected(tab.route) },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun ReperaFloatingTabItem(
    tab: ReperaTabSpec,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val scheme = MaterialTheme.colorScheme
    val iconTint = if (selected) brandGreen else scheme.onSurfaceVariant
    val labelColor = if (selected) brandGreen else scheme.onSurfaceVariant
    val interaction = remember { androidx.compose.foundation.interaction.MutableInteractionSource() }
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .clickable(
                interactionSource = interaction,
                indication = androidx.compose.material3.ripple(
                    bounded = true,
                    color = scheme.onSurface.copy(alpha = 0.10f)
                ),
                onClick = onClick
            )
            .padding(vertical = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(width = 56.dp, height = 32.dp)
                .then(
                    if (selected) Modifier
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color(0x1430D158)) // cápsula fill verde suave
                    else Modifier
                )
        ) {
            Icon(
                imageVector = tab.iconFor(selected),
                contentDescription = tab.label,
                modifier = Modifier.size(24.dp),
                tint = iconTint
            )
        }
        Text(
            text = tab.label,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium,
            color = labelColor,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
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
    Surface(
        color = Color.White,
        shape = RoundedCornerShape(topStart = 18.dp, topEnd = 18.dp),
        shadowElevation = 6.dp,
        tonalElevation = 0.dp,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .testTag("continuar_accessory")
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                // Fondo blanco se prolonga por detrás de la píldora (sin corte gris).
                .padding(start = 14.dp, end = 16.dp, top = 12.dp, bottom = 40.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                Modifier
                    .size(thumbSize)
                    .clip(if (isLiveActivity) CircleShape else RoundedCornerShape(10.dp))
                    .background(
                        if (isLiveActivity) accent else Color(0xFFF2F2F7)
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
                    .height(thumbSize),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    "Continuar",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.Black,
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

/** Columna inferior: Continuar sale por detrás de la píldora + menú. */
@Composable
internal fun ReperaTabBarChrome(
    showTabBar: Boolean,
    selectedRoute: String,
    onTabSelected: (String) -> Unit,
    continueTitle: String?,
    continueProgress: String,
    onContinue: () -> Unit,
    continueExercise: ExerciseEntry? = null,
    continueIsLive: Boolean = false,
    continueLiveIcon: ImageVector? = null,
) {
    if (!showTabBar) return
    Box(
        Modifier
            .fillMaxWidth()
            .background(Color.Transparent)
            .navigationBarsPadding()
            .padding(start = 16.dp, end = 16.dp, bottom = 10.dp, top = 4.dp)
    ) {
        if (continueTitle != null) {
            // Continuar detrás del menú: el blanco tapa el hueco bajo la píldora.
            ReperaContinueAccessory(
                title = continueTitle,
                progress = continueProgress,
                onClick = onContinue,
                exercise = continueExercise,
                isLiveActivity = continueIsLive,
                liveSportIcon = continueLiveIcon,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 28.dp)
                    .zIndex(0f)
            )
        }
        ReperaFloatingTabBar(
            tabs = reperaMainTabs,
            selectedRoute = selectedRoute,
            onTabSelected = onTabSelected,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .zIndex(1f)
        )
    }
}
