package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

internal data class ReperaTabSpec(
    val route: String,
    val label: String,
    val icon: ImageVector
)

/** Cuatro pestañas principales (paridad iOS Liquid Glass tab bar). */
internal val reperaMainTabs = listOf(
    ReperaTabSpec("inicio", "Inicio", Icons.Outlined.Home),
    ReperaTabSpec("en-vivo", "Comenzar", Icons.Outlined.PlayCircle),
    ReperaTabSpec("progreso", "Progreso", Icons.Outlined.Speed),
    ReperaTabSpec("ejercicios", "Ejercicios", Icons.Outlined.FitnessCenter)
)

internal val reperaTabRoutes: Set<String> = reperaMainTabs.map { it.route }.toSet()

/** Push del editor de entreno (paridad DayEditorView): sin tab bar ni TopAppBar «repera». */
internal fun reperaRouteHidesAppShell(route: String?): Boolean {
    if (route.isNullOrBlank()) return false
    return when {
        route.startsWith("rutina/") -> true
        route.startsWith("rutina-nueva") -> true
        route.startsWith("escaner") -> true
        route.startsWith("favoritos") -> true
        route.startsWith("temporizador") -> true
        route in setOf(
            "entreno-libre",
            "entreno-activo",
            "entreno-activo-editar",
            "favorito-nuevo",
            "ajustes",
            "reloj",
            "historial"
        ) -> true
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
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .testTag("floating_tab_bar"),
        shape = pillShape,
        color = MaterialTheme.colorScheme.surface,
        shadowElevation = 4.dp,
        tonalElevation = 0.dp,
        border = BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.65f)
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
    val iconTint = if (selected) scheme.primary else scheme.onSurfaceVariant
    val labelColor = if (selected) scheme.primary else scheme.onSurfaceVariant
    Column(
        modifier = modifier
            .clickable(onClick = onClick)
            .padding(vertical = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(width = 56.dp, height = 32.dp)
                .then(
                    if (selected) {
                        Modifier.background(
                            scheme.primaryContainer.copy(alpha = 0.72f),
                            RoundedCornerShape(999.dp)
                        )
                    } else {
                        Modifier
                    }
                )
        ) {
            Icon(
                imageVector = tab.icon,
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

/** Accesorio «Continuar» sobre la píldora (ContinueAccessory iOS). */
@Composable
internal fun ReperaContinueAccessory(
    title: String,
    progress: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        tonalElevation = 2.dp,
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .testTag("continuar_accessory")
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    "Continuar",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            if (progress.isNotEmpty()) {
                Text(
                    progress,
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

/** Columna inferior: Continuar (opcional) + píldora con inset y gesto de navegación. */
@Composable
internal fun ReperaTabBarChrome(
    showTabBar: Boolean,
    selectedRoute: String,
    onTabSelected: (String) -> Unit,
    continueTitle: String?,
    continueProgress: String,
    onContinue: () -> Unit
) {
    if (!showTabBar) return
    Column(
        Modifier
            .fillMaxWidth()
            .background(Color.Transparent)
            .navigationBarsPadding()
            .padding(start = 16.dp, end = 16.dp, bottom = 10.dp, top = 4.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        if (continueTitle != null) {
            ReperaContinueAccessory(
                title = continueTitle,
                progress = continueProgress,
                onClick = onContinue
            )
        }
        ReperaFloatingTabBar(
            tabs = reperaMainTabs,
            selectedRoute = selectedRoute,
            onTabSelected = onTabSelected
        )
    }
}
